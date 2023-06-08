// Store delegation -> claim delegation -> merge-into tx_authority -> check tx_authority

// ===== Examples =====
//
// I want you to be able to edit any of my Capsuleverse objects as myself:
// { on_types: [capsuleverse::Capsuleverse -> [capsuleverse::EDIT] ] }
//
// I want you to be able to withdraw currency from a set of accounts as myself:
// { on_objects: [account1 -> [account::WITHDRAW], account2 -> [account::WITHDRAW] ] }
//
// I want you to be able to sell any Outlaws as myself:
// { on_types: [outlaw_sky::Outlaw -> [transfer_market::SELL] ] }
//
// I want you to be able to sell anything I own:
// { general: [transfer_market::SELL] } (<-- risky! Not enabled)

// ===== Action Chaining =====
//
// 1. `Owner` grants EDIT action to `Organization`.
// 2. `Organization` creates a role that includes the EDIT action, and gives `Server` this role.
// 3 .`Server` logs into `Organization` and claims the [EDIT as Organization] action; this is added
// to TxAuthority.
// 4. The server then logs into `Owner` delegation and retrieves [EDIT as Owner]; transitive. This
// is added to TxAuthority.
//
// We call this sort of A -> B -> C indirect delegation "delegation chaining" and it is a powerful
// primitive.
// Chaining even works for types and objects! Not just 'general'

// ===== Restrictions =====
//
// You cannot add action::ADMIN, action::MANAGER, or ownership::TRANSFER as a 'general' action.
// This would be too risky and would likely result in users being phished.
// You may however delegate these actions for types and/or object-ids.

module ownership::delegation {
    use std::option;
    use std::vector;

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_map;

    use sui_utils::dynamic_field2;
    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::vector2;
    use sui_utils::vec_map2;

    use ownership::action::{Self, ADMIN};
    use ownership::action_set::{Self, ActionSet};
    use ownership::tx_authority::{Self, TxAuthority};

    // Error codes
    const ENO_ADMIN_AUTHORITY: u64 = 0;
    const EINVALID_DELEGATION: u64 = 1;

    // Root-level, shared object. The owner is the principle, and is immutable (non-transferable).
    // This serves a purpose similar to RBAC, in that it persons delegated actions
    struct Person has key {
        id: UID,
        principal: address,
        guardian: address
    }

    // Stores `ActionSet` inside of a Person object
    struct Key has store, copy, drop { agent: address } 

    // ======= For Owners =======

    public fun create(guardian: address, ctx: &mut TxContext): Person {
        Person {
            id: object::new(ctx),
            principal: tx_context::sender(ctx),
            guardian
        }
    }

    public fun create_(principal: address, guardian: address, auth: &TxAuthority, ctx: &mut TxContext): Person {
        assert!(tx_authority::can_act_as_address<ADMIN>(principal, auth), ENO_ADMIN_AUTHORITY);

        Person {
            id: object::new(ctx),
            principal,
            guardian
        }
    }

    public fun return_and_share(person: Person) {
        transfer::share_object(person);
    }

    // This won't work yet, but it will once Sui supports deleting shared objects (late 2023)
    public fun destroy(person: Person, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let Person { id, principal: _, guardian: _ } = person;
        object::delete(id);
    }

    // ======= Add Agent Actions =======

    public fun add_general_action<Action>(
        person: &mut Person,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);
        assert!(!action::is_admin_action<Action>() &&
            !action::is_manager_action<Action>(), EINVALID_DELEGATION);

        let general = action_set::general_mut(agent_actions_mut(person, agent));
        vector2::push_back_unique(general, action::new<Action>());
    }

    public fun add_action_for_type<ObjectType, Action>(
        person: &mut Person,
        agent: address,
        auth: &TxAuthority
    ) {
        let types = vector[struct_tag::get<ObjectType>()];
        add_action_for_types<Action>(person, agent, types, auth);
    }

    // Using struct-tag allows for us to match entire classes of types; adding an abstract type without
    // its generics will match all concrete-types that implement it. Missing generics are treated as *
    // wildcard when type-matching.
    //
    // Example: StructTag { address: 0x2, module_name: coin, struct_name: Coin, generics: [] } will match
    // all Coin<*> types. Effectively, this grants the action over all Coin types. If you don't want
    // this behavior, simply specify the generics, like Coin<SUI>.
    public fun add_action_for_types<Action>(
        person: &mut Person,
        agent: address,
        types: vector<StructTag>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let action = action::new<Action>();
        let types_map = action_set::types_mut(agent_actions_mut(person, agent));

        while (vector::length(&types) > 0) {
            let type = vector::pop_back(&mut types);
            let type_actions = vec_map2::borrow_mut_fill(types_map, &type, vector[]);
            vector2::push_back_unique(type_actions, action);
        };
    }

    public fun add_action_for_objects<Action>(
        person: &mut Person,
        agent: address,
        objects: vector<ID>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let action = action::new<Action>();
        let objects_map = action_set::objects_mut(agent_actions_mut(person, agent));

        while (vector::length(&objects) > 0) {
            let object_id = vector::pop_back(&mut objects);
            let object_actions = vec_map2::borrow_mut_fill(objects_map, &object_id, vector[]);
            vector2::push_back_unique(object_actions, action);
        };
    }

    // ======= Remove Agent Actions =======

    public fun remove_general_action_from_agent<Action>(
        person: &mut Person,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let general = action_set::general_mut(agent_actions_mut(person, agent));
        vector2::remove_maybe(general, &action::new<Action>());
    }

    public fun remove_all_general_actions_from_agent(
        person: &mut Person,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let general = action_set::general_mut(agent_actions_mut(person, agent));
        *general = vector[];
    }

    public fun remove_action_for_type_from_agent<ObjectType, Action>(
        person: &mut Person,
        agent: address,
        auth: &TxAuthority
    ) {
        let types = vector[struct_tag::get<ObjectType>()];
        remove_action_for_types_from_agent<Action>(person, agent, types, auth);
    }

    public fun remove_action_for_types_from_agent<Action>(
        person: &mut Person,
        agent: address,
        types: vector<StructTag>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let types_map = action_set::types_mut(agent_actions_mut(person, agent));
        let action = action::new<Action>();

        while (!vector::is_empty(&types)) {
            let type_key = vector::pop_back(&mut types);
            let index_maybe = vec_map::get_idx_opt(types_map, &type_key);
            if (option::is_some(&index_maybe)) {
                let index = option::destroy_some(index_maybe);
                let (_, actions) = vec_map::get_entry_by_idx_mut(types_map, index);
                vector2::remove_maybe(actions, &action);
            };
        };
    }

    public fun remove_type_from_agent<ObjectType>(
        person: &mut Person,
        agent: address,
        auth: &TxAuthority
    ) {
       assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let types_map = action_set::types_mut(agent_actions_mut(person, agent));
        let type_key = struct_tag::get<ObjectType>();
        vec_map2::remove_maybe(types_map, &type_key);
    }

    public fun remove_types_from_agent(
        person: &mut Person,
        agent: address,
        types: vector<StructTag>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let types_map = action_set::types_mut(agent_actions_mut(person, agent));

        while(!vector::is_empty(&types)) {
            let type_key = vector::pop_back(&mut types);
            vec_map2::remove_maybe(types_map, &type_key);
        };
    }

    public fun remove_action_for_objects_from_agent<Action>(
        person: &mut Person,
        agent: address,
        objects: vector<ID>,
        auth: &TxAuthority,
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let objects_map = action_set::objects_mut(agent_actions_mut(person, agent));
        let action = action::new<Action>();

        while(!vector::is_empty(&objects)) {
            let object_key = vector::pop_back(&mut objects);
            let index_maybe = vec_map::get_idx_opt(objects_map, &object_key);
            if (option::is_some(&index_maybe)) {
                let index = option::destroy_some(index_maybe);
                let (_, actions) = vec_map::get_entry_by_idx_mut(objects_map, index);
                vector2::remove_maybe(actions, &action);
            };
        }
    }

    public fun remove_objects_from_agent(
        person: &mut Person,
        agent: address,
        objects: vector<ID>,
        auth: &TxAuthority,
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        let objects_map = action_set::objects_mut(agent_actions_mut(person, agent));

        while (!vector::is_empty(&objects)) {
            let object_key = vector::pop_back(&mut objects);
            vec_map2::remove_maybe(objects_map, &object_key);
        };
    }

    public fun remove_agent(
        person: &mut Person,
        agent: address,
        auth: &TxAuthority,
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(person.principal, auth), ENO_ADMIN_AUTHORITY);

        dynamic_field2::drop<address, ActionSet>(&mut person.id, Key { agent });
    }

    // ======= For Agents =======

    public fun claim_delegation(person: &Person, ctx: &TxContext): TxAuthority {
        let agent = tx_context::sender(ctx);
        let auth = tx_authority::begin(ctx);
        claim_delegation_(person, agent, &auth)
    }

    // We don't need to add an assertion here because merge_action_set_internal will filter
    // out any actions not currently present in auth already for the agent. Meaning that if
    // you call this without having the agent already present in your auth, this function does
    // nothing other than return the same TxAuthority you gave it.
    public fun claim_delegation_(person: &Person, agent: address, auth: &TxAuthority): TxAuthority {
        let set = agent_actions_value(person, agent);
        tx_authority::merge_action_set_internal(person.principal, agent, set, auth)
    }

    // ======= Internal Helper Functions =======

    fun agent_actions_mut(person: &mut Person, agent: address): &mut ActionSet {
        let fallback = action_set::empty();
        dynamic_field2::borrow_mut_fill(&mut person.id, Key { agent }, fallback)
    }

    fun agent_actions_value(person: &Person, agent: address): ActionSet {
        let set_maybe = dynamic_field2::get_maybe(&person.id, Key { agent });
        if (option::is_some(&set_maybe)) {
            option::destroy_some(set_maybe)
        } else {
            action_set::empty()
        }
    }

    // ======= Getters =======

    public fun principal(person: &Person): address {
        person.principal
    }

    public fun guardian(person: &Person): address {
        person.guardian
    }

    public fun agent_actions(person: &Person, agent: address): ActionSet {
        let fallback = action_set::empty();
        dynamic_field2::get_with_default(&person.id, Key { agent }, fallback)
    }

    // ======= Extend Pattern =======

    public fun uid(person: &Person): &UID {
        person.id
    }

    public fun uid_mut(person: &mut Person): &mut UID {
        &mut person.id
    }

    // ======= Convenience Entry Functions =======
    // TO DO: provide entry functions for all public API functions

    entry fun create_delegation_person(
        ctx: &mut TxContext
    ) {
        return_and_share(create(ctx))
    }

    entry fun destroy_delegation_person(
        person: Person,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        destroy(person, &auth)
    }

    entry fun add_general_action_<Action>(
        person: &mut Person,
        agent: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        add_general_action<Action>(person, agent, &auth)
    }

    public fun add_action_for_types_<Action>(
        person: &mut Person,
        agent: address,
        types: vector<StructTag>,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        add_action_for_types<Action>(person, agent, types, &auth)
    }

    entry fun add_action_for_type_<ObjectType, Action>(
        person: &mut Person,
        agent: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        add_action_for_type<ObjectType, Action>(person, agent, &auth)
    }

    entry fun add_action_for_objects_<Action>(
        person: &mut Person,
        agent: address,
        objects: vector<ID>,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        add_action_for_objects<Action>(person, agent, objects, &auth)
    }

    entry fun remove_general_action_from_agent_<Action>(
        person: &mut Person,
        agent: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_general_action_from_agent<Action>(person, agent, &auth)
    }

    entry fun remove_all_general_actions_from_agent_(
        person: &mut Person,
        agent: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_all_general_actions_from_agent(person, agent, &auth)
    }

    entry fun remove_action_for_type_from_agent_<ObjectType, Action>(
        person: &mut Person,
        agent: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_action_for_type_from_agent<ObjectType, Action>(person, agent, &auth)
    }

    entry fun remove_action_for_types_from_agent_<Action>(
        person: &mut Person,
        agent: address,
        types: vector<StructTag>,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_action_for_types_from_agent<Action>(person, agent, types, &auth)
    }

    entry fun remove_type_from_agent_<ObjectType>(
        person: &mut Person,
        agent: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_type_from_agent<ObjectType>(person, agent, &auth)
    }

    entry fun remove_types_from_agent_(
        person: &mut Person,
        agent: address,
        types: vector<StructTag>,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_types_from_agent(person, agent, types, &auth)
    }

    entry fun remove_action_for_objects_from_agent_<Action>(
        person: &mut Person,
        agent: address,
        objects: vector<ID>,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_action_for_objects_from_agent<Action>(person, agent, objects, &auth)
    }

    entry fun remove_objects_from_agent_(
        person: &mut Person,
        agent: address,
        objects: vector<ID>,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_objects_from_agent(person, agent, objects, &auth)
    }

    entry fun remove_agent_(
        person: &mut Person,
        agent: address,
        ctx: &TxContext,
    ) {
        let auth = tx_authority::begin(ctx);
        remove_agent(person, agent, &auth) 
    }
}