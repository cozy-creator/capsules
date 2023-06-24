// This is an internal module used by tx_authority and delegations
// General actions are actions the agent can take on behalf of the principal, without any restriction
// to type of object-id.
// on-types and and on-objects restrict actions to a given set of types and object-ids, giving
// delegators much more granular control.

module ownership::action_set {
    use std::option;
    use std::vector;

    use sui::object::ID;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::struct_tag::StructTag;
    use sui_utils::vector2;
    use sui_utils::vec_map2;

    use ownership::action::{Self, Action};

    friend ownership::tx_authority;
    friend ownership::person;
    // friend ownership::pending_action;

    // Because this has copy + store, references to this struct should not be made public
    struct ActionSet has store, copy, drop {
        general: vector<Action>,
        on_types: VecMap<StructTag, vector<Action>>,
        on_objects: VecMap<ID, vector<Action>>
    }

    public(friend) fun empty(): ActionSet {
        ActionSet {
            general: vector[],
            on_types: vec_map::empty(),
            on_objects: vec_map::empty()
        }
    }

    public(friend) fun new(contents: vector<Action>): ActionSet {
        ActionSet {
            general: contents,
            on_types: vec_map::empty(),
            on_objects: vec_map::empty()
        }
    }

    public(friend) fun intersection(self: &ActionSet, filter: &ActionSet): ActionSet {
        let general = action::intersection(&self.general, &filter.general);
        let on_types = action::vec_map_intersection(
            &self.on_types, &filter.general, &filter.on_types);
        let on_objects = action::vec_map_intersection(
            &self.on_objects, &filter.general, &filter.on_objects);
        
        ActionSet { general, on_types, on_objects }
    }

    // This ensures that actions are not improperly overwritten
    public(friend) fun merge(self: &mut ActionSet, new: ActionSet) {
        let ActionSet { general, on_types, on_objects } = new;
        action::add(&mut self.general, general);
        action::vec_map_join(&mut self.on_types, on_types);
        action::vec_map_join(&mut self.on_objects, on_objects);
    }

    // ======== Modification API ========

    public(friend) fun add_general<Action>(set: &mut ActionSet) {
        vector2::push_back_unique(&mut set.general, action::new<Action>());
    }

    public(friend) fun add_general_(set: &mut ActionSet, actions: vector<Action>) {
        vector2::merge(&mut set.general, actions);
    }

    public(friend) fun remove_general<Action>(set: &mut ActionSet) {
        vector2::remove_maybe(&mut set.general, &action::new<Action>());
    }

    public(friend) fun remove_all_general(set: &mut ActionSet) {
        *&mut set.general = vector[];
    }

    public(friend) fun add_action_for_types<Action>(set: &mut ActionSet, types: vector<StructTag>) {
        while (vector::length(&types) > 0) {
            let type = vector::pop_back(&mut types);
            let type_actions = vec_map2::borrow_mut_fill(&mut set.on_types, &type, vector[]);
            vector2::push_back_unique(type_actions, action::new<Action>());
        };
    }

    public(friend) fun remove_action_for_types<Action>(set: &mut ActionSet, types: vector<StructTag>) {
        let action = action::new<Action>();

        while (!vector::is_empty(&types)) {
            let type_key = vector::pop_back(&mut types);
            let index_maybe = vec_map::get_idx_opt(&mut set.on_types, &type_key);
            if (option::is_some(&index_maybe)) {
                let index = option::destroy_some(index_maybe);
                let (_, actions) = vec_map::get_entry_by_idx_mut(&mut set.on_types, index);
                vector2::remove_maybe(actions, &action);
            };
        };
    }

    public(friend) fun remove_all_actions_for_types(set: &mut ActionSet, types: vector<StructTag>) {
        while (!vector::is_empty(&types)) {
            let type_key = vector::pop_back(&mut types);
            vec_map2::remove_maybe(&mut set.on_types, &type_key);
        };
    }

    public(friend) fun add_action_for_objects<Action>(set: &mut ActionSet, objects: vector<ID>) {
        while (vector::length(&objects) > 0) {
            let object_id = vector::pop_back(&mut objects);
            let object_actions = vec_map2::borrow_mut_fill(&mut set.on_objects, &object_id, vector[]);
            vector2::push_back_unique(object_actions, action::new<Action>());
        };
    }

    public(friend) fun remove_action_for_objects<Action>(set: &mut ActionSet, objects: vector<ID>) {
        let action = action::new<Action>();

        while(!vector::is_empty(&objects)) {
            let object_key = vector::pop_back(&mut objects);
            let index_maybe = vec_map::get_idx_opt(&mut set.on_objects, &object_key);
            if (option::is_some(&index_maybe)) {
                let index = option::destroy_some(index_maybe);
                let (_, actions) = vec_map::get_entry_by_idx_mut(&mut set.on_objects, index);
                vector2::remove_maybe(actions, &action);
            };
        }
    }

    public(friend) fun remove_all_actions_for_objects(set: &mut ActionSet, objects: vector<ID>) {
        while (!vector::is_empty(&objects)) {
            let object_key = vector::pop_back(&mut objects);
            vec_map2::remove_maybe(&mut set.on_objects, &object_key);
        };
    }

    // ======== Getters ========

    public fun general(set: &ActionSet): &vector<Action> {
        &set.general
    }

    public fun on_types(set: &ActionSet): &VecMap<StructTag, vector<Action>> {
        &set.on_types
    }

    public fun on_objects(set: &ActionSet): &VecMap<ID, vector<Action>> {
        &set.on_objects
    }

    // =========== Single-use actions ===========
    // Created by ownership::pending_action, consumed by ownership::tx_authority.
    // These allows parties to delegate an action now, and have it performed later, but only once.
    // In the future, these could also be used to compensate for Sui's lack of native support for
    // multi-party transactions.

    // struct SingleUseActions has store, drop {
    //     principal: address,
    //     actions: ActionSet
    // }

    // public(friend) fun create_single_use(principal: address, actions: ActionSet): SingleUseActions {
    //     SingleUseActions { principal, actions }
    // }

    // public(friend) fun consume_single_use(single_use: SingleUseActions): (address, ActionSet) {
    //     let SingleUseActions { principal, actions } = single_use;
    //     (principal, actions)
    // }
}