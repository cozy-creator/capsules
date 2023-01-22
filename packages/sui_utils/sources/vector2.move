module sui_utils::vector2 {
    use std::vector;
    
    const EINVALID_SLICE: u64 = 0;

    // Takes a slice of a vector from the start-index up to, but not including, the end-index.
    // Does not modify the original vector
    public fun slice<T: store + copy>(vec: &vector<T>, start: u64, end: u64): vector<T> {
        assert!(end >= start, EINVALID_SLICE);

        let (i, slice) = (start, vector::empty<T>());
        while (i < end) {
            vector::push_back(&mut slice, *vector::borrow(vec, i));
            i = i + 1;
        };

        slice
    }

    // O(n) operation. Preserves order of vector. Takes the indicies [start, end), that is, the end-index
    // is not included.
    public fun slice_mut<T: store>(vec: &mut vector<T>, start: u64, end: u64): vector<T> {
        assert!(end >= start, EINVALID_SLICE);

        let slice_length = end - start;
        let (i, slice) = (0, vector::empty<T>());
        while (i < slice_length) {
            vector::push_back(&mut slice, vector::swap_remove(vec, start + i));
            i = i + 1;
        };

        // Now put the original vector back in order
        let last_index = vector::length(vec) - 1;
        while (i < (last_index - i - slice_length)) {
            vector::swap(vec, start + i, last_index - i - slice_length);
            i = i + 1;
        };

        let (i, len, remainder) = (0, vector::length(vec), vector::empty<T>());
        while (i < (len - start)) {
            vector::push_back(&mut remainder, vector::pop_back(vec));
            i = i + 1;
        };
        vector::append(vec, remainder);

        slice
    }

    // Preserves order of vector
    public fun slice_mut2<T: store>(vec: &mut vector<T>, start: u64, end: u64): vector<T> {
        assert!(end >= start, EINVALID_SLICE);

        let (i, slice) = (0, vector::empty<T>());
        while (i < (end - start)) {
            vector::push_back(&mut slice, vector::remove(vec, start));
            i = i + 1;
        };

        slice
    }
}