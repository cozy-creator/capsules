// Sui's Role Based Access Control (RBAC) system

// This allows a principal (address) to delegate a set of actions to an agent (address).
// Roles provide a layer of abstraction; instead of granting each agent a set of actions individually,
// you assign each agent a set of roles, and then define the actions for each of those roles.

// A delegation is:
// The specification of a action (type), enabling access to a set of function calls
// By an agent
// On behalf of the principle

// An RBAC can be used to delegate control of an account
// Example: a game-studio runs a number of servers, and gives their keypairs actions to edit
// its game objects.

// For safety, we are limiting RBACs to only organizations for now.
// Previously considered functionality:
// - Allow any user to create an RBAC / organizations so other people can use their account
// - Allow RBAC to be stored inside of objects, and grant actions to that object on behalf of
// owners.
// We removed this functionality for now because it's too dangerous and complex.
// For simplicity, we limit each agent to having only one role at a time.

// Note that there will never be a action-vector containing the ADMIN or MANAGER actions; rather
// you should instead use the grant_admin_role_for_agent() and grant_manager_role_for_agent() functions.
// These give special reserved role-names, as defined in ownership::actions.

// For security, this module is only callable by ownership::organization

module ownership::rbac {
    use std::option;
    use std::string::String;
    use std::vector;

    use sui::vec_map::{Self, VecMap};

    use sui_utils::vector2;
    use sui_utils::vec_map2;

    use ownership::action::{Self, Action, ADMIN};

    friend ownership::organization;

    // Error enums
    const ENO_PRINCIPAL_AUTHORITY: u64 = 0;

    // Reserved role names
    // const ADMIN_ROLE: vector<u8> = b"ADMIN";
    // const MANAGER_ROLE: vector<u8> = b"MANAGER";

    // After creation the principal cannot be changed
    // This can be modified with mere referential authority; store this somewhere private
    struct RBAC has store, drop {
        principal: address, // action granted on behalf of
        agent_role: VecMap<address, String>, // agent -> role
        role_actions: VecMap<String, vector<Action>> // role -> actions
    }

    // ======= Principal API =======

    // The principal cannot be changed after creation
    public(friend) fun create(principal: address): RBAC {
        RBAC {
            principal,
            agent_role: vec_map::empty(),
            role_actions: vec_map::empty()
        }
    }

    // ======= Assign Agents to a Role =======

    // Creates or overwrites existing role for agent
    public(friend) fun set_role_for_agent(rbac: &mut RBAC, agent: address, role: String) {
        vec_map2::set(&mut rbac.agent_role, &agent, role);
        // Ensure that role exists in rbac.role_actions
        vec_map2::borrow_mut_fill(&mut rbac.role_actions, &role, vector::empty());
    }

    public(friend) fun delete_agent(rbac: &mut RBAC, agent: address) {
        vec_map2::remove_maybe(&mut rbac.agent_role, &agent);
    }

    // ======= Assign Actions to Roles =======

    public(friend) fun grant_action_to_role<Action>(rbac: &mut RBAC, role: String) {
        let action = action::new<Action>();
        if (action::is_admin_action_(&action) || action::is_manager_action_(&action)) {
            // Admin and Manager actions overwrite all other existing actions
            vec_map2::set(&mut rbac.role_actions, &role, vector[action]);
        } else {
            let existing = vec_map2::borrow_mut_fill(&mut rbac.role_actions, &role, vector::empty());
            vector2::merge(existing, vector[action]);
        };
    }

    // Empty roles (with no actions) are not automatically deleted
    public(friend) fun revoke_action_from_role<Action>(rbac: &mut RBAC, role: String) {
        let action = action::new<Action>();
        let existing = vec_map2::borrow_mut_fill(&mut rbac.role_actions, &role, vector::empty());
        vector2::remove_maybe(existing, &action);
    }

    // Any agent with this role will also be removed. The agents can always be re-added with new roles.
    public(friend) fun delete_role_and_agents(rbac: &mut RBAC, role: String) {
        vec_map2::remove_entries_with_value(&mut rbac.agent_role, &role);
        vec_map2::remove_maybe(&mut rbac.role_actions, &role);
    }

    // ======= Getter Functions =======

    public(friend) fun to_fields(
        rbac: &RBAC
    ): (address, &VecMap<address, String>, &VecMap<String, vector<Action>>) {
        (rbac.principal, &rbac.agent_role, &rbac.role_actions)
    }

    public fun principal(rbac: &RBAC): address {
        rbac.principal
    }

    public fun agent_role(rbac: &RBAC): &VecMap<address, String> {
        &rbac.agent_role
    }

    public(friend) fun role_actions(rbac: &RBAC): &VecMap<String, vector<Action>> {
        &rbac.role_actions
    }

    // The principal always has ADMIN action over themselves; there is no need to give the principal
    // a role within the RBAC.
    public(friend) fun get_agent_actions(rbac: &RBAC, agent: address): vector<Action> {
        if (agent == rbac.principal) {
            return vector[action::new<ADMIN>()]
        };

        let role_maybe = vec_map2::get_maybe(&rbac.agent_role, &agent);
        if (option::is_some(&role_maybe)) {
            let role = option::destroy_some(role_maybe);
            *vec_map::get(&rbac.role_actions, &role)
        } else {
            vector[]
        }
    }

    public(friend) fun get_admin(): vector<Action> {
        vector[action::new<ADMIN>()]
    }
}

    // struct Key has store, copy, drop { principal: address }

    // Used by the principal to create roles and delegate actions to agents

    // public fun create(principal: address, auth: &TxAuthority): RBAC {
    //     assert!(tx_authority::is_signed_by(principal, auth), ENO_PRINCIPAL_AUTHORITY);

    //     create_internal(principal)
    // }

    // Note that if another rbac is stored in this UID for the same principal, it will be overwritten
    // public fun store(uid: &mut UID, rbac: RBAC) {
    //     dynamic_field2::set(uid, Key { principal: rbac.principal }, rbac);
    // }

    // // Convenience function
    // public fun create_and_store(uid: &mut UID, principal: address, auth: &TxAuthority) {
    //     let rbac = create(principal, auth);
    //     store(uid, rbac);
    // }

    // public fun borrow(): &RBAC {
    // }

    // public fun borrow_mut(): &mut RBAC {
    // }

    // public fun remove(): RBAC {
    // }


    // ======= Agent API =======
    // Used by agents to retrieve their delegated actions

    // Convenience function. Uses type T as the principal-address
    // public fun claim<T>(uid: &UID, ctx: &TxContext): TxAuthority {
    //     let principal = tx_authority::type_into_address<T>();
    //     let auth = tx_authority::begin(ctx);
    //     claim_(uid, principal, tx_context::sender(ctx), auth)
    // }

    // Auth is passed in here to be added onto, not because it's used as a proof of ownership
    // public fun claim_(uid: &UID, principal: address, agent: address, auth: &TxAuthority): TxAuthority {
    //     if (!dynamic_field::exists_(uid, Key { principal })) { return auth };

    //     let rbac = dynamic_field::borrow<Key, RBAC>(uid, Key { principal });
    //     let roles = vec_map2::get_with_default(&rbac.agent_role, agent, vector::empty());
    //     let i = 0;
    //     while (i < vector::length(roles)) {
    //         let action = vec_map::get(&rbac.role_actions, *vector::borrow(roles, i));
    //         auth = tx_authority::add_actions_internal(principal, action, &auth);
    //         i = i + 1;
    //     };

    //     auth
    // }

    // This is rather complicated for a validity checker honestly
    // public fun is_allowed_by_owner<T>(uid: &UID, function: u8, auth: &TxAuthority): bool {
    //     let owner_maybe = ownership::get_owner(uid);
    //     if (option::is_none(owner_maybe)) { 
    //         return false // owner is undefined
    //     };
    //     let owner = option::destroy_some(owner_maybe);

    //     // Claim any delegations that may be waiting for us inside inside of this UID
    //     let i = 0;
    //     let agents = tx_authority::agents(auth);
    //     while (i < vector::length(&agents)) {
    //         let agent = *vector::borrow(&agents, i);
    //         auth = claim_(uid, owner, agent, auth);
    //         i = i + 1;
    //     };

    //     // The owner is a signer, or a delegation from the owner for this function already exists within `auth`
    //     tx_authority::is_allowed<T>(owner, function, auth)
    // }