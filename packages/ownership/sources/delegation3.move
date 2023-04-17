// Delegates permissions from a principal (the owner of the UID) to an agent (the address of the recipient).
// Permissions are scoped using idiosyncratic numbers from 0 - 15.
// It is up to the module assigning and checking these permissions to assign meaning to the numbers
// If the principle is left undefined, the owner of the UID (if one exists) will be used as the principal.
// That is Key { principal: none, agent: <addr> } is shorthand for Key { principal: ownership::owner(uid), agent: <addr> }

// A delegation is:
// A specification of a function which can be called
// By an agent
// On behalf of the principle

module ownership::delegation {
    use std::string::String;

    use ownership::tx_authority::{Self, StoredPermission};

    struct RBAC has store, drop {
        principal: address, // permission granted on behalf of
        role_members: VecMap<address, vector<String>>, // agent -> roles
        role_permissions: VecMap<String, StoredPermission> // role -> permission
    }

    struct Key has store, copy, drop { principal: address }

    // ======= Principal API =======
    // Used by the principal to create roles and delegate permissions to agents
    // Note: rather than giving RBAC referential authority (i.e., a mutable reference alone is sufficient
    // proof of ownership), we do an ownership-check on every modification. This is a safety measure to prevent
    // mistakes on the part of developers who might allow unauthorized access by mistake.

    public fun create_rbac(principal: address, auth: &TxAuthority): RBAC {
        assert!(tx_authority::is_signed_by(principal, auth), ENO_PRINCIPAL_AUTHORITY);

        RBAC {
            principal,
            role_members: vec_map::empty(),
            role_permissions: vec_map::empty()
        }
    }

    // Note that if another rbac is stored in this UID for the same principal, it will be overwritten
    public fun store_rbac(uid: &mut UID, rbac: RBAC) {
        dynamic_field2::set(uid, Key { principal: rbac.principal }, rbac);
    }

    // Convenience function
    public fun create_and_store_rbac(uid: &mut UID, principal: address, auth: &TxAuthority) {
        let rbac = create_rbac(principal, auth);
        store_rbac(uid, rbac);
    }

    public fun add_roles_for_agent() {

    }

    public fun remove_roles_for_agent() {

    }

    public fun delete_agent() {

    }

    public fun add_permissions_for_role() {

    }

    public fun remove_permissions_for_role() {

    }

    public fun delete_role() {

    }

    // ======= Agent API =======
    // Used by agents to retrieve their delegated permissions

    public fun claim(uid: &UID, principal: address, ctx: &TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);

        if (!dynamic_field::exists_(uid, Key { principal })) { return auth };

        let rbac = dynamic_field::borrow<Key, RBAC>(uid, Key { principal });
        let sender = tx_context::sender(ctx);
        let roles = vec_map2::get_with_default(&rbac.role_members, sender, vector::empty());
        let i = 0;
        while (i < vector::length(roles)) {
            let permission = vec_map::get(&rbac.role_permissions, *vector::borrow(roles, i));
            auth = tx_authority::add_permission(principal, permission, &auth);
            i = i + 1;
        };

        auth
    }


    // ======= Manage Permissions =======

    public fun create_role(uid: &mut UID, name: String) {
        let role_index = vec_map2::borrow_mut_fill<Key, VecMap<String, Role>>(uid, Key { }, vec_map::empty());
        vec_map::insert(role_index, name, vector<StoredDelegation>)
    }

    // The permission is stored in the UID.
    public fun add_permission<T>(
        uid: &mut UID,
        permissions: vector<u8>,
        principal: address,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::is_signed_by(principal, auth), ENO_MODULE_AUTHORITY);

        let delegations_index = dynamic_field2::borrow_mut_fill<Key, VecMap<address, vector<StoredDelegation>>>(
            uid,
            Key { },
            vec_map::empty());
        let delegations_for_agent = vec_map2::borrow_mut_fill(delegations_index, agent, vector::empty());


        // TO DO: we can optimize thise with a specialized function
        let (package, module_name, _, _) = encode::type_name_decomposed<T>();

        let stored_delegation = StoredDelegation {
            principal,
            package,
            module_name,
            functions
        };

        let permissions = dynamic_field2::borrow_mut_fill<Key, vector<AllowedFunctions>>(
            uid, Key { agent }, vector::empty());

            struct AllowedFunctions has store, copy, drop {
        package: address,
        module_name: String,
        functions: u16
    }



        let acl = dynamic_field2::borrow_mut_fill(uid, Key<W> { agent }, 0);
        acl::add_role(acl, permission);
    }

    public fun remove_permission() {}

    // ======= Validity Checkers =======

    // Convenience function
    // public fun has_permission(uid: &UID, permission: u8, auth: &TxAuthority): bool {
    //     let principal = tx_authority::type_to_address<Principal>();
    //     has_permission_(uid, option::some(principal), permission, auth)
    // }

    // The ModuleWitness provides scoping for the permissions
    // Looks through the UID seeing if one of the agents in the TxAuthority have the requested permission
    public fun has_owner_permission<ModuleWitness>(uid: &UID, permission: u8, auth: &TxAuthority): bool {
        // Use uid's owner as the default principal
        // let principal = if (option::is_none(&principal)) {
        //     let owner = ownership::get_owner(uid);
        //     if (option::is_none(&owner)) { return false };
        //     option::destroy_some(owner)
        // } else { option::destroy_some(principal) };

        if (ownership::contains_owner_authority(uid, auth)) { return true };

        // Iterate through all agents in the current tx-authority
        let agents = tx_authority::agents(auth);
        let i = 0;
        while (i < vector::length(&agents)) {
            let agent = vector::borrow(agents, i);
            let acl = dynamic_field2::get_with_default<Key, u16>(uid, Key<ModuleWitness> { agent }, 0u16);
            if (acl::has_role(acl, permission)) { return true };
            i = i + 1;
        };

        false
    }

    // This checks the current TxAuthority to see if the requested function is in scope.
    // A module + permission form a scope.
    public fun has_module_permission<ModuleWitness>(permission: u8, auth: &TxAuthority): bool {
        if (ownership::contains_module_authority<ModuleWitness>(auth)) { return true };

        let scope = tx_authority::scope(auth);
        let addr = tx_authority::type_into_address<ModuleWitness>();
        let acl = vec_map2::get_with_default(scope, addr, 0);
        acl::has_role(&acl, permission)
    }
}