// TxAuthority uses the convention that modules can sign for themselves using the reserved struct name
//  `Witness`, i.e., 0x899::my_module::Witness. Modules should always define a Witness struct, and
// carefully guard access to it, as it represents the authority of the module at runtime.

module ownership::tx_authority {
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use std::vector;

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID};
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::vec_map2;

    use ownership::permissions::{Self, Permission, SingleUsePermission};

    const WITNESS_STRUCT: vector<u8> = b"Witness";

    // agent_permissions: (principle => Permission types)
    // package_org: (package ID => organization-id (as an address) that controls that package)
    // We are keeping agent_permissions internal, because otherwise someone could duplicate and store one of
    // the `Permission` structs, although I don't think they'd be able to use it anywhere.
    struct TxAuthority has drop {
        agent_permissions: VecMap<address, vector<PermissionSet>>,
        package_org: VecMap<ID, address>
    }

    // I removed 'copy' for security reasons, since this also can be stored
    struct PermissionSet has store, drop {
        general: vector<Permission>,
        on_types: VecMap<StructTag, vector<Permission>>,
        on_objects: VecMap<ID, vector<Permission>>
    }

    // ========= Begin =========
    // Any agent added by one of these functions will have full ADMIN permissions as themselves.

    // Begins with a transaction-context object
    public fun begin(ctx: &TxContext): TxAuthority {
        new_internal(tx_context::sender(ctx))
    }

    // Begins with a capability-id
    public fun begin_with_id<T: key>(cap: &T): TxAuthority {
        new_internal(object::id_address(cap))
    }

    // Begins with a capability-type
    public fun begin_with_type<T>(_cap: &T): TxAuthority {
        new_internal(encode::type_into_address<T>())
    }

    public fun begin_with_single_use(single_use: SingleUsePermission): TxAuthority {
        let (principal, permission) = permissions::consume_single_use(single_use);

        TxAuthority {
            agent_permissions: vec_map2::new(principal, vector[permission]),
            agent_type_constraints: vec_map::empty(),
            agent_object_constraints: vec_map::empty(),
            package_org: vec_map::empty() 
        }
    }

    public fun begin_with_package_witness<Witness: drop>(_witness: Witness): TxAuthority {
        new_internal(object::id_to_address(&encode::package_id<Witness>()))
    }

    public fun empty(): TxAuthority {
        TxAuthority { 
            agent_permissions: vec_map::empty(),
            package_org: vec_map::empty() 
        }
    }

    // ========= Add Agents =========
    // Any agent added by one of these functions will have full ADMIN permissions as themselves.

    // This will be more useful once Sui supports multi-party transactions (August 2023)
    public fun add_signer(ctx: &TxContext, auth: &TxAuthority): TxAuthority {
        let new_auth = copy_(auth);
        let permissions = new_permission_set_internal(vector[permissions::admin()]);

        vec_map2::set(&mut new_auth.agent_permissions, tx_context::sender(ctx), permissions);

        new_auth
    }

    public fun add_id<T: key>(cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = copy_(auth);
        let permissions = new_permission_set_internal(vector[permissions::admin()]);

        vec_map2::set(&mut new_auth.agent_permissions, object::id_address(cap), permissions);

        new_auth
    }

    public fun add_type<T>(_cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = copy_(auth);
        let permissions = new_permission_set_internal(vector[permissions::admin()]);

        vec_map2::set(&mut new_auth.agent_permissions, encode::type_into_address<T>(), permissions);

        new_auth
    }

    public fun add_single_use(single_use: SingleUsePermission, auth: &TxAuthority): TxAuthority {
        let new_auth = copy_(auth);
        let fallback = new_permission_set_internal(vector[]);

        let (principal, permission) = permissions::consume_single_use(single_use);
        let existing = vec_map2::borrow_mut_fill(&mut new_auth.agent_permissions, principal, fallback);
        permissions::add(&mut existing.general, vector[permission]);

        new_auth
    }

    public fun add_package_witness<Witness: drop>(_witness: Witness, auth: &TxAuthority): TxAuthority {
        let new_auth = copy_(auth);
        let package_addr = object::id_to_address(&encode::package_id<Witness>());
        let permissions = new_permission_set_internal(vector[permissions::admin()]);

        vec_map2::set(&mut new_auth.agent_permissions, package_addr, permissions);

        new_auth
    }

    public fun copy_(auth: &TxAuthority): TxAuthority {
        TxAuthority { 
            agent_permissions: auth.agent_permissions,
            package_org: auth.package_org
        }
    }

    // ========= Permission Validity Checkers =========

    public fun has_permission<Permission>(principal: address, auth: &TxAuthority): bool {
        let permissions_maybe = vec_map2::get_maybe(&auth.agent_permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        permissions::has_permission<Permission>(&permissions.general)
    }

    // Same as above, except it checks against the type and object_id constraints as well
    public fun has_permission_<Permission>(
        principal: address,
        struct_tag: &StructTag,
        object_id: &ID,
        auth: &TxAuthority
    ): bool {
        // Check against general permissions
        let permissions_maybe = vec_map2::get_maybe(&auth.agent_permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);
        if (permissions::has_permission<Permission>(&permissions.general)) return true

        // Check against type permissions
        let type_permissions_maybe = vec_map2::get_stuct_tag_maybe(&permissions.on_types, struct_tag);
        if (option::is_some(&type_permissions_maybe)) {
            let type_permissions = option::destroy_some(type_permissions_maybe);
            if (permissions::has_permission<Permission>(&type_permissions)) return true
        };

        // Check against object permissions
        let object_permissions_maybe = vec_map2::get_maybe(&permissions.on_objects, object_id);
        if (option::is_some(&object_permissions_maybe)) {
            let object_permissions = option::destroy_some(object_permissions_maybe);
            if (permissions::has_permission<Permission>(&object_permissions)) return true
        };

        false
    }

    // `T` can be any type belong to the package, such as 0x599::my_module::StructName
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

    // ========= Organization Validity Checkers =========

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
        let permissions_maybe = vec_map2::get_maybe(&auth.agent_permissions, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        permissions::has_permission_excluding_manager<Permission>(&permissions)
    }

    // ========= Getter Functions =========

    public fun agents(auth: &TxAuthority): vector<address> {
        vec_map::keys(&auth.agent_permissions)
    }

    public fun organizations(auth: &TxAuthority): VecMap<ID, address> {
        auth.package_org
    }

    // May return option::none if the organization hasn't been added to this TxAuthority object
    public fun lookup_organization_for_package<P>(auth: &TxAuthority): Option<address> {
        vec_map2::get_maybe(&auth.package_org, encode::package_id<P>())
    }

    public fun lookup_organization_for_package_(package_id: ID, auth: &TxAuthority): Option<address> {
        vec_map2::get_maybe(&auth.package_org, package_id)
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

    fun new_internal(princpal: address): TxAuthority {
        TxAuthority {
            agent_permissions: vec_map2::new(principal, PermissionSet {
                general: vector[permissions::admin()],
                on_types: vec_map::empty(),
                on_objects: vec_map::empty()
            }),
            package_org: vec_map::empty() 
        }
    }

    fun new_permission_set_internal(contents: vector<Permission>): PermissionSet {
        PermissionSet {
            general: vector[contents],
            on_types: vec_map::empty(),
            on_objects: vec_map::empty()
        };
    }

    public(friend) fun new_permission_set_empty(): PermissionSet {
        PermissionSet {
            general: vector[],
            on_types: vec_map::empty(),
            on_objects: vec_map::empty()
        };
    }

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
        new_permissions: vector<Permission>,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = copy_(auth);
        let fallback = new_permission_set_internal(vector[]);

        // Delegation cannot expand the permissions that an agent already has; it can merely extend a
        // subset of its existing permissions to a new principal
        let agent_permissions = vec_map2::borrow_mut_fill(&mut new_auth.agent_permissions, agent, fallback);
        let filtered_permissions = permissions::intersection(&new_permissions, &agent_permissions.general);

        let principal_permissions = vec_map2::borrow_mut_fill(
            &mut new_auth.agent_permissions, principal, fallback);
        permissions::add(&mut principal_permissions.general, filtered_permissions);

        new_auth
    }

    // Only callable by the ownership::delegation module
    friend ownership::delegation;

    public(friend) fun add_permission_for_type_internal(
        principal: address,
        agent: address,
        new_permissions: vector<Permission>,
    ): TxAuthority {

    }

    public(friend) fun add_permissions_internal_(
        principal: address,
        agent: address,
        new_permissions: vector<Permission>,
        types: vector<StructTag>,
        objects: vector<ID>,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = copy_(auth);
        let fallback = new_permission_set_internal(vector[]);

        // Filter delegations
        let agent_permissions = vec_map2::borrow_mut_fill(&mut new_auth.agent_permissions, agent, fallback);
        let filtered_permissions = permissions::intersection(&new_permissions, &agent_permissions.general);

        let principal_permissions = vec_map2::borrow_mut_fill(
            &mut new_auth.agent_permissions, principal, fallback);
        permissions::add(&mut principal_permissions.general, filtered_permissions);

        new_auth
    }
}
