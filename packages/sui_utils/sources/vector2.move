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

        let (i, slice, remainder, len) = (start, vector::empty<T>(), vector::empty<T>(), vector::length(vec));
        while (i < len) {
            if (i < end) {
                vector::push_back(&mut slice, vector::swap_remove(vec, i));
            } else {
                vector::push_back(&mut remainder, vector::swap_remove(vec, i));
            };
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