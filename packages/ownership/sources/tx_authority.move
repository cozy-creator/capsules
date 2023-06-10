// TxAuthority uses the convention that modules can sign for themselves using the reserved struct name
//  `Witness`, i.e., 0x899::my_module::Witness. Modules should always define a Witness struct, and
// carefully guard access to it, as it represents the authority of the module at runtime.

module ownership::tx_authority {
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use std::vector;

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    use sui_utils::struct_tag::StructTag;
    use sui_utils::vec_map2;

    use ownership::action_set::{Self, ActionSet};
    use ownership::action::{Self, Action};

    // Hardcoded struct name for package witnesses
    const WITNESS_STRUCT: vector<u8> = b"Witness";

    // Error constants
    const ENOT_A_PACKAGE_WITNESS: u64 = 0;

    // principal_actions: (principle => Set of available actions as that principal)
    // package_org: (package ID => organization-id (as an address) that controls that package)
    // We are keeping principal_actions internal, because otherwise someone could duplicate and store one of
    // the `ActionSet` structs, although I don't think they'd be able to use it anywhere.
    struct TxAuthority has drop {
        principal_actions: VecMap<address, ActionSet>,
        package_org: VecMap<ID, address>
    }

    // ========= Begin =========
    // Any agent added by one of these functions will have full ADMIN permissions as themselves.

    // Begins with a transaction-context object
    public fun begin(ctx: &TxContext): TxAuthority {
        new_internal(tx_context::sender(ctx))
    }

    // Begins with a capability-type
    public fun begin_with_type<T>(_cap: &T): TxAuthority {
        new_internal(encode::type_into_address<T>())
    }

    public fun begin_with_single_use(single_use: SingleUseAction): TxAuthority {
        let (principal, action) = action::consume_single_use(single_use);

        TxAuthority {
            principal_actions: vec_map2::new(principal, vector[action]),
            package_org: vec_map::empty() 
        }
    }

    // A 'package witness' is any struct with the name 'Witness' and the `drop` ability.
    // The module_name is unimportant; only the package_id matters. Effectively this means
    // that any module within a package can produce the same package Witness.
    public fun begin_with_package_witness<Witness: drop>(_witness: Witness): TxAuthority {
        let (package_id, _, struct_name, _)= encode::type_name_decomposed<Witness>();
        assert!(struct_name == string::utf8(WITNESS_STRUCT), ENOT_A_PACKAGE_WITNESS);

        new_internal(object::id_to_address(&package_id))
    }

    public fun empty(): TxAuthority {
        TxAuthority { 
            principal_actions: vec_map::empty(),
            package_org: vec_map::empty() 
        }
    }

    // ========= Add Agents =========
    // Any agent added by one of these functions will have full ADMIN permissions as themselves.

    // This will be more useful once Sui supports multi-party transactions (August 2023)
    public fun add_signer(ctx: &TxContext, auth: &TxAuthority): TxAuthority {
        let new_auth = copy_(auth);
        let permissions = action_set::new(vector[action::admin()]);

        vec_map2::set(&mut new_auth.principal_actions, &tx_context::sender(ctx), permissions);

        new_auth
    }

    public fun add_type<T>(_cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = copy_(auth);
        let permissions = action_set::new(vector[action::admin()]);

        vec_map2::set(&mut new_auth.principal_actions, &encode::type_into_address<T>(), permissions);

        new_auth
    }

    // public fun add_single_use(single_use: SingleUseAction, auth: &TxAuthority): TxAuthority {
    //     let new_auth = copy_(auth);
    //     let fallback = action_set::new(vector[]);

    //     let (principal, action) = action::consume_single_use(single_use);
    //     let existing = vec_map2::borrow_mut_fill(&mut new_auth.principal_actions, &principal, fallback);
    //     action::add(&mut action_set::general_mut(existing), vector[action]);

    //     new_auth
    // }

    public fun add_package_witness<Witness: drop>(_witness: Witness, auth: &TxAuthority): TxAuthority {
        let (package_id, _, struct_name, _)= encode::type_name_decomposed<Witness>();
        assert!(struct_name == string::utf8(WITNESS_STRUCT), ENOT_A_PACKAGE_WITNESS);

        let new_auth = copy_(auth);
        let package_addr = object::id_to_address(&package_id);
        let permissions = action_set::new(vector[action::admin()]);

        vec_map2::set(&mut new_auth.principal_actions, &package_addr, permissions);

        new_auth
    }

    public fun copy_(auth: &TxAuthority): TxAuthority {
        TxAuthority { 
            principal_actions: auth.principal_actions,
            package_org: auth.package_org
        }
    }

    // ========= Action Validity Checkers =========

    public fun can_act_as_address<Action>(principal: address, auth: &TxAuthority): bool {
        let set_maybe = vec_map2::get_maybe(&auth.principal_actions, &principal);
        if (option::is_none(&set_maybe)) { return false };
        let set = option::destroy_some(set_maybe);

        action::has_action<Action>(action_set::general(&set))
    }

    // `T` can be any type belong to the package, such as 0x599::my_module::StructName
    public fun has_package_permission<T, Action>(auth: &TxAuthority): bool {
        let package_id = encode::package_id<T>();
        has_package_permission_<Action>(package_id, auth)
    }

    public fun has_package_permission_<Action>(package_id: ID, auth: &TxAuthority): bool {
        // Checks if this package directly added `Action` to `auth``
        if (can_act_as_address<Action>(object::id_to_address(&package_id), auth)) {
            return true
        };

        // Checks if the organization controlling this package added `Action` to `auth`
        let principal_maybe = lookup_organization_for_package_(package_id, auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);
        can_act_as_address<Action>(principal, auth)
    }

    public fun has_id_permission<T: key, Action>(obj: &T, auth: &TxAuthority): bool {
        has_id_permission_<Action>(object::id(obj), auth)
    }

    public fun has_id_permission_<Action>(id: ID, auth: &TxAuthority): bool {
        can_act_as_address<Action>(object::id_to_address(&id), auth)
    }

    public fun has_type_permission<T, Action>(auth: &TxAuthority): bool {
        can_act_as_address<Action>(encode::type_into_address<T>(), auth)
    }

    // ========= Exclude MANAGER Action =========
    // Note: If you are doing a sensitive edit, such as assigning new delegations or roles, it's
    // recommended that you check for <ADMIN> action, or at least define a special action
    // such as <ASSIGN_ROLE> and then exclude managers, which will automatically have all
    // permissions other than admin. You can do this by doing something like:
    // `assert!(tx_authority::can_act_as_address<ASSIGN_ROLE>(package_id, auth), ENO_AUTHORITY)`;
    // `assert!(!tx_authority::is_manager(principal, auth), ENO_AUTHORITY)`;

    public fun is_manager(principal: address, auth: &TxAuthority): bool {
        let set_maybe = vec_map2::get_maybe(&auth.principal_actions, &principal);
        if (option::is_none(&set_maybe)) { return false };
        let set = option::destroy_some(set_maybe);

        action::has_manager_permission(action_set::general(&set))
    }

    public fun has_package_permission_excluding_manager<T, Action>(auth: &TxAuthority): bool {
        let package_id = encode::package_id<T>();
        has_package_permission_excluding_manager_<Action>(package_id, auth)
    }

    public fun has_package_permission_excluding_manager_<Action>(package_id: ID, auth: &TxAuthority): bool {
        // Checks if this package directly added `Action` to `auth``
        let package_addr = object::id_to_address(&package_id);
        if (can_act_as_address<Action>(package_addr, auth) && !is_manager(package_addr, auth)) {
            return true
        };

        // Checks if the organization controlling this package added `Action` to `auth`
        let principal_maybe = lookup_organization_for_package_(package_id, auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);
        can_act_as_address<Action>(principal, auth) && !is_manager(principal, auth)
    }

    // ========= Validity Checkers with Object Ownership =========
    // Ownership calls into these; they use types and object-ids in addition to general permissions,
    // which makes it more advanced and allows for delegation

        // Same as above, except it checks against the type and object_id constraints as well
    public fun has_object_permission<Action>(
        principal: address,
        struct_tag: &StructTag,
        object_id: &ID,
        auth: &TxAuthority
    ): bool {
        let set_maybe = vec_map2::get_maybe(&auth.principal_actions, &principal);
        if (option::is_none(&set_maybe)) { return false };
        let set = option::destroy_some(set_maybe);

        // Check against general permissions
        if (action::has_action<Action>(action_set::general(&set))) { return true };

        // Check against type permissions
        let type_permissions_maybe = vec_map2::match_struct_tag_maybe(action_set::types(&set), struct_tag);
        if (option::is_some(&type_permissions_maybe)) {
            let type_permissions = option::destroy_some(type_permissions_maybe);
            if (action::has_action<Action>(&type_permissions)) { return true };
        };

        // Check against object permissions
        let object_permissions_maybe = vec_map2::get_maybe(action_set::objects(&set), object_id);
        if (option::is_some(&object_permissions_maybe)) {
            let object_permissions = option::destroy_some(object_permissions_maybe);
            if (action::has_action<Action>(&object_permissions)) { return true };
        };

        false
    }

    public fun has_object_package_permission<T, Action>(
        struct_tag: &StructTag,
        object_id: &ID,
        auth: &TxAuthority
    ): bool {
        let package_id = encode::package_id<T>();
        has_object_package_permission_<Action>(package_id, struct_tag, object_id, auth)
    }

    public fun has_object_package_permission_<Action>(
        package_id: ID,
        struct_tag: &StructTag,
        object_id: &ID,
        auth: &TxAuthority
    ): bool {
        // Checks if this package directly added `Action` to `auth``
        if (has_object_permission<Action>(
            object::id_to_address(&package_id), struct_tag, object_id, auth)) {
            return true
        };

        // Checks if the organization controlling this package added `Action` to `auth`
        let principal_maybe = lookup_organization_for_package_(package_id, auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);
        has_object_permission<Action>(principal, struct_tag, object_id, auth)
    }


    // ========= Check Against Lists of Agents =========

    public fun has_k_or_more_agents_with_permission<Action>(
        principals: vector<address>,
        k: u64,
        auth: &TxAuthority
    ): bool {
        if (k == 0) return true;
        let total = 0;
        while (!vector::is_empty(&principals)) {
            let principal = vector::pop_back(&mut principals);
            if (can_act_as_address<Action>(principal, auth)) { total = total + 1; };
            if (total >= k) return true;
        };

        false
    }

    public fun tally_agents_with_permission<Action>(principals: vector<address>, auth: &TxAuthority): u64 {
        let total = 0;
        while (!vector::is_empty(&principals)) {
            let principal = vector::pop_back(&mut principals);
            if (can_act_as_address<Action>(principal, auth)) { total = total + 1; };
        };

        total
    }

    // ========= Getter Functions =========

    public fun agents(auth: &TxAuthority): vector<address> {
        vec_map::keys(&auth.principal_actions)
    }

    public fun organizations(auth: &TxAuthority): VecMap<ID, address> {
        auth.package_org
    }

    // May return option::none if the organization hasn't been added to this TxAuthority object
    public fun lookup_organization_for_package<P>(auth: &TxAuthority): Option<address> {
        vec_map2::get_maybe(&auth.package_org, &encode::package_id<P>())
    }

    public fun lookup_organization_for_package_(package_id: ID, auth: &TxAuthority): Option<address> {
        vec_map2::get_maybe(&auth.package_org, &package_id)
    }

    // True if the package-id, and module-name of Witness and T map, and Witness' struct name is 'Witness'
    public fun is_module_authority<Witness: drop, T>(): bool {
        encode::type_name<Witness>() == witness_string<T>()
    }

    // ========= Witness for Module Authority =========

    public fun witness_string<T>(): String {
        encode::append_struct_name<T>(string::utf8(WITNESS_STRUCT))
    }

    // ========= Internal Functions =========

    fun new_internal(principal: address): TxAuthority {
        TxAuthority {
            principal_actions: vec_map2::new(principal, action_set::new(vector[action::admin()])),
            package_org: vec_map::empty()
        }
    }

    // ========= Private Friend Functions =========

    // Only callable within the `ownership::organization` module
    friend ownership::organization;

    public(friend) fun add_organization_internal(
        packages: vector<ID>,
        principal: address,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = copy_(auth);
        while (!vector::is_empty(&packages)) {
            let package = vector::pop_back(&mut packages);
            vec_map2::insert_maybe(&mut new_auth.package_org, package, principal);
        };

        new_auth
    }

    public(friend) fun add_permissions_internal(
        principal: address,
        agent: address,
        new_permissions: vector<Action>,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = copy_(auth);
        let fallback = action_set::new(vector[]);

        // Delegation cannot expand the permissions that an agent already has; it can merely extend a
        // subset of its existing permissions to a new principal
        let principal_actions = vec_map2::borrow_mut_fill(&mut new_auth.principal_actions, &agent, fallback);
        let filtered_permissions = action::intersection(
            &new_permissions, action_set::general(principal_actions));

        let principal_permissions = vec_map2::borrow_mut_fill(
            &mut new_auth.principal_actions, &principal, fallback);
        action::add(action_set::general_mut(principal_permissions), filtered_permissions);

        new_auth
    }

    // Only callable by the ownership::delegation module
    friend ownership::delegation;

    public(friend) fun merge_permission_set_internal(
        principal: address,
        agent: address,
        new_set: ActionSet,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = copy_(auth);
        let fallback = action_set::new(vector[]);

        let agent_set = vec_map2::borrow_mut_fill(&mut new_auth.principal_actions, &agent, fallback);
        let filtered_set = action_set::intersection(&new_set, agent_set);

        let principal_set = vec_map2::borrow_mut_fill(&mut new_auth.principal_actions, &principal, fallback);
        action_set::merge(principal_set, filtered_set);

        new_auth
    }

    // Only callable by ownership
    friend ownership::ownership;

    public(friend) fun add_object_id(
        uid: &UID,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = copy_(auth);
        let permissions = action_set::new(vector[action::admin()]);
        vec_map2::set(&mut new_auth.principal_actions, &object::uid_to_address(uid), permissions);

        new_auth
    }

    public(friend) fun begin_with_object_id(uid: &UID): TxAuthority {
        new_internal(object::uid_to_address(uid))
    }

}
