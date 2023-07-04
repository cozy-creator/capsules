// Sui's action system, used to delegate authority from a principal to an agent
// We call these actions 'actions' for clarity. Packages can define their own arbitrary actions
// as structs; these structs do not need to be instantiated; they exist solely for type-checking.
//
// I wish that actions could be typed, like Action<T>, but that would make them hard
// to store, as vectors do not support heterogenous types. sui::Bag would work,
// but that's not droppable, so they'd have to explicitly be destroyed at the end of every tx.

module ownership::action {
    use std::option;
    use std::string::String;
    use std::vector;

    // use sui::object::{Self, UID};
    // use sui::tx_context::TxContext;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    use sui_utils::vector2;
    use sui_utils::vec_map2;

    friend ownership::person;
    friend ownership::organization;
    friend ownership::action_set;
    friend ownership::rbac;
    friend ownership::tx_authority;

    // This has `store` + `copy` which could be dangerous? We need to keep all refs these private
    struct Action has store, copy, drop {
        inner: String
    }

    public(friend) fun new<Act>(): Action {
        Action { inner: encode::type_name<Act>() }
    }
    
    // Delegations only extend an agent's power to equal or lower levels, never up.
    //
    // Example: Alice delegates [CREATE] to Bob--this means Bob can call in and perform a CREATE action
    // as if he were Alice. Bob now delegates [CREATE, DELETE] to Charlie. This means Charlie can now
    // do both CREATE and DELETE as Bob, and by inheritance, can also do CREATE as Alice as well.
    // However, Charlie cannot perform DELETE or any other action as Alice.
    //
    // That is, everything in `actions` that is outside of the `filter` will be removed
    public(friend) fun intersection(actions: &vector<Action>, filter: &vector<Action>): vector<Action> {
        if (contains_admin(filter)) { return *actions };

        if (contains_manager(filter)) {
            if (contains_admin(actions)) { return vector[manager()] }; // Downgrade to manager
            return *actions
        };

        if (contains_admin(actions) || contains_manager(actions)) { 
            return *filter
        };

        vector2::intersection(actions, filter)
    }

    public(friend) fun vec_map_intersection<T: copy + drop>(
        self: &VecMap<T, vector<Action>>, 
        general_filter: &vector<Action>,
        specific_filter: &VecMap<T, vector<Action>>
    ): VecMap<T, vector<Action>> {
        let i = 0;
        let filtered = vec_map::empty<T, vector<Action>>();
        while (i < vec_map::size(self)) {
            let (key, value) = vec_map::get_entry_by_idx(self, i);

            let specific_filter_maybe = vec_map::try_get(specific_filter, key);
            let filtered_value = if (option::is_some(&specific_filter_maybe)) {
                let this_specific_filter = option::destroy_some(specific_filter_maybe);
                let this_filter = add_(general_filter, this_specific_filter);
                intersection(value, &this_filter)
            } else {
                intersection(value, general_filter)
            };

            vec_map::insert(&mut filtered, *key, filtered_value);

            i = i + 1;
        };

        filtered
    }

    public(friend) fun add(existing: &mut vector<Action>, new: vector<Action>) {
        let (admin, manager) = (admin(), manager());

        // This prevents accidental action downgrades
        if (contains_admin(existing)) { return };

        // These superseed and replace all existing actions
        if (vector::contains(&new, &admin)) {
            *existing = vector[admin];
            return
        };
        if (vector::contains(&new, &manager)) { 
            *existing = vector[manager];
            return
        };

        vector2::merge(existing, new);
    }

    // Doesn't modify the existing vectors
    public(friend) fun add_(existing: &vector<Action>, new: vector<Action>): vector<Action> {
        let (admin, manager) = (admin(), manager());

        // This prevents accidental action downgrades
        if (contains_admin(existing)) { return *existing };

        // These superseed and replace all existing actions
        if (vector::contains(&new, &admin)) {
            return vector[admin]
        };
        if (vector::contains(&new, &manager)) { 
            return vector[manager]
        };

        vector2::merge_(existing, &new)
    }

    public(friend) fun vec_map_join<K: copy + drop>(
        existing: &mut VecMap<K, vector<Action>>,
        new: VecMap<K, vector<Action>>
    ) {
        while (vec_map::size(&new) > 0) {
            let (key, value) = vec_map::pop(&mut new);
            let self = vec_map2::borrow_mut_fill(existing, &key, vector[]);
            add(self, value);
       };
    }

    public fun contains<Act>(actions: &vector<Action>): bool {
        if (contains_admin(actions) || contains_manager(actions)) {
            return true
        };

        if (is_any<Act>() && vector::length(actions) > 0) { return true };

        let type_name = encode::type_name<Act>();
        let i = 0;
        while (i < vector::length(actions)) {
            let action = vector::borrow(actions, i);
            if (action.inner == type_name) {  return true };
            i = i + 1;
        };

        false
    }

    public fun contains_excluding_manager<Act>(actions: &vector<Action>): bool {
        if (contains_manager(actions)) { return false };
        contains<Act>(actions)
    }

    // ========= Special System-Level Actions =========
    // If the principal gives an agent the MANAGER action, then they can act as
    // that agent for all action-types (there is no scope), except for admin.
    //
    // With the ADMIN action, an agent is indistinguishable from the delegating principal.
    // Granting the ADMIN action is potentially dangerous, as the agent can then grant _other_ agents
    // the rights of the principal as well, ad inifintum. If this occurs, it could be virtually impossible
    // to revoke the rights of the agent and make the principal secure again.
    //
    // ANY is intended to be a wild-card, like `can_act_as<*>(actions)` and as long as their at least one
    // action, it will return 'true'.
    struct ADMIN {}
    struct MANAGER {}
    struct ANY {}

    public(friend) fun admin(): Action {
        Action { inner: encode::type_name<ADMIN>() }
    }

    public(friend) fun manager(): Action {
        Action { inner: encode::type_name<MANAGER>() }
    }

    public fun contains_admin(actions: &vector<Action>): bool {
        vector::contains(actions, &admin())
    }

    public fun is_admin_action<Action>(): bool {
        encode::is_same_type<Action, ADMIN>()
    }

    public fun is_admin_action_(action: &Action): bool {
        action.inner == encode::type_name<ADMIN>()
    }

    public fun contains_manager(actions: &vector<Action>): bool {
        vector::contains(actions, &manager())
    }

    public fun is_manager_action<Action>(): bool {
        encode::is_same_type<Action, MANAGER>()
    }

    public fun is_manager_action_(action: &Action): bool {
        action.inner == encode::type_name<MANAGER>()
    }

    public fun is_any<Action>(): bool {
        encode::type_name<Action>() == encode::type_name<ANY>()
    }

    public fun is_any_(action: &Action): bool {
        action.inner == encode::type_name<ANY>()
    }

    #[test_only]
    public fun new_for_testing<A>(): Action {
        new<A>()
    }
}

    // Can be stored, but not copied. Used as a template to produce Action structs
    // Anyone who can obtain a reference to this can use it; store it somewhere private
    // struct StoredAction has store, drop {
    //     inner: String
    // }

    // Turns persistent (Stored) actions into ephemeral actions. Ephemeral actions are always
    // dropped at the end of a transaction.
    // public(friend) fun clone(stored: &vector<StoredAction>): vector<Action> {
    //     let i = 0;
    //     let actions = vector::empty<Action>();
    //     while (i < vector::length(&stored)) {
    //         let inner = vector::borrow(&stored, i).inner;
    //         vector::push_back(&mut actions, Action { inner });
    //         i = i + 1;
    //     };
    // }