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

    // Convenience function. Uses type T as the principal-address
    public fun claim<T>(uid: &UID, ctx: &TxContext): TxAuthority {
        let principal = tx_authority::type_into_address<T>();
        let auth = tx_authority::begin(ctx);
        claim_(uid, principal, tx_context::sender(ctx), auth)
    }

    public fun claim_(uid: &UID, principal: address, agent: address, auth: &TxAuthority): TxAuthority {
        if (!dynamic_field::exists_(uid, Key { principal })) { return auth };

        let rbac = dynamic_field::borrow<Key, RBAC>(uid, Key { principal });
        let roles = vec_map2::get_with_default(&rbac.role_members, agent, vector::empty());
        let i = 0;
        while (i < vector::length(roles)) {
            let permission = vec_map::get(&rbac.role_permissions, *vector::borrow(roles, i));
            auth = tx_authority::add_permission(principal, permission, &auth);
            i = i + 1;
        };

        auth
    }

    // Honestly, this is just too complicated
    public fun is_allowed_by_owner<T>(uid: &UID, function: u8, auth: &TxAuthority): bool {
        let owner_maybe = ownership::get_owner(uid);
        if (option::is_none(owner_maybe)) { 
            return false // owner is undefined
        };
        let owner = option::destroy_some(owner_maybe);

        // Claim any delegations that may be waiting for us inside inside of this UID
        let i = 0;
        let agents = tx_authority::agents(auth);
        while (i < vector::length(&agents)) {
            let agent = *vector::borrow(&agents, i);
            auth = claim_(uid, owner, agent, auth);
            i = i + 1;
        };

        // The owner is a signer, or a delegation from the owner for this function already exists within `auth`
        tx_authority::is_allowed<T>(owner, function, auth)
    }
}