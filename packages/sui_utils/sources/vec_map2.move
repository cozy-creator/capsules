module sui_utils::vec_map2 {
    use std::option::{Self, Option};
    use std::string::{String, utf8};
    use std::vector;

    use sui::vec_map::{Self, VecMap};

    // Error enums
    const EVEC_LENGTH_MISMATCH: u64 = 0;
    const EVEC_NOT_EMPTY: u64 = 1;

    public fun create<K: copy, V>(keys: vector<K>, values: vector<V>): VecMap<K, V> {
        assert!(vector::length(&keys) == vector::length(&values), EVEC_LENGTH_MISMATCH);

        vector::reverse(&mut keys);
        vector::reverse(&mut values);

        let result = vec_map::empty();
        while (vector::length(&values) > 0) {
            let key = vector::pop_back(&mut keys);
            let value = vector::pop_back(&mut values);
            vec_map::insert(&mut result, key, value);
        };

        vector::destroy_empty(keys);
        vector::destroy_empty(values);

        result
    }

    // This will fail if there is an odd number of entries in the first vector
    // It will also fail if the bytes are not utf8 strings
    public fun to_string_string_vec_map(bytes: &vector<vector<u8>>): VecMap<String, String> {
        let output = vec_map::empty<String, String>();
        let i = 0;

        while (i < vector::length(bytes)) {
            let key = utf8(*vector::borrow(bytes, i));
            let value = utf8(*vector::borrow(bytes, i + 1));

            vec_map::insert(&mut output, key, value);

            i = i + 2;
        };

        output
    }

    // Returns the old value (if one existed)
    public fun set<K: copy + drop, V>(self: &mut VecMap<K, V>, key: K, value: V): Option<V> {
        let index_maybe = vec_map::get_idx_opt(self, &key);
        let old_value_maybe = if (option::is_some(&index_maybe)) {
            let (_, old_value) = vec_map::remove_entry_by_idx(self, option::destroy_some(index_maybe));
            option::some(old_value)
        } else {
            option::none()
        };

        vec_map::insert(self, key, value);

        old_value_maybe
    }

    // More efficient than doing 'vec_map::contains' followed by 'vec_map::get', because that iterates through the
    // map twice, whereas this only iterates through it once
    public fun get_maybe<K: copy + drop, V: copy>(self: &VecMap<K, V>, key: K): Option<V> {
        let index_maybe = vec_map::get_idx_opt(self, &key);

        if (option::is_some(&index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, value) = vec_map::get_entry_by_idx(self, index);
            option::some(*value)
        } else {
            option::none()
        }
    }

    public fun remove_maybe<K: copy + drop, V: copy>(self: &mut VecMap<K, V>, key: K): Option<V> {
        let index_maybe = vec_map::get_idx_opt(self, &key);

        if (option::is_some(&index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, value) = vec_map::remove_entry_by_idx(self, index);
            option::some(value)
        } else {
            option::none()
        }
    }
}