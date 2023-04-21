// Sui's Role Based Access Control (RBAC) system

// This allows a principal (address) to delegate a set of permissions to an agent (address).
// Roles provide a layer of abstraction; instead of granting each agent a set of permissions individually,
// you assign each agent a set of roles, and then define the permissions for each of those roles.

// A delegation is:
// The specification of a permission (type), enabling access to a set of function calls
// By an agent
// On behalf of the principle

// An RBAC can be used to delegate control of an account, or control of an object.
// To control an account, a namespace must be created, and the RBAC is stored safely inside.
// To control an object, rbac::Key is used to add it to any UID.

// Example for accounts: a game-master runs a number of servers, and gives their keypairs permissions
// to edit its game objects.
// Example for objects: I have an account object, and I want to allow other people to deposit or
// withdraw assets from it.

module ownership::rbac {
    use std::string::String;

    use ownership::tx_authority::{Self, StoredPermission};

    friend ownership::namespace;

    // Error enums
    const ENO_PRINCIPAL_AUTHORITY: u64 = 0;

    // After creation the principal cannot be changed
    // This can be modified with mere referential authority; store this somewhere private
    struct RBAC has store, drop {
        principal: address, // permission granted on behalf of
        agent_roles: VecMap<address, vector<String>>, // agent -> roles
        role_permissions: VecMap<String, vector<StoredPermission>> // role -> permissions
    }

    struct Key has store, copy, drop { principal: address }

    // ======= Principal API =======
    // Used by the principal to create roles and delegate permissions to agents

    // public fun create(principal: address, auth: &TxAuthority): RBAC {
    //     assert!(tx_authority::is_signed_by(principal, auth), ENO_PRINCIPAL_AUTHORITY);

    //     create_internal(principal)
    // }

    // This is used by namespace::claim because namespaces use package-ids as their principal, and you can
    // never obtain a package-id as an agent outside of using a namespace, so it's impossible to satisfy
    // the auth constraint
    public(friend) fun create(principal: address): RBAC {
        RBAC {
            principal,
            agent_roles: vec_map::empty(),
            role_permissions: vec_map::empty()
        }
    }

    // Note that if another rbac is stored in this UID for the same principal, it will be overwritten
    public fun store(uid: &mut UID, rbac: RBAC) {
        dynamic_field2::set(uid, Key { principal: rbac.principal }, rbac);
    }

    // Convenience function
    public fun create_and_store(uid: &mut UID, principal: address, auth: &TxAuthority) {
        let rbac = create(principal, auth);
        store(uid, rbac);
    }

    public fun borrow(): &RBAC {
    }

    public fun borrow_mut(): &mut RBAC {
    }

    public fun remove(): RBAC {
    }

    public fun grant_roles_for_agent() {

    }

    public fun revoke_roles_for_agent() {

    }

    // Gives unlimited scope to the agent; individual permissions do not need to be specified
    // tx_authority::has_permission<Principal, Any>(auth) will always resolve
    // This does not, however, add the principal to tx_authority.agents. This means
    // tx_authority::is_signed_by(principal, auth) will still fail.
    public fun grant_all_roles_for_agent() {

    }

    // The agent is now identical to the principal. Granting admin power is dangerous; use with caution
    // public fun grant_admin_role_for_agent() {
    // }

    public fun delete_agent() {

    }

    public fun grant_permission_for_role<Permission>(rbac: &mut RBAC, role: String, auth: &TxAuthority) {
        assert!(tx_authority::is_signed_by(rbac.principal, auth), ENO_PRINCIPAL_AUTHORITY);

        let permission = encode::type_name<Permission>();
        let permissions = vec_map2::borrow_mut_fill(&mut rbac.role_permissions, role, vector::empty());
        vector2::merge(permissions, vector[permission]);
    }

    public fun revoke_permissions_for_role() {

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

    // Auth is passed in here to be added onto, not because it's used as a proof of ownership
    public fun claim_(uid: &UID, principal: address, agent: address, auth: &TxAuthority): TxAuthority {
        if (!dynamic_field::exists_(uid, Key { principal })) { return auth };

        let rbac = dynamic_field::borrow<Key, RBAC>(uid, Key { principal });
        let roles = vec_map2::get_with_default(&rbac.agent_roles, agent, vector::empty());
        let i = 0;
        while (i < vector::length(roles)) {
            let permission = vec_map::get(&rbac.role_permissions, *vector::borrow(roles, i));
            auth = tx_authority::add_permission(principal, permission, &auth);
            i = i + 1;
        };

        auth
    }

    // This is rather complicated for a validity checker honestly
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

    // ======= Getter Functions =======

    public fun to_fields(
        rbac: &RBAC
    ): (address, &VecMap<address, vector<String>>, &VecMap<String, vector<Permission>>) {
        (rbac.principal, &rbac.agent_roles, &rbac.role_permissions)
    }

    public fun principal(rbac: &RBAC): address {
        rbac.principal
    }

    public fun agent_roles(rbac: &RBAC): &VecMap<String, vector<String>> {
        &rbac.agent_roles
    }

    public fun role_permissions(rbac: &RBAC): &VecMap<String, Permission> {
        &rbac.role_permissions
    }
}