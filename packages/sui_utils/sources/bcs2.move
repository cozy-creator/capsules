// These functions should be added to sui::bcs

// sui::bcs does not expose any method for modifying the BCS bytes directly, i.e., getting a mutable reference
// to the underlying bytes. As such, we have to destructure the BCS object every time we want to implement custom
// peel functions. That's why in most of the functions below we pass the bcs by value, rather than by mut ref.
// At the end of the function we pack the bytes back into BCS and return the remaining bytes as a BCS struct,
// for continued operation upon it.
// Once this is integrated into the official sui::bcs module, this will be a lot simpler, since bcs can operate
// on its own bytes directly.

// TO ADD:
// peel_id, peel_u16, peel_u32, peel_ascii_string, peel_utf8_string
// Also vector and option versions of all of these
// https://github.com/MystenLabs/sui/issues/7231

module sui_utils::bcs2 {
    use std::ascii;
    use std::string;
    use std::vector;
    use sui::bcs::{Self, BCS};
    use sui::object::{Self, ID};
    use sui::vec_map::{Self, VecMap};
    use sui_utils::vector2;

    public fun peel_ascii(bcs: BCS): (ascii::String, BCS) {
        let len = bcs::peel_vec_length(&mut bcs);
        let bytes = bcs::into_remainder_bytes(bcs);
        let ascii_bytes = vector2::slice_mut(&mut bytes, 0, len);

        (ascii::string(ascii_bytes), bcs::new(bytes))
    }

    public fun peel_utf8(bcs: BCS): (string::String, BCS) {
        let len = bcs::peel_vec_length(&mut bcs);
        let bytes = bcs::into_remainder_bytes(bcs);
        let utf8_bytes = vector2::slice_mut(&mut bytes, 0, len);

        (string::utf8(utf8_bytes), bcs::new(bytes))
    }

    // Because addresses are of fixed size (20 bytes), bcs does not prepend a length before each address
    public fun peel_vec_id(bcs: &mut BCS): vector<ID> {
        let (len, i, res) = (bcs::peel_vec_length(bcs), 0, vector[]);
        while (i < len) {
            let id = object::id_from_address(bcs::peel_address(bcs));
            vector::push_back(&mut res, id);
            i = i + 1;
        };
        res
    }

    public fun peel_vec_ascii(bcs: BCS): (vector<ascii::String>, BCS) {
        let (num_strings, i, res) = (bcs::peel_vec_length(&mut bcs), 0, vector[]);
        while (i < num_strings) {
            let (string, bcs_remainder) = peel_ascii(bcs);
            vector::push_back(&mut res, string);
            bcs = bcs_remainder;
            i = i + 1;
        };

        (res, bcs)
    }

    // Unfortunately the above function had to be copy-pasted
    public fun peel_vec_utf8(bcs: BCS): (vector<string::String>, BCS) {
        let (num_strings, i, res) = (bcs::peel_vec_length(&mut bcs), 0, vector[]);
        while (i < num_strings) {
            let (string, bcs_remainder) = peel_utf8(bcs);
            vector::push_back(&mut res, string);
            bcs = bcs_remainder;
            i = i + 1;
        };
        (res, bcs)
    }

    // Serialization of Vec_Map looks like:
    // [total-number of item-pairs], written in ULEB format
    // [length of item-1 in pair-1], written in ULEB format
    // [bytes of item-1 in pair-1]
    // [length of item-2 in pair-1], written in ULEB format
    // ...
    public fun peel_vec_map_utf8(bcs: BCS): (VecMap<string::String, string::String>, BCS) {
        let (num_pairs, i, res) = (bcs::peel_vec_length(&mut bcs), 0, vec_map::empty());
        while (i < num_pairs) {
            let (str1, bcs_remainder) = peel_utf8(bcs);
            let (str2, bcs_remainder) = peel_utf8(bcs_remainder);
            bcs = bcs_remainder;
            vec_map::insert(&mut res, str1, str2);
            i = i + 1;
        };

        (res, bcs)
    }
}