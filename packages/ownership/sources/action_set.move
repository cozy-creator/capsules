// This is an internal module used by tx_authority and delegations
// General actions are actions the agent can take on behalf of the principal, without any restriction
// to type of object-id.
// on-types and and on-objects restrict actions to a given set of types and object-ids, giving
// delegators much more granular control.

module ownership::action_set {
    use sui::object::ID;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::struct_tag::StructTag;

    use ownership::action::{Self, Action};

    friend ownership::tx_authority;
    friend ownership::delegation;

    // TO DO: Is `copy` + `store` a security vulnerability? Can someone get ahold of this, store it,
    // and use it maliciously later?
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
        let general = permission::intersection(&self.general, &filter.general);
        let on_types = permission::vec_map_intersection(
            &self.on_types, &filter.general, &filter.on_types);
        let on_objects = permission::vec_map_intersection(
            &self.on_objects, &filter.general, &filter.on_objects);
        
        ActionSet { general, on_types, on_objects }
    }

    // This ensures that permissions are not improperly overwritten
    public(friend) fun merge(self: &mut ActionSet, new: ActionSet) {
        let ActionSet { general, on_types, on_objects } = new;
        permission::add(&mut self.general, general);
        permission::vec_map_add(&mut self.on_types, on_types);
        permission::vec_map_add(&mut self.on_objects, on_objects);
    }

    // ======== Field Accessors ========

    public fun general(set: &ActionSet): &vector<Action> {
        &set.general
    }

    public fun types(set: &ActionSet): &VecMap<StructTag, vector<Action>> {
        &set.on_types
    }

    public fun objects(set: &ActionSet): &VecMap<ID, vector<Action>> {
        &set.on_objects
    }

    public(friend) fun general_mut(set: &mut ActionSet): &mut vector<Action> {
        &mut set.general
    }

    public(friend) fun types_mut(set: &mut ActionSet): &mut VecMap<StructTag, vector<Action>> {
        &mut set.on_types
    }

    public(friend) fun objects_mut(set: &mut ActionSet): &mut VecMap<ID, vector<Action>> {
        &mut set.on_objects
    }
}