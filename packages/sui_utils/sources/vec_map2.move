module sui_utils::vec_map2 {
    use std::string::{String, utf8};
    use std::vector;
    use sui::vec_map::{Self, VecMap};

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

    public fun set<K: copy + drop, V>(self: &mut VecMap<K, V>, key: K, value: V): Option<V> {
        let old_value_maybe = if (vec_map::contains(self, &key)) {
            let (_, old_value) = vec_map::remove(self, &key);
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

        if (option::is_some(index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, value) = vec_map::get_entry_by_idx(self, index);
            option::some(value)
        } else {
            option::none()
        }
    }

    public fun remove_maybe<K: copy + drop, V: copy>(self: &mut VecMap<K, V>, key: K): Option<V> {
        let index_maybe = vec_map::get_idx_opt(self, &key);

        if (option::is_some(index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, value) = vec_map::remove_entry_by_idx(self, index);
            option::some(value)
        } else {
            option::none()
        }
    }
}