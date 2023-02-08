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

    // Error constants
    const ENO_ULEB_LENGTH_FOUND: u64 = 0;
    const EINCORRECTLY_SERIALIZED_VEC_MAP: u64 = 1;

    public fun peel_id(bcs: &mut BCS): ID {
        let addr = bcs::peel_address(bcs);
        object::id_from_address(addr)
    }

    public fun peel_ascii(bcs: &mut BCS): ascii::String {
        let ascii_bytes = bcs::peel_vec_u8(bcs);
        ascii::string(ascii_bytes)
    }

    public fun peel_utf8(bcs: &mut BCS): string::String {
        let utf8_bytes = bcs::peel_vec_u8(bcs);
        string::utf8(utf8_bytes)
    }

    public fun peel_option_byte(bcs: &mut BCS): bool {
        bcs::peel_bool(bcs)
    }

    // ======== Vector Peels ======== 

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

    public fun peel_vec_ascii(bcs: &mut BCS): vector<ascii::String> {
        let ascii_strings = bcs::peel_vec_vec_u8(bcs);
        let (i, res) = (0, vector::empty());
        while (i < vector::length(&ascii_strings)) {
            let str = ascii::string(*vector::borrow(&ascii_strings, i));
            vector::push_back(&mut res, str);
            i = i + 1;
        };

        res
    }

    public fun peel_vec_utf8(bcs: &mut BCS): vector<string::String> {
        let utf8_strings = bcs::peel_vec_vec_u8(bcs);
        let (i, res) = (0, vector::empty());
        while (i < vector::length(&utf8_strings)) {
            let str = string::utf8(*vector::borrow(&utf8_strings, i));
            vector::push_back(&mut res, str);
            i = i + 1;
        };

        res
    }

    // Serialization of Vec_Map looks like:
    // [total-number of item-pairs], written in ULEB format
    // [length of item-1 in pair-1], written in ULEB format
    // [bytes of item-1 in pair-1]
    // [length of item-2 in pair-1], written in ULEB format
    // ...
    public fun peel_vec_map_utf8(bcs: &mut BCS): VecMap<string::String, string::String> {
        let utf8_strings = bcs::peel_vec_vec_u8(bcs);
        assert!(vector::length(&utf8_strings) % 2 == 0, EINCORRECTLY_SERIALIZED_VEC_MAP);

        let (i, res) = (0, vec_map::empty());
        while (i < vector::length(&utf8_strings)) {
            let str1 = string::utf8(*vector::borrow(&utf8_strings, i));
            let str2 = string::utf8(*vector::borrow(&utf8_strings, i + 1));
            vec_map::insert(&mut res, str1, str2);
            i = i + 2;
        };

        res
    }

    // Encodes a u64 as a sequence of ULEB128 bytes
    public fun u64_into_uleb128(num: u64): vector<u8> {
        let uleb = vector::empty<u8>();
        while (true) {
            let byte = ((num & 0x7f) as u8);
            num = num >> 7;
            if (num == 0) {
                vector::push_back(&mut uleb, byte);
                break
            } else {
                vector::push_back(&mut uleb, byte | 0x80);
            };
        };

        uleb
    }

    // Reads the ULEB128 length from the byte-array at the specified index, returns the number along with the index where it
    // left off
    public fun uleb128_length(data: &vector<u8>, start: u64): (u64, u64) {
        let (total, shift, len) = (0u64, 0, 0);
        while (true) {
            assert!(len <= 4, ENO_ULEB_LENGTH_FOUND);

            let byte = (*vector::borrow(data, start + len) as u64);
            total = total | ((byte & 0x7f) << shift);

            if ((byte & 0x80) == 0) {
                break
            };

            shift = shift + 7;
            len = len + 1;
        };

        (total, start + len + 1)
    }
}

#[test_only]
module sui_utils::bcs2_tests {
    use std::vector;
    use sui_utils::bcs2;

    #[test]
    public fun test_uleb128() {
        let test_numbers = vector[77, 0, 17, 128, 240, 256, 900, 17001, 614599, 1270999];
        let i = 0;
        while (i < vector::length(&test_numbers)) {
            let x = *vector::borrow(&test_numbers, i);
            let (len, _) = bcs2::uleb128_length(&bcs2::u64_into_uleb128(x), 0);
            assert!(len == x, 0);
            i = i + 1;
        }
    }
}