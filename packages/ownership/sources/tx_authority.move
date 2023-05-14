// TxAuthority uses the convention that modules can sign for themselves using the reserved struct name
//  `Witness`, i.e., 0x899::my_module::Witness. Modules should always define a Witness struct, and
// carefully guard access to it, as it represents the authority of the module at runtime.

module ownership::tx_authority {
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use std::vector;

    // use sui::bcs;
    // use sui::hash;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID};
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    // use sui_utils::string2;
    // use sui_utils::struct_tag::{Self, StructTag};
    // use sui_utils::vector2;
    use sui_utils::vec_map2;

    use ownership::permissions::{Self, Permission, SingleUsePermission};

    const WITNESS_STRUCT: vector<u8> = b"Witness";

    // agents: [ addresses that have given full authority to this transaction ]
    // permissions: (principle => Permission" functions that are allowed to be called on behalf of the principal)
    // organizations: (package ID => principal for that package, i.e., the ID (address) found in its organization object)
    struct TxAuthority has drop {
        permissions: VecMap<address, vector<Permission>>,
        organizations: VecMap<ID, address>
    }

    // ========= Begin =========
    // Any agent added by one of these functions will have full ADMIN permissions as themselves.

    // Begins with a transaction-context object
    public fun begin(ctx: &TxContext): TxAuthority {
        TxAuthority {
            permissions: vec_map2::new(tx_context::sender(ctx), vector[permissions::admin()]), 
            organizations: vec_map::empty() 
        }
    }

    // Begins with a capability-id
    public fun begin_with_id<T: key>(cap: &T): TxAuthority {
        TxAuthority {
            permissions: vec_map2::new(object::id_address(cap), vector[permissions::admin()]), 
            organizations: vec_map::empty() 
        }
    }

    // Begins with a capability-type
    public fun begin_with_type<T>(_cap: &T): TxAuthority {
        TxAuthority {
            permissions: vec_map2::new(encode::type_into_address<T>(), vector[permissions::admin()]), 
            organizations: vec_map::empty() 
        }
    }

    public fun begin_with_single_use(single_use: SingleUsePermission): TxAuthority {
        let (principal, permission) = permissions::consume_single_use(single_use);

        TxAuthority {
            permissions: vec_map2::new(principal, vector[permission]), 
            organizations: vec_map::empty() 
        }
    }

    public fun begin_with_package_witness<Witness: drop>(_witness: Witness): TxAuthority {
        let package_addr = object::id_to_address(&encode::package_id<Witness>());

        TxAuthority {
            permissions: vec_map2::new(package_addr, vector[permissions::admin()]), 
            organizations: vec_map::empty()
        }
    }

    public fun empty(): TxAuthority {
        TxAuthority { permissions: vec_map::empty(), organizations: vec_map::empty() }
    }

    // ========= Add Agents =========
    // Any agent added by one of these functions will have full ADMIN permissions as themselves.

    // This will be more useful once Sui supports multi-party transactions (August 2023)
    public fun add_signer<T: key>(ctx: &TxContext, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, organizations: auth.organizations };
        vec_map2::set(&mut new_auth.permissions, tx_context::sender(ctx), vector[permissions::admin()]);

        new_auth
    }

    public fun add_id<T: key>(cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, organizations: auth.organizations };
        vec_map2::set(&mut new_auth.permissions, object::id_address(cap), vector[permissions::admin()]);

        new_auth
    }

    public fun add_type<T>(_cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, organizations: auth.organizations };
        vec_map2::set(&mut new_auth.permissions, encode::type_into_address<T>(), vector[permissions::admin()]);

        new_auth
    }

    public fun add_single_use(single_use: SingleUsePermission, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, organizations: auth.organizations };

        let (principal, permission) = permissions::consume_single_use(single_use);
        let existing = vec_map2::borrow_mut_fill(&mut new_auth.permissions, principal, vector[]);
        permissions::add(existing, vector[permission]);

        new_auth
    }

    public fun add_package_witness<Witness: drop>(_witness: Witness, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, organizations: auth.organizations };
        let package_addr = object::id_to_address(&encode::package_id<Witness>());

        vec_map2::set(&mut new_auth.permissions, package_addr, vector[permissions::admin()]);

        new_auth
    }

    public fun copy_(auth: &TxAuthority): TxAuthority {
        TxAuthority { permissions: auth.permissions, organizations: auth.organizations }
    }

    // ========= Admin Validity Checkers =========
    // Admin is the highest level of permission an agent can have
    // Use these checkers when doing sensitive operations, like granting permissions to other agents

    // public fun has_admin_permission(principal: address, auth: &TxAuthority): bool {
    //     let permissions_maybe = vec_map2::get_maybe(&auth.permissions, principal);
    //     if (option::is_none(&permissions_maybe)) { return false };
    //     let permissions = option::destroy_some(permissions_maybe);

    //     permissions::has_admin_permission(permissions)
    // }

    // // Defaults to `true` if the principal does not exist (option::none)
    // public fun has_admin_permission_opt(principal_maybe: Option<address>, auth: &TxAuthority): bool {
    //     if (option::is_none(&principal_maybe)) return true;
    //     has_admin_permission(option::destroy_some(principal_maybe), auth)
    // }

    // // True if and only if TxAuthority had the Witness of T's module added
    // public fun has_module_admin_permission<T>(auth: &TxAuthority): bool {
    //     has_admin_permission(witness_addr<T>(), auth)
    // }

    // // type can be any type belonging to the module, such as 0x599::my_module::StructName
    // public fun has_module_admin_permission_(type: String, auth: &TxAuthority): bool {
    //     has_admin_permission(witness_addr_(type), auth)
    // }

    // public fun has_object_admin_permission<T: key>(id: ID, auth: &TxAuthority): bool {
    //     has_admin_permission(object::id_to_address(&id), auth)
    // }

    // public fun has_type_admin_permission<T>(auth: &TxAuthority): bool {
    //     has_admin_permission(encode::type_into_address<T>(), auth)
    // }

    // ========= Permission Validity Checkers =========

    public fun has_permission<Permission>(principal: address, auth: &TxAuthority): bool {
        let permissions_maybe = vec_map2::get_maybe(&auth.permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        permissions::has_permission<Permission>(&permissions)
    }

    // The principal is optional and defaults to true if `option::none`
    // public fun has_permission_opt<Permission>(principal_maybe: Option<address>, auth: &TxAuthority): bool {
    //     if (option::is_none(&principal_maybe)) { return true };
    //     let principal = option::destroy_some(principal_maybe);

    //     has_permission_<Permission>(principal, auth)
    // }

    // `T` can be any type belong to the package
    public fun has_package_permission<T, Permission>(auth: &TxAuthority): bool {
        let package_id = encode::package_id<T>();
        if (has_permission<Permission>(object::id_to_address(&package_id), auth)) {
            return true
        };

        has_org_permission_for_package<Permission>(package_id, auth)
    }

    // `type` can be any type belonging to the package, such as 0x599::my_module::StructName
    public fun has_package_permission_<Permission>(package_id: ID, auth: &TxAuthority): bool {
        if (has_permission<Permission>(object::id_to_address(&package_id), auth)) {
            return true
        };

        has_org_permission_for_package<Permission>(package_id, auth)
    }

    public fun has_id_permission<T: key, Permission>(obj: &T, auth: &TxAuthority): bool {
        has_id_permission_<Permission>(object::id(obj), auth)
    }

    public fun has_id_permission_<Permission>(id: ID, auth: &TxAuthority): bool {
        has_permission<Permission>(object::id_to_address(&id), auth)
    }

    public fun has_type_permission<T, Permission>(auth: &TxAuthority): bool {
        has_permission<Permission>(encode::type_into_address<T>(), auth)
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

    // public fun has_k_or_more_admin_agents(
    //     principals: vector<address>,
    //     k: u64,
    //     auth: &TxAuthority
    // ): bool {
    //     if (k == 0) return true;
    //     let total = 0;
    //     while (!vector::is_empty(&principals)) {
    //         let principal = vector::pop_back(&mut principals);
    //         if (has_admin_permission(principal, auth)) { total = total + 1; };
    //         if (total >= k) return true;
    //     };

    //     false
    // }

    // public fun tally_admin_agents(principals: vector<address>, auth: &TxAuthority): u64 {
    //     let total = 0;
    //     while (!vector::is_empty(&principals)) {
    //         let principal = vector::pop_back(&mut principals);
    //         if (has_admin_permission(principal, auth)) { total = total + 1; };
    //     };

    //     total
    // }

    // ========= Organization Validity Checkers =========

    // public fun has_organization_admin_permission<OrganizationType>(auth: &TxAuthority): bool {
    //     let principal_maybe = lookup_organization_for_package<OrganizationType>(auth);
    //     if (option::is_none(&principal_maybe)) { return false };
    //     let principal = option::destroy_some(principal_maybe);

    //    has_admin_permission(principal, auth)
    // }

    // Convenience function. Permission and Organization are the same module, so this is checking if
    // the same module authorized this operation as the module that declared this permission type.
    public fun has_org_permission<Permission>(auth: &TxAuthority): bool {
        has_org_permission_<Permission, Permission>(auth)
    }

    // `OrganizationType` can be literally any type declared in any package belonging to that Organization;
    // we merely use this type to figure out the package-id, so that we can lookup the Organization that
    // owns that type (assuming it has been added to TxAuthority already).
    // In this case, Organization is the principal.
    public fun has_org_permission_<OrganizationType, Permission>(auth: &TxAuthority): bool {
        let principal_maybe = lookup_organization_for_package<OrganizationType>(auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);

       has_permission<Permission>(principal, auth)
    }

    // Finds the organization that controls the corresponding package ID, and checks to see if the
    // corresponding permission is found.
    public fun has_org_permission_for_package<Permission>(package: ID, auth: &TxAuthority): bool {
        let principal_maybe = lookup_organization_for_package_(package, auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);

        has_permission<Permission>(principal, auth)
    }

    // This is best used for sensitive operations, where you want the agent to either explicitly have
    // the permission, or be an admin. We do not want to automatically grant this permission by default
    // by being a manager.
    public fun has_org_permission_excluding_manager<OrganizationType, Permission>(auth: &TxAuthority): bool {
        let principal_maybe = lookup_organization_for_package<OrganizationType>(auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);

        has_org_permission_excluding_manager_<Permission>(principal, auth)
    }

    // Special-case function where we want to assign sensitive permissions to agents, but not grant them to
    // managers automatically (they are still granted to admins automatically)
    public fun has_org_permission_excluding_manager_<Permission>(
        principal: address,
        auth: &TxAuthority
    ): bool {
        let permissions_maybe = vec_map2::get_maybe(&auth.permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        permissions::has_permission_excluding_manager<Permission>(&permissions)
    }

    // ========= Getter Functions =========

    public fun agents(auth: &TxAuthority): vector<address> {
        vec_map::keys(&auth.permissions)
    }

    public fun permissions(auth: &TxAuthority): VecMap<address, vector<Permission>> {
        auth.permissions
    }

    public fun organizations(auth: &TxAuthority): VecMap<ID, address> {
        auth.organizations
    }

    // May return option::none if the organization hasn't been added to this TxAuthority object
    public fun lookup_organization_for_package<P>(auth: &TxAuthority): Option<address> {
        vec_map2::get_maybe(&auth.organizations, encode::package_id<P>())
    }

    public fun lookup_organization_for_package_(package_id: ID, auth: &TxAuthority): Option<address> {
        vec_map2::get_maybe(&auth.organizations, package_id)
    }

    // True if the package-id, and module-name of Witness and T map, and Witness' struct name is 'Witness'
    public fun is_module_authority<Witness: drop, T>(): bool {
        encode::type_name<Witness>() == witness_string<T>()
    }

    // ========= Witness for Module Authority =========

    // public fun witness_addr<T>(): address {
    //     let witness_type = witness_string<T>();
    //     encode::type_string_into_address(witness_type)
    // }

    // public fun witness_addr_(type: String): address {
    //     let witness_type = witness_string_(type);
    //     encode::type_string_into_address(witness_type)
    // }

    // public fun witness_addr_from_struct_tag(tag: &StructTag): address {
    //     let witness_type = string2::empty();
    //     string::append(&mut witness_type, string2::from_id(struct_tag::package_id(tag)));
    //     string::append(&mut witness_type, utf8(b"::"));
    //     string::append(&mut witness_type, struct_tag::module_name(tag));
    //     string::append(&mut witness_type, utf8(b"::"));
    //     string::append(&mut witness_type, utf8(WITNESS_STRUCT));

    //     encode::type_string_into_address(witness_type)
    // }

    public fun witness_string<T>(): String {
        encode::append_struct_name<T>(string::utf8(WITNESS_STRUCT))
    }

    // public fun witness_string_(type: String): String {
    //     let module_addr = encode::package_id_and_module_name_(type);
    //     encode::append_struct_name_(module_addr, string::utf8(WITNESS_STRUCT))
    // }

    // ========= Internal Functions =========
    // Only callable within the `ownership::organization` module

    friend ownership::organization;

    public(friend) fun add_organization_internal(
        packages: vector<ID>,
        principal: address,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, organizations: auth.organizations };
        while (!vector::is_empty(&packages)) {
            let package = vector::pop_back(&mut packages);
            vec_map2::insert_maybe(&mut new_auth.organizations, package, principal);
        };

        new_auth
    }

    public(friend) fun add_permissions_internal(
        principal: address,
        agent: address,
        new_permissions: vector<Permission>,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { permissions: auth.permissions, organizations: auth.organizations };

        // Delegation cannot expand the permissions that an agent already has; it can merely extend a
        // subset of its existing permissions to a new principal
        let agent_permissions = vec_map2::borrow_mut_fill(&mut new_auth.permissions, agent, vector[]);
        let permissions = permissions::intersection(&new_permissions, agent_permissions);

        let existing = vec_map2::borrow_mut_fill(&mut new_auth.permissions, principal, vector[]);
        permissions::add(existing, permissions);

        new_auth
    }
}
