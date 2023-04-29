// This module takes vectors of bytes and deserializes them into primitive types. It's very similar to sui::bcs, but
// without the BCS-encoding. I.e., an Option<u16> is simply encoded as none: [], some: [u8, u8], and strings
// are simply stored as their raw bytes, without any prefix length encoding. We still use prefix-encoding
// for vector<vector<u8>>, vector<String>, and VecMap, i.e.
// [ ULEB128 bytes for length of item1, item1 bytes, ... ]
// We don't add a ULEB128 length prefix for the total number of items, just the length of each individual item

module sui_utils::deserialize {
    use std::string::{Self, String};
    use std::vector;

    use sui::address;
    use sui::object::{Self, ID};
    use sui::vec_map::{Self, VecMap};
    use sui::url::{Self, Url};

    use sui_utils::bcs2;
    use sui_utils::vector2;

    const SUI_ADDRESS_LENGTH: u64 = 32;

    // Error constants
    const EINCORRECT_DATA_SIZE: u64 = 0;
    const ENOT_BOOLEAN: u64 = 1;

    public fun address_(bytes: &vector<u8>, start: u64): (address, u64) {
        (address::from_bytes(vector2::slice(bytes, start, start + SUI_ADDRESS_LENGTH)), start + SUI_ADDRESS_LENGTH)
    }

    public fun bool_(bytes: &vector<u8>, start: u64): (bool, u64) {
        let value = *vector::borrow(bytes, start);
        if (value == 0) {
            (false, start + 1)
        } else if (value == 1) {
            (true, start + 1)
        } else {
            abort ENOT_BOOLEAN
        }
    }

    public fun id_(bytes: &vector<u8>, start: u64): (ID, u64) {
        (object::id_from_bytes(vector2::slice(bytes, start, start + SUI_ADDRESS_LENGTH)), start + SUI_ADDRESS_LENGTH)
    }

    public fun string_(bytes: &vector<u8>, start: u64): (String, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let string_bytes = vector2::slice(bytes, start, start + len);

        (string::utf8(string_bytes), start + len)
    }

    public fun url_(bytes: &vector<u8>, start: u64): (Url, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let url_bytes = vector2::slice(bytes, start, start + len);

        (url::new_unsafe_from_bytes(url_bytes), start + len)
    }

    public fun u16_(bytes: &vector<u8>, start: u64): (u16, u64) {
        let (value, i) = (0u16, 0u8);
        while (i < 2) {
            let byte = (*vector::borrow(bytes, start + (i as u64)) as u16);
            value = value + (byte << (i * 8u8));
            i = i + 1;
        };

        (value, start + 2)
    }

    public fun u32_(bytes: &vector<u8>, start: u64): (u32, u64) {
        let (value, i) = (0u32, 0u8);
        while (i < 4) {
            let byte = (*vector::borrow(bytes, start + (i as u64)) as u32);
            value = value + (byte << (i * 8u8));
            i = i + 1;
        };

        (value, start + 4)
    }

    public fun u64_(bytes: &vector<u8>, start: u64): (u64, u64) {
        let (value, i) = (0u64, 0u8);
        while (i < 8) {
            let byte = (*vector::borrow(bytes, start + (i as u64)) as u64);
            value = value + (byte << (i * 8u8));
            i = i + 1;
        };

        (value, start + 8)
    }

    public fun u128_(bytes: &vector<u8>, start: u64): (u128, u64) {
        let (value, i) = (0u128, 0u8);
        while (i < 16) {
            let byte = (*vector::borrow(bytes, start + (i as u64)) as u128);
            value = value + (byte << (i * 8u8));
            i = i + 1;
        };

        (value, start + 16)
    }

    public fun u256_(bytes: &vector<u8>, start: u64): (u256, u64) {
        let (value, i) = (0u256, 0);
        while (i < 32) {
            let byte = (*vector::borrow(bytes, start + i) as u256);
            value = value + (byte << ((i * 8) as u8));
            i = i + 1;
        };

        (value, start + 32)
    }

    public fun vec_address(bytes: &vector<u8>, start: u64): (vector<address>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (i, result) = (0, vector::empty<address>());
        while (i < len) {
            let (value, _) = address_(bytes, start + i * SUI_ADDRESS_LENGTH);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len * SUI_ADDRESS_LENGTH)
    }

    public fun vec_bool(bytes: &vector<u8>, start: u64): (vector<bool>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (i, result) = (0, vector::empty<bool>());
        while (i < len) {
            let (value, _) = bool_(bytes, start + i);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len)
    }

    public fun vec_id(bytes: &vector<u8>, start: u64): (vector<ID>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (i, result) = (0, vector::empty<ID>());
        while (i < len) {
            let (value, _) = id_(bytes, start + i * SUI_ADDRESS_LENGTH);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len * SUI_ADDRESS_LENGTH)
    }

    // Kind of silly we need this lol. All we do is remove the length prefix.
    public fun vec_u8(bytes: &vector<u8>, start: u64): (vector<u8>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        (vector2::slice(bytes, start, start + len), start + len)
    }

    public fun vec_u16(bytes: &vector<u8>, start: u64): (vector<u16>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<u16>(), 0);
        while (i < len) {
            let (value, _) = u16_(bytes, start + i * 2);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len * 2)
    }

    public fun vec_u32(bytes: &vector<u8>, start: u64): (vector<u32>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<u32>(), 0);
        while (i < len) {
            let (value, _) = u32_(bytes, start + i * 4);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len * 4)
    }

    public fun vec_u64(bytes: &vector<u8>, start: u64): (vector<u64>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<u64>(), 0);
        while (i < len) {
            let (value, _) = u64_(bytes, start + i * 8);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len * 8)
    }

    public fun vec_u128(bytes: &vector<u8>, start: u64): (vector<u128>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<u128>(), 0);
        while (i < len) {
            let (value, _) = u128_(bytes, start + i * 16);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len * 16)
    }

    public fun vec_u256(bytes: &vector<u8>, start: u64): (vector<u256>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<u256>(), 0);
        while (i < len) {
            let (value, _) = u256_(bytes, start + i * 32);
            vector::push_back(&mut result, value);
            i = i + 1;
        };

        (result, start + len * 32)
    }

    // Turns [ 2, 2, 0, 0, 3, 0, 0, 0 ] into [ [ 0, 0 ], [ 0, 0, 0 ] ]
    public fun vec_vec_u8(bytes: &vector<u8>, start: u64): (vector<vector<u8>>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<vector<u8>>(), 0);
        while (i < len) {
            let (value, new_start) = vec_u8(bytes, start);
            vector::push_back(&mut result, value);
            start = new_start;
            i = i + 1;
        };

        (result, start)
    }

    // Turns [ 2, 2, 72, 105, 3, 89, 111, 117 ] into [ Hi, You ]
    public fun vec_string(bytes: &vector<u8>, start: u64): (vector<String>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<String>(), 0);
        while (i < len) {
            let (value, new_start) = string_(bytes, start);
            vector::push_back(&mut result, value);
            start = new_start;
            i = i + 1;
        };

        (result, start)
    }

    public fun vec_url(bytes: &vector<u8>, start: u64): (vector<Url>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<Url>(), 0);
        while (i < len) {
            let (value, new_start) = url_(bytes, start);
            vector::push_back(&mut result, value);
            start = new_start;
            i = i + 1;
        };

        (result, start)
    }

    // Turns [ 2, 3, 75, 101, 121, 5, 86, 97, 108, 117, 101 ] into VecMap { contents: [ Entry { k: Key, v: Value } ] }
    public fun vec_map_string_string(bytes: &vector<u8>, start: u64): (VecMap<String, String>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vec_map::empty<String,String>(), 0);
        while (i < len) {
            let (key, new_start) = string_(bytes, start);
            let (value, new_start) = string_(bytes, new_start);
            vec_map::insert(&mut result, key, value);
            start = new_start;
            i = i + 1;
        };

        (result, start)
    }

    public fun vec_vec_map_string_string(bytes: &vector<u8>, start: u64): (vector<VecMap<String, String>>, u64) {
        let (len, start) = bcs2::uleb128_length(bytes, start);
        let (result, i) = (vector::empty<VecMap<String, String>>(), 0);
        while (i < len) {
            let (value, new_start) = vec_map_string_string(bytes, start);
            vector::push_back(&mut result, value);
            start = new_start;
            i = i + 1;
        };

        (result, start)
    }
}

#[test_only]
module sui_utils::test_deserialize {
    use std::string::{Self, String};
    use std::vector;
    use sui_utils::bcs2;
    use sui_utils::deserialize;

    #[test]
    public fun test_u256() {
        let bytes = vector[254, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        let (num, _) = deserialize::u256_(&bytes, 0);
        assert!(num == 13054u256, 0);
    }

    #[test]
    public fun test_vec_string() {
        let test_strings = vector<String>[string::utf8(b"The last vector is japanese Wikipedia text"), string::utf8(b"Sui is amazing"), string::utf8(b"foobar bruh"), string::utf8(vector<u8>[227,131,135,227,130,163,227,131,188,227,131,136,227,131,170,227,131,146,227,131,187,227,131,150,227,130,175,227,130,185,227,131,134,227,131,149,227,131,188,227,131,135,239,188,136,227,131,135,227,130,163,227,131,188,227,131,134,227,131,170,227,131,146,227,131,187,227,131,150,227,130,175,227,130,185,227,131,134,227,131,149,227,131,188,227,131,135,227,128,129,227,131,137,227,130,164,227,131,132,232,170,158,058,032,068,105,101,116,101,114,105,099,104,032,040,068,105,101,116,114,105,099,104,041,032,066,117,120,116,101,104,117,100,101,032,091,203,136,100,105,203,144,116,201,153,202,129,201,170,195,167,032,098,202,138,107,115,116,201,153,203,136,104,117,203,144,100,201,153,093,044,032,227,131,135,227,131,179,227,131,158,227,131,188,227,130,175,232,170,158,058,032,068,105,100,101,114,105,107,032,040,068,105,100,101,114,105,099,104,041,032,066,117,120,116,101,104,117,100,101,032,091,203,136,100,105,195,176,201,153,202,129,201,170,107,032,098,117,107,115,100,201,153,203,136,104,117,203,144,195,176,201,153,093,044,032,049,054,051,055,229,185,180,233,160,131,032,045,032,049,055,048,055,229,185,180,053,230,156,136,057,230,151,165,239,188,137,091,230,179,168,032,049,093,227,129,175,227,128,129,049,055,228,184,150,231,180,128,227,129,174,229,140,151,227,131,137,227,130,164,227,131,132,227,129,138,227,130,136,227,129,179,227,131,144,227,131,171,227,131,136,230,181,183,230,178,191,229,178,184,229,156,176,229,159,159,227,128,129,227,131,151,227,131,173,227,130,164,227,130,187,227,131,179,227,130,146,228,187,163,232,161,168,227,129,153,227,130,139,228,189,156,230,155,178,229,174,182,227,131,187,227,130,170,227,131,171,227,130,172,227,131,139,227,130,185,227,131,136,227,129,167,227,129,130,227,130,139,227,128,130,229,163,176,230,165,189,228,189,156,229,147,129,227,129,171,227,129,138,227,129,132,227,129,166,227,129,175,227,128,129,227,131,144,227,131,173,227,131,131,227,130,175,230,156,159,227,131,137,227,130,164,227,131,132,227,129,174,230,149,153,228,188,154,227,130,171,227,131,179,227,130,191,227,131,188,227,130,191,227,129,174,229,189,162,230,136,144,227,129,171,232,178,162,231,140,174,227,129,153,227,130,139,228,184,128,230,150,185,227,128,129,227,130,170,227,131,171,227,130,172,227,131,179,233,159,179,230,165,189,227,129,171,227,129,138,227,129,132,227,129,166,227,129,175,227,128,129,227,131,164,227,131,179,227,131,187,227,131,148,227,131,188,227,131,134,227,131,171,227,130,185,227,130,190,227,131,188,227,131,179,227,131,187,227,130,185,227,130,166,227,130,167,227,131,188,227,131,170,227,131,179,227,130,175,227,129,171,231,171,175,227,130,146,231,153,186,227,129,153,227,130,139,229,140,151,227,131,137,227,130,164,227,131,132,227,131,187,227,130,170,227,131,171,227,130,172,227,131,179,230,165,189,230,180,190,227,129,174,230,156,128,229,164,167,227,129,174,229,183,168,229,140,160,227,129,167,227,129,130,227,130,138,227,128,129,227,129,157,227,129,174,229,141,179,232,136,136,231,154,132,227,131,187,228,184,187,230,131,133,231,154,132,227,129,170,228,189,156,233,162,168,227,129,175,227,130,185,227,131,134,227,130,163,227,131,171,227,130,185,227,131,187,227,131,149,227,130,161,227,131,179,227,130,191,227,130,185,227,131,134,227,130,163,227,130,175,227,130,185,239,188,136,227,131,137,227,130,164,227,131,132,232,170,158,231,137,136,227,128,129,232,139,177,232,170,158,231,137,136,239,188,137,239,188,136,229,185,187,230,131,179,230,167,152,229,188,143,239,188,137,227,129,174,229,133,184,229,158,139,227,129,168,227,129,149,227,130,140,227,129,166,227,129,132,227,130,139,227,128,130])];

        let i = 0;
        let bytes = vector<u8>[];
        vector::append(&mut bytes, bcs2::u64_into_uleb128(vector::length(&test_strings)));
        while (i < vector::length(&test_strings)) {
            let string_bytes = *string::bytes(vector::borrow(&test_strings, i));
            let uleb_len = bcs2::u64_into_uleb128(vector::length(&string_bytes));
            vector::append(&mut bytes, uleb_len);
            vector::append(&mut bytes, string_bytes);
            i = i + 1;
        };

        let (decoded_strings, _) = deserialize::vec_string(&bytes, 0);

        let i = 0;
        while (i < vector::length(&test_strings)) {
            assert!(*vector::borrow(&decoded_strings, i) == *vector::borrow(&test_strings, i), 0);
            // debug::print(vector::borrow(&decoded_strings, i));
            i = i + 1;
        };
    }
}