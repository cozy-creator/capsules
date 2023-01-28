module sui_utils::map {
    use std::option::{Self, Option};
    use std::vector;
    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;

    const MAX_LENGTH: u64 = 65536;

    // Error enums
    const EKEY_ALREADY_EXISTS: u64 = 0;
    const EKEY_NOT_FOUND: u64 = 1;
    const EMAP_IS_FULL: u64 = 2;
    const EMAP_NOT_EMPTY: u64 = 3;
    const EITERABLE_MISMATCH: u64 = 4;

    struct Map<Key, phantom Value> has key, store {
        id: UID,
        index: vector<Key>
    }

    public fun empty<Key: store + copy + drop, Value: store>(ctx: &mut TxContext): Map<Key, Value> {
        Map { 
            id: object::new(ctx),
            index: vector::empty<Key>()
        }
    }

    public fun add<Key: store + copy + drop, Value: store>(map: &mut Map<Key, Value>, key: Key, value: Value) {
        add_to_index(map, copy key);
        dynamic_field::add(&mut map.id, key, value);
    }

    public fun borrow<Key: store + copy + drop, Value: store>(
        map: &Map<Key, Value>,
        key: Key
    ): &Value {
        dynamic_field::borrow<Key, Value>(&map.id, key)
    }

    public fun borrow_mut<Key: store + copy + drop, Value: store>(
        map: &mut Map<Key, Value>,
        key: Key
    ): &mut Value {
        dynamic_field::borrow_mut<Key, Value>(&mut map.id, key)
    }
    
    public fun remove<Key: store + copy + drop, Value: store>(map: &mut Map<Key, Value>, key: Key): Value {
        remove_from_index(map, copy key);
        dynamic_field::remove(&mut map.id, key)
    }

    public fun exists_<Key: store + copy + drop, Value: store>(map: &Map<Key, Value>, key: Key): bool {
        let (exists, _i) = vector::index_of(&map.index, &key);
        exists
    }

    public fun length<Key: store + copy + drop, Value: store>(map: &Map<Key, Value>): u64 {
        vector::length(&map.index)
    }

    public fun into_keys<Key: store + copy + drop, Value: store>(map: &Map<Key, Value>): vector<Key> {
        *&map.index
    }

    // This iterates over and deletes all child elements, so no data is orphaned
    // This only works if the Value has drop
    public fun delete<Key: store + copy + drop, Value: store + drop>(map: Map<Key, Value>) {
        let Map { id, index } = map;
        let i = 0;
        while (i < vector::length(&index)) {
            dynamic_field::remove<Key, Value>(&mut id, *vector::borrow(&index, i));
            i = i + 1;
        };
        object::delete(id);
    }

    public fun delete_empty<Key: store + copy + drop, Value: store>(map: Map<Key, Value>) {
        assert!(vector::length(&map.index) == 0, EMAP_NOT_EMPTY);

        let Map { id, index: _ } = map;
        object::delete(id);
    }

    // ========== Iterator Functions ============

    struct Iter<Key> has drop {
        for: ID,
        keys: vector<Key>
    }

    public fun iter<Key: store + copy + drop, Value: store>(map: &Map<Key, Value>): Iter<Key> {
        Iter<Key> {
            for: object::uid_to_inner(&map.id),
            keys: *&map.index
        }
    }

    public fun next<Key: store + copy + drop, Value: store>(
        map: &Map<Key, Value>,
        iter: &mut Iter<Key>
    ): Option<Key> {
        assert!(object::uid_to_inner(&map.id) == iter.for, EITERABLE_MISMATCH);

        let i = 0;
        let length = vector::length(&iter.keys);

        while (i < length) {
            let key = vector::remove(&mut iter.keys, 0);
            if (exists_(map, copy key)) {
                return option::some(key)
            };
            i = i + 1;
        };

        option::none()
    }

    // ========== Internal Functions ============

    fun add_to_index<K: drop, V>(map: &mut Map<K, V>, key: K) {
        assert!(!vector::contains(&map.index, &key), EKEY_ALREADY_EXISTS);
        assert!(vector::length(&map.index) < MAX_LENGTH, EMAP_IS_FULL);

        vector::push_back(&mut map.index, key);
    }

    fun remove_from_index<K: drop, V>(map: &mut Map<K, V>, key: K) {
        let (exists, i) = vector::index_of(&map.index, &key);
        if (exists) {
            vector::remove(&mut map.index, i);
        }
    }

}

#[test_only]
module sui_utils::map_tests {
    use sui::test_scenario;
    use sui_utils::map::{Self, Map, Iter};
    use std::option;
    use std::vector;

    #[test]
    public fun iterator() {
        let scenario = test_scenario::begin(@55);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let new_map = map::empty<u64, u64>(ctx);
            map::add(&mut new_map, 0, 15);
            map::add(&mut new_map, 1, 99);
            map::add(&mut new_map, 2, 100074);

            let iter = map::iter(&new_map);
            loop {
                let next = map::next(&new_map, &mut iter);
                if (next == option::none()) { break };
                let _value = map::borrow_mut(&mut new_map, option::destroy_some(next));
            };

            map::delete(new_map);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun iterate_with_index() {
        let scenario = test_scenario::begin(@55);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let new_map = map::empty<u64, u64>(ctx);
            map::add(&mut new_map, 0, 15);
            map::add(&mut new_map, 1, 99);
            map::add(&mut new_map, 2, 100074);

            let index = map::into_keys(&new_map);
            let i = 0;
            while (i < vector::length(&index)) {
                let next = vector::borrow(&index, i);
                let _value = map::borrow_mut(&mut new_map, *next);
                i = i + 1;
            };

            map::delete(new_map);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun iterate_recursively() {
        let scenario = test_scenario::begin(@55);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let new_map = map::empty<u64, u64>(ctx);
            map::add(&mut new_map, 0, 15);
            map::add(&mut new_map, 1, 99);
            map::add(&mut new_map, 2, 100074);

            recursive(&new_map, &mut map::iter(&new_map));

            map::delete(new_map);
        };
        test_scenario::end(scenario);
    }

    public fun recursive<Key: store + copy + drop, Value: store>(map: &Map<Key, Value>, iter: &mut Iter<Key>) {
        let next = map::next(map, iter);
        if (next == option::none()) { 
            return
        };
        let _value = map::borrow(map, option::destroy_some(next));

        recursive(map, iter);
    }
}