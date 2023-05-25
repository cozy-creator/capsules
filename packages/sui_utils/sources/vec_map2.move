module sui_utils::vec_map2 {
    use std::option::{Self, Option};
    use std::vector;

    use sui::vec_map::{Self, VecMap};

    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::vector2;

    // Error enums
    const EVEC_LENGTH_MISMATCH: u64 = 0;
    const EVEC_NOT_EMPTY: u64 = 1;

    public fun new<K: copy, V>(key: K, value: V): VecMap<K, V> {
        let vec = vec_map::empty();
        vec_map::insert(&mut vec, key, value);
        vec
    }

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

    // Returns the old value (if one existed)
    public fun set<K: copy + drop, V>(self: &mut VecMap<K, V>, key: &K, value: V): Option<V> {
        let index_maybe = vec_map::get_idx_opt(self, key);
        let old_value_maybe = if (option::is_some(&index_maybe)) {
            let (_, old_value) = vec_map::remove_entry_by_idx(self, option::destroy_some(index_maybe));
            option::some(old_value)
        } else {
            option::none()
        };

        vec_map::insert(self, *key, value);

        old_value_maybe
    }

    public fun borrow_mut_fill<K: copy, V: drop>(
        self: &mut VecMap<K, V>,
        key: &K,
        default_value: V
    ): &mut V {
        let index_maybe = vec_map::get_idx_opt(self, key);
        if (!option::is_some(&index_maybe)) {
            vec_map::insert(self, *key, default_value);
        };

        vec_map::get_mut(self, key)
    }

    public fun get_with_default<K: copy + drop, V: copy + drop>(self: &VecMap<K, V>, key: &K, default: V): V {
        let index_maybe = vec_map::get_idx_opt(self, key);

        if (option::is_some(&index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, value) = vec_map::get_entry_by_idx(self, index);
            *value
        } else {
            default
        }
    }

    // More efficient than doing 'vec_map::contains' followed by 'vec_map::get', because that iterates through the
    // map twice, whereas this only iterates through it once
    public fun get_maybe<K: copy, V: copy>(self: &VecMap<K, V>, key: &K): Option<V> {
        let index_maybe = vec_map::get_idx_opt(self, key);

        if (option::is_some(&index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, value) = vec_map::get_entry_by_idx(self, index);
            option::some(*value)
        } else {
            option::none()
        }
    }

    public fun remove_maybe<K: copy + drop, V>(self: &mut VecMap<K, V>, key: &K): Option<V> {
        let index_maybe = vec_map::get_idx_opt(self, key);

        if (option::is_some(&index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, value) = vec_map::remove_entry_by_idx(self, index);
            option::some(value)
        } else {
            option::none()
        }
    }

    public fun insert_maybe<K: copy + drop, V: drop>(self: &mut VecMap<K, V>, key: K, value: V) {
        if (!vec_map::contains(self, &key)) { 
            vec_map::insert(self, key, value); 
        };
    }

    public fun merge<K: copy, V: copy + drop>(
        self: &mut VecMap<K, vector<V>>,
        other: &VecMap<K, vector<V>>
    ) {
        let i = 0;
        while (i < vec_map::size(other)) {
            let (key, value) = vec_map::get_entry_by_idx(other, i);
            let vec = borrow_mut_fill(self, key, vector[]);
            vector2::merge(vec, *value);
            i = i + 1;
        };
    }

    // The new value is merged into the vector stored at the specified key (duplicates are not added).
    public fun merge_value<K: copy + drop, V: copy + drop>(self: &mut VecMap<K, vector<V>>, key: &K, value: V) {
        let vec = borrow_mut_fill(self, key, vector[]);
        vector2::merge(vec, vector[value]);
    }

    public fun get_many<K: copy + drop, V: copy>(self: &VecMap<K, V>, keys: &vector<K>): vector<V> {
        let (i, result) = (0, vector::empty());
        while (i < vector::length(keys)) {
            let key = vector::borrow(keys, i);
            let value = *vec_map::get(self, key);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        result
    }

    // This does not alter the order of elements, but we could potentially make it more efficient
    // by using vector::swap_remove instead of vector::remove inside of vec_map::remove_entry_by_idx
    public fun remove_entries_with_value<K: copy + drop, V: drop>(self: &mut VecMap<K, V>, value: &V) {
        let i = 0;
        while (i < vec_map::size(self)) {
            let (_, val) = vec_map::get_entry_by_idx(self, i);
            if (val == value) { 
                vec_map::remove_entry_by_idx(self, i); 
            } else {
                i = i + 1;
            };
        };
    }

    // Speciality function created just for struct-tag matching. 
    public fun match_struct_tag_maybe<V: copy>(self: &VecMap<StructTag, V>, struct_tag: &StructTag): Option<V> {
        let i = 0;
        while (i < vec_map::size(self)) {
            let (key, value) = vec_map::get_entry_by_idx(self, i);

            if (struct_tag::match(struct_tag, key)) { 
                return option::some(*value)
            };
            i = i + 1;
        };

        return option::none()
    }
}