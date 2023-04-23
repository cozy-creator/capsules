// TxAuthority uses the convention that modules can sign for themselves using the reserved struct name
//  `Witness`, i.e., 0x899::my_module::Witness. Modules should always define a Witness struct, and
// carefully guard access to it, as it represents the authority of the module at runtime.

module ownership::tx_authority {
    use std::option::{Self, Option};
    use std::string::{Self, String, utf8};
    use std::vector;

    use sui::bcs;
    use sui::hash;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID};

    use sui_utils::encode;
    use sui_utils::string2;
    use sui_utils::struct_tag::{Self, StructTag};

    const WITNESS_STRUCT: vector<u8> = b"Witness";

    // agents: [ addresses that have given full authority to this transaction ]
    // permissions: (principle => Permission" functions that are allowed to be called on behalf of the principal)
    // namespaces: (package ID => principal for that package, i.e., the ID (address) found in its namespace object)
    struct TxAuthority has drop {
        permissions: VecMap<address, vector<Permission>>,
        namespaces: VecMap<ID, address>
    }

    // ========= Begin =========

    // Begins with a transaction-context object
    public fun begin(ctx: &TxContext): TxAuthority {
        TxAuthority {
            permissions: vec_map2::new(tx_context::sender(ctx), permissions::admin()), 
            namespaces: vec_map::empty() 
        }
    }

    // Begins with a capability-id
    public fun begin_with_id<T: key>(cap: &T): TxAuthority {
        TxAuthority {
            permissions: vec_map2::new(object::id_address(cap), permissions::admin()), 
            namespaces: vec_map::empty() 
        }
    }

    // Begins with a capability-type
    public fun begin_with_type<T>(_cap: &T): TxAuthority {
        TxAuthority {
            permissions: vec_map2::new(encode::type_into_address<T>(), permissions::admin()), 
            namespaces: vec_map::empty() 
        }
    }

    public fun begin_with_single_use(single_use: SingleUsePermission): TxAuthority {
        let SingleUsePermission = { id, principal, permission } = single_use;
        object::delete(id);

        TxAuthority {
            permissions: vec_map2::new(principal, vector[permission]), 
            namespaces: vec_map::empty() 
        }
    }

    public fun empty(): TxAuthority {
        TxAuthority { permissions: vec_map2::empty(), namespaces: vec_map::empty() }
    }

    // ========= Add Agents =========

    public fun add_id<T: key>(cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, namespaces: auth.namespaces };
        vec_map2::set(&mut new_auth.permissions, object::id_address(cap), permissions::admin());

        new_auth
    }

    public fun add_type<T>(_cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, namespaces: auth.namespaces };
        vec_map2::set(&mut new_auth.permissions, encode::type_into_address<T>(), permissions::admin());

        new_auth
    }

    public fun add_single_use(single_use: SingleUsePermission, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, namespaces: auth.namespaces };

        let SingleUsePermission = { id, principal, permission } = single_use;
        object::delete(id);
        let existing = vec_map2::borrow_mut_fill(&mut new_auth.permissions, principal, vector[]);
        permissions::add(existing, vector[permission]);

        new_auth
    }

    // ========= Admin Validity Checkers =========
    // Admin is the highest level of permission an agent can have
    // Use these checkers when doing sensitive operations, like granting permissions to other agents

    public fun has_admin_permission(principal: address, auth: &TxAuthority): bool {
        let permissions_maybe = vec_map2::get_maybe(&auth.permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        permissions::has_admin_permission(permissions)
    }

    // Defaults to `true` if the principal does not exist (option::none)
    public fun has_admin_permission_opt(principal_maybe: Option<address>, auth: &TxAuthority): bool {
        if (option::is_none(&principal_maybe)) return true;
        has_admin_permission(option::destroy_some(principal_maybe), auth)
    }

    // True if and only if TxAuthority had the Witness of T's module added
    public fun has_module_admin_permission<T>(auth: &TxAuthority): bool {
        has_admin_permission(witness_addr<T>(), auth)
    }

    // type can be any type belonging to the module, such as 0x599::my_module::StructName
    public fun has_module_admin_permission_(type: String, auth: &TxAuthority): bool {
        has_admin_permission(witness_addr_(type), auth)
    }

    public fun has_object_admin_permission<T: key>(id: ID, auth: &TxAuthority): bool {
        has_admin_permission(object::id_to_address(&id), auth)
    }

    public fun has_type_admin_permission<T>(auth: &TxAuthority): bool {
        has_admin_permission(encode::type_into_address<T>(), auth)
    }

    // ========= Check Against Lists of Agents =========

    public fun has_k_or_more_agents_with_permission<Permission>(
        principals: vector<address>,
        k: u64,
        auth: &TxAuthority
    ): bool {
        if (k == 0) return true;
        let total = 0;
        while (!vector::is_empty(&principals)) {
            let principal = vector::pop_back(&mut principals);
            if (has_permission<Permission>(principal, auth)) { total = total + 1; };
            if (total >= k) return true;
        };

        false
    }

    public fun tally_agents_with_permission<Permission>(principals: vector<address>, auth: &TxAuthority): u64 {
        let total = 0;
        while (!vector::is_empty(&principals)) {
            let principal = vector::pop_back(&mut principals);
            if (has_permission<Permission>(principal, auth)) { total = total + 1; };
        };

        total
    }

    public fun has_k_or_more_admin_agents(
        principals: vector<address>,
        k: u64,
        auth: &TxAuthority
    ): bool {
        if (k == 0) return true;
        let total = 0;
        while (!vector::is_empty(&principals)) {
            let principal = vector::pop_back(&mut principals);
            if (has_admin_permission(principal, auth)) { total = total + 1; };
            if (total >= k) return true;
        };

        false
    }

    public fun tally_admin_agents(principals: vector<address>, auth: &TxAuthority): u64 {
        let total = 0;
        while (!vector::is_empty(&principals)) {
            let principal = vector::pop_back(&mut principals);
            if (has_admin_permission(principal, auth)) { total = total + 1; };
        };

        total
    }

    // ========= Permission Validity Checkers =========
    // Checks against permissions + admins, and not just admin-status (as above)
    // Permission checks are more permissive than admin-checks, because there is a wider number of ways
    // to satisfy the check

    public fun has_permission<Permission>(principal: address, auth: &TxAuthority): bool {
        let permissions_maybe = vec_map2::get_maybe(&auth.permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        permissions::has_permission<Permission>(&permissions);
    }

    // The principal is optional and defaults to true if `option::none`
    public fun has_permission_opt<Permission>(principal_maybe: Option<address>, auth: &TxAuthority): bool {
        if (option::is_none(&principal_maybe)) { return true };
        let principal = option::destroy_some(principal_maybe);

        has_permission_<Permission>(principal, auth)
    }

    // True if and only if TxAuthority had the Witness of T's module added
    public fun has_module_permission<T, Permission>(auth: &TxAuthority): bool {
        has_permission<Permission>(witness_addr<T>(), auth)
    }

    // type can be any type belonging to the module, such as 0x599::my_module::StructName
    public fun has_module_permission_<Permission>(type: String, auth: &TxAuthority): bool {
        has_permission<Permission>(witness_addr_(type), auth)
    }

    public fun has_object_permission<T: key, Permission>(id: ID, auth: &TxAuthority): bool {
        has_permission<Permission>(object::id_to_address(&id), auth)
    }

    public fun has_type_permission<T, Permission>(auth: &TxAuthority): bool {
        has_permission<Permission>(encode::type_into_address<T>(), auth)
    }

    // Special-case function where we want to assign sensitive permissions to agents, but not grant them to
    // managers automatically (they are still granted to admins automatically)
    public fun has_permission_excluding_manager<Permission>(principal: address, auth: &TxAuthority): bool {
        let permissions_maybe = vec_map2::get_maybe(&auth.permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        permissions::has_permission_exclude_manager<Permission>(&permissions);
    }

    // ========= Getter Functions =========

    public fun agents(auth: &TxAuthority): vector<address> {
        vec_map2::keys(&auth.permissions)
    }

    public fun permissions(auth: &TxAuthority): VecMap<address, Permission> {
        auth.permissions
    }

    public fun namespaces(auth: &TxAuthority): VecMap<ID, address> {
        auth.namespaces
    }

    // May return option::none if the namespace hasn't been added to this TxAuthority object
    public fun lookup_namespace_for_package<P>(auth: &TxAuthority): Option<address> {
        vec_map2::get_maybe(&auth.namespaces, encode::package_id<P>())
    }

    public fun is_module_authority<Witness: drop, T>(): bool {
        encode::type_name<Witness>() == witness_string<T>()
    }

    // ========= Witness for Module Authority =========

    public fun witness_addr<T>(): address {
        let witness_type = witness_string<T>();
        encode::type_string_into_address(witness_type)
    }

    public fun witness_addr_(type: String): address {
        let witness_type = witness_string_(type);
        encode::type_string_into_address(witness_type)
    }

    public fun witness_addr_from_struct_tag(tag: &StructTag): address {
        let witness_type = string2::empty();
        string::append(&mut witness_type, string2::from_id(struct_tag::package_id(tag)));
        string::append(&mut witness_type, utf8(b"::"));
        string::append(&mut witness_type, struct_tag::module_name(tag));
        string::append(&mut witness_type, utf8(b"::"));
        string::append(&mut witness_type, utf8(WITNESS_STRUCT));

        encode::type_string_into_address(witness_type)
    }

    public fun witness_string<T>(): String {
        encode::append_struct_name<T>(string::utf8(WITNESS_STRUCT))
    }

    public fun witness_string_(type: String): String {
        let module_addr = encode::package_id_and_module_name_(type);
        encode::append_struct_name_(module_addr, string::utf8(WITNESS_STRUCT))
    }

    // ========= Internal Functions =========
    // Only callable within the `ownership::namespace` module

    friend ownership::namespace;

    public(friend) fun add_namespace_internal(
        packages: vector<ID>,
        principal: address,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, namespaces: auth.namespaces };
        while (!vector::is_empty(&packages)) {
            let package = vector::pop_back(&mut packages);
            vec_map2::insert_maybe(&mut new_auth.namespaces, package, principal);
        };

        new_auth
    }

    public(friend) fun add_permissions_internal(
        principal: address,
        agent: address,
        new_permissions: vector<Permission>,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, namespaces: auth.namespaces };
        let agent_permissions = vec_map2::borrow_mut_fill(&mut new_auth.permissions, agent, vector[]);
        let existing = vec_map2::borrow_mut_fill(&mut new_auth.permissions, principal, vector[]);

        let permissions = vector2::filter(&new_permissions, agent_permissions);
        permissions::add(existing, permissions);

        new_auth
    }

    #[test_only]
    public fun begin_for_testing(addr: address): TxAuthority {
        TxAuthority { agents: vector[addr] }
    }

    #[test_only]
    public fun add_for_testing(addr: address, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { agents: auth.agents };
        vec_map2::set(&mut new_auth.permissions, addr, permissions::admin());

        new_auth
    }
}

#[test_only]
module ownership::tx_authority_test {
    use sui::test_scenario;
    use sui::sui::SUI;
    use ownership::tx_authority;
    use sui_utils::encode;

    const SENDER1: address = @0x69;
    const SENDER2: address = @0x420;

    struct SomethingElse has drop {}
    struct Witness has drop {}

    #[test]
    public fun signer_authority() {
        let scenario = test_scenario::begin(SENDER1);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let auth = tx_authority::begin(ctx);
            assert!(tx_authority::has_admin_permission(SENDER1, &auth), 0);
            assert!(!tx_authority::has_admin_permission(SENDER2, &auth), 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun module_authority() {
        let scenario = test_scenario::begin(@0x69);
        let _ctx = test_scenario::ctx(&mut scenario);
        {
            let auth = tx_authority::begin_with_type<Witness>(&Witness {});
            let type = encode::type_name<SomethingElse>();
            assert!(tx_authority::is_signed_by_module_(type, &auth), 0);

            let type = encode::type_name<SUI>();
            assert!(!tx_authority::is_signed_by_module_(type, &auth), 0);

            assert!(tx_authority::is_signed_by_module<SomethingElse>(&auth), 0);
            assert!(!tx_authority::is_signed_by_module<SUI>(&auth), 0);
        };
        test_scenario::end(scenario);
    }
}