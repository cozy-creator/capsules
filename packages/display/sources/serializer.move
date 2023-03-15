// ============ (de)serializes objects ============ 

// Two of these are private functions only useable within Display so that the schema cannot be bypassed
// Aborts if the type is incorrect because the bcs deserialization will fail
//
// Supported types: address, bool, objectID, u8, u16, u32, u64, u128, u256, String (utf8),
// VecMap<String, String>, Url, and vectors of these types, as well as vector<vector<u8>>

module display::serializer {
    use std::string::String;
    use std::option;
    use std::vector;

    use sui::bcs::{Self};
    use sui::dynamic_field;
    use sui::object::{UID, ID};
    use sui::vec_map::VecMap;

    use metadata::schema::{Self, Schema};

    use sui_utils::encode;
    use sui_utils::deserialize;
    use sui_utils::dynamic_field2;

    use display::display::Key;

    friend display::display;

    // Error Enums
    const EUNRECOGNIZED_TYPE: u64 = 0;

    public(friend) fun set_field(
        uid: &mut UID,
        key: Key,
        type_string: String,
        optional: bool,
        value: vector<u8>,
        overwrite: bool
    ) {
        let type = *string::bytes(&type_string);

        // Empty byte-arrays are treated as undefined
        if (vector::length(&value) == 0) {
            if (optional) {
                drop_field(uid, key, type_string);
                return
            // These types are allowed to be empty arrays and still count as being "defined"
            } else if ( type == b"String" || type == b"VecMap" || encode::is_vector(type_string) ) {
                value = if (optional) { vector[1u8, 0u8] } else { vector[0u8] };
            } else { abort EKEY_IS_NOT_OPTIONAL };
        };

        // Field is optional and undefined
        if (optional && *vector::borrow(&value, 0) == 0u8) {
            drop_field(uid, key, type_string);
            return
        };

        // Index to start deserializing
        let i = if (optional) { 1 } else { 0 };

        if (type == b"address") {
            let (addr, _) = deserialize::address_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, addr);
        } 
        else if (type == b"bool") {
            let (boolean, _) = deserialize::bool_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, boolean);
        } 
        else if (type == b"id") {
            let (object_id, _) = deserialize::id_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, object_id);
        } 
        else if (type == b"u8") {
            let integer = vector::borrow(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, *integer);
        }
        else if (type == b"u16") {
            let (integer, _) = deserialize::u16_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u32") {
            let (integer, _) = deserialize::u32_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u64") {
            let (integer, _) = deserialize::u64_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u128") {
            let (integer, _) = deserialize::u128_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u256") {
            let (integer, _) = deserialize::u256_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"String") {
            let (string, _) = deserialize::string_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, string);
        }
        else if (type == b"Url") {
            let (url, _) = deserialize::url_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, url);
        } 
        else if (type == b"vector<address>") {
            let (vec, _) = deserialize::vec_address(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<bool>") {
            let (vec, _) = deserialize::vec_bool(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<id>") {
            let (vec, _) = deserialize::vec_id(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u8>") {
            let (vec, _) = deserialize::vec_u8(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u16>") {
            let (vec, _) = deserialize::vec_u16(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u32>") {
            let (vec, _) = deserialize::vec_u32(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u64>") {
            let (vec, _) = deserialize::vec_u64(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u128>") {
            let (vec, _) = deserialize::vec_u128(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u256>") {
            let (vec, _) = deserialize::vec_u256(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<vector<u8>>") {
            let (vec, _) = deserialize::vec_vec_u8(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<String>") {
            let (strings, _) = deserialize::vec_string(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, strings);
        }
        else if (type == b"vector<Url>") {
            let (urls, _) = deserialize::url_string(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, urls);
        }
        else if (type == b"VecMap") {
            let (vec_map, _) = deserialize::vec_map_string_string(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec_map);
        }
        else if (type == b"vector<VecMap>") {
            let (vec_maps, _) = deserialize::vec_vec_map_string_string(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec_maps);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // Unfortunately sui::dynamic_field does not have a general 'drop' function; the value of the type
    // being dropped MUST be known. This makes dropping droppable assets unecessarily complex, hence
    // this lengthy function in place of what should be one line of code. I know... believe me I've asked.
    public(friend) fun drop_field(uid: &mut UID, key: Key, type_string: String) {
        let type = *string::bytes(&type_string);

        if (type == b"address") {
            dynamic_field2::drop<Key, address>(uid, key);
        } 
        else if (type == b"bool") {
            dynamic_field2::drop<Key, bool>(uid, key);
        } 
        else if (type == b"id") {
            dynamic_field2::drop<Key, ID>(uid, key);
        } 
        else if (type == b"u8") {
            dynamic_field2::drop<Key, u8>(uid, key);
        } 
        else if (type == b"u64") {
            dynamic_field2::drop<Key, u64>(uid, key);
        } 
        else if (type == b"u128") {
            dynamic_field2::drop<Key, u128>(uid, key);
        } 
        else if (type == b"String") {
            dynamic_field2::drop<Key, String>(uid, key);
        }
        else if (type == b"Url") {
            dynamic_field2::drop<Key, Url>(uid, key);
        } 
        else if (type == b"vector<address>") {
            dynamic_field2::drop<Key, vector<address>>(uid, key);
        }
        else if (type == b"vector<bool>") {
            dynamic_field2::drop<Key, vector<bool>>(uid, key);
        }
        else if (type == b"vector<id>") {
            dynamic_field2::drop<Key, vector<ID>>(uid, key);
        }
        else if (type == b"vector<u8>") {
            dynamic_field2::drop<Key, vector<u8>>(uid, key);
        }
        else if (type == b"vector<u64>") {
            dynamic_field2::drop<Key, vector<u64>>(uid, key);
        }
        else if (type == b"vector<u128>") {
            dynamic_field2::drop<Key, vector<u128>>(uid, key);
        }
        else if (type == b"vector<String>") {
            dynamic_field2::drop<Key, vector<String>>(uid, key);
        }
        else if (type == b"vector<Url>") {
            dynamic_field2::drop<Key, vector<Url>>(uid, key);
        }
        else if (type == b"VecMap") {
            dynamic_field2::drop<Key, VecMap<String, String>>(uid, key);
        }
        else if (type == b"vector<VecMap>") {
            dynamic_field2::drop<Key, vector<VecMap<String, String>>>(uid, key);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // If we get dynamic_field::get_bcs_bytes we can simplify this down into 2 or 3 lines
    public fun get_bcs_bytes(uid: &UID, slot: String, type_string: String): vector<u8> {
        let key = Key { slot };
        assert!(dynamic_field::exists_(uid, key), EVALUE_UNDEFINED);

        let type = *string::bytes(&type_string);

        if (type == b"address") {
            let addr = dynamic_field::borrow<Key, address>(uid, key);
            bcs::to_bytes(addr)
        } 
        else if (type == b"bool") {
            let boolean = dynamic_field::borrow<Key, bool>(uid, key);
            bcs::to_bytes(boolean)
        } 
        else if (type == b"id") {
            let object_id = dynamic_field::borrow<Key, ID>(uid, key);
            bcs::to_bytes(object_id)
        } 
        else if (type == b"u8") {
            let int = dynamic_field::borrow<Key, u8>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"u64") {
            let int = dynamic_field::borrow<Key, u64>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"u128") {
            let int = dynamic_field::borrow<Key, u128>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"String") {
            let string = dynamic_field::borrow<Key, String>(uid, key);
            bcs::to_bytes(string)
        }
        else if (type == b"Url") {
            let url = dynamic_field::borrow<Key, Url>(uid, key);
            bcs::to_bytes(url)
        } 
        else if (type == b"vector<address>") {
            let vec = dynamic_field::borrow<Key, vector<address>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<bool>") {
            let vec = dynamic_field::borrow<Key, vector<bool>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<id>") {
            let vec = dynamic_field::borrow<Key, vector<ID>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u8>") {
            let vec = dynamic_field::borrow<Key, vector<u8>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u64>") {
            let vec = dynamic_field::borrow<Key, vector<u64>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u128>") {
            let vec = dynamic_field::borrow<Key, vector<u128>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<String>") {
            let vec = dynamic_field::borrow<Key, vector<String>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<Url>") {
            let vec = dynamic_field::borrow<Key, vector<Url>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"VecMap") {
            let vec_map = dynamic_field::borrow<Key, VecMap<String, String>>(uid, key);
            bcs::to_bytes(vec_map)
        }
        else if (type == b"vector<VecMap>") {
            let vec_vec_map = dynamic_field::borrow<Key, vector<VecMap<String, String>>>(uid, key);
            bcs::to_bytes(vec_vec_map)
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }
}