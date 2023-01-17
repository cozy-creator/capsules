// These functions should be added to sui::bcs

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
    use sui_utils::vector2;

    // To do: Check this; does bcs prepend a length to addresses, or is it just assumed that they are of length 20?
    public fun peel_vec_id(bcs: &mut BCS): vector<ID> {
        let (len, i, res) = (bcs::peel_vec_length(bcs), 0, vector[]);
        while (i < len) {
            let id = object::id_from_address(bcs::peel_address(bcs));
            vector::push_back(&mut res, id);
            i = i + 1;
        };
        res
    }

    // To do: check to see if bcs is prepending the length of strings; I believe it does
    // Returns any remaining BCS bytes. This setup is needed because there is no way to access a BCS'
    // underlying bytes without destroying it
    public fun peel_vec_ascii_string(bcs: BCS): (vector<ascii::String>, BCS) {
        let (num_strings, i, res) = (bcs::peel_vec_length(&mut bcs), 0, vector[]);
        while (i < num_strings) {
            let len = bcs::peel_vec_length(&mut bcs);
            // Note that we have to unpack the bcs struct here; there is no way to gain access
            // to the underlying bytes without doing so. When this is integrated into the sui::bcs
            // module itself, this will be much easier, and this function can take `&mut BCS` rather
            // than tkaing BCS by value.
            let bytes = bcs::into_remainder_bytes(bcs); // remove bytes from bcs wrapper
            let string_bytes = vector2::slice_mut(&mut bytes, 0, len);
            let string = ascii::string(string_bytes);
            vector::push_back(&mut res, string);
            bcs = bcs::new(bytes); // put bytes back into bcs wrapper for the next loop
            i = i + 1;
        };
        (res, bcs)
    }

    // Unfortunately the above function had to be copy-pasted
    public fun peel_vec_utf8_string(bcs: BCS): (vector<string::String>, BCS) {
        let (num_strings, i, res) = (bcs::peel_vec_length(&mut bcs), 0, vector[]);
        while (i < num_strings) {
            let len = bcs::peel_vec_length(&mut bcs);
            let bytes = bcs::into_remainder_bytes(bcs); // remove bytes from bcs wrapper
            let string_bytes = vector2::slice_mut(&mut bytes, 0, len);
            let string = string::utf8(string_bytes);
            vector::push_back(&mut res, string);
            bcs = bcs::new(bytes); // put bytes back into bcs wrapper for the next loop
            i = i + 1;
        };
        (res, bcs)
    }
}