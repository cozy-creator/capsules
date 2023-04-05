// Similar to vec_set in 0x2::sui, but more performant and far more useful

module sui_utils::vec_set2 {
    use std::option::{Self, Option};
    use std::vector;

    /// A set data structure backed by a vector. The set is guaranteed not to contain duplicate keys.
    /// All operations are O(N) in the size of the set--the intention of this data structure is only to provide
    /// the convenience of programming against a set API.
    /// Sets that need sorted iteration rather than insertion order iteration should be handwritten.
    struct VecSet<K: copy + drop> has store, copy, drop {
        contents: vector<K>,
    }

    /// Create an empty `VecSet`
    public fun empty<K: copy + drop>(): VecSet<K> {
        VecSet { contents: vector::empty() }
    }

    /// Create a singleton `VecSet` that only contains one element.
    public fun create<K: copy + drop>(keys: vector<K>): VecSet<K> {
        VecSet { contents: keys }
    }

    /// Insert a `key` into self. Does nothing if the key is already present
    public fun add<K: copy + drop>(self: &mut VecSet<K>, key: K) {
        if (option::is_none(&get_index(self, key))) {
            vector::push_back(&mut self.contents, key);
        };
    }

    /// Remove the entry `key` from self. Does nothing if the key is not present
    public fun remove<K: copy + drop>(self: &mut VecSet<K>, key: K) {
        let index_maybe = get_index(self, key);
        if (option::is_some(&index_maybe)) {
            vector::remove(&mut self.contents, option::destroy_some(index_maybe));
        };
    }

    /// Unpack `self` into vectors of keys.
    /// The output keys are stored in insertion order, *not* sorted.
    public fun into_keys<K: copy + drop>(self: &VecSet<K>): vector<K> {
        self.contents
    }

    /// Find the index of `key` in `self`. Return `None` if `key` is not in `self`.
    /// Note that keys are stored in insertion order, *not* sorted.
    public fun get_index<K: copy + drop>(self: &VecSet<K>, key: K): Option<u64> {
        let i = 0;
        while (i < size(self)) {
            if (vector::borrow(&self.contents, i) == &key) {
                return option::some(i)
            };
            i = i + 1;
        };

        option::none()
    }

    // ==== Helper Functions ====

    /// Return the number of entries in `self`
    public fun size<K: copy + drop>(self: &VecSet<K>): u64 {
        vector::length(&self.contents)
    }

    /// Return true if `self` contains an entry for `key`, false otherwise
    public fun contains<K: copy + drop>(self: &VecSet<K>, key: K): bool {
        option::is_some(&get_index(self, key))
    }

    /// Return true if `self` has 0 elements, false otherwise
    public fun is_empty<K: copy + drop>(self: &VecSet<K>): bool {
        size(self) == 0
    }
}