// ============ Sui's Data (de)serializer ============
// This deserializes and stores any supported data-type in a dynamic field. Use whatever custom key
// object you like!
// This also serializes any stored and supported data-types; just give us the key and type and we'll
// take care of the rest!

module attach::serializer {
    use std::string::{Self, String};
    use std::vector;

    use sui::bcs::{Self};
    use sui::dynamic_field;
    use sui::object::{UID, ID};
    use sui::vec_map::VecMap;
    use sui::url::Url;

    use sui_utils::encode;
    use sui_utils::deserialize;
    use sui_utils::dynamic_field2;

    // Error enums
    const EUNRECOGNIZED_TYPE: u64 = 0;
    
    // Aborts if `type_string` does not match `value` (the binary data) supplied, because the bcs
    // deserialization will fail
    public fun set_field<T: store + copy + drop>(
        uid: &mut UID,
        key: T,
        type: String,
        old_type: String, // Pass an empty string if the type is unchanged or if the field is new
        value: vector<u8>,
        overwrite: bool
    ) {
        // We're not supposed to overwrite, and the destination already has data, so we return
        if (!overwrite && dynamic_field::exists_(uid, key)) {
            return
        };

        if (!string::is_empty(&old_type) && old_type != type) {
            // Type is changing; drop the old field
            drop_field(uid, key, old_type);
        };

        // This is cheaper on gas; we don't have to construct a string every time we do a comparison
        // to a string literal. Instead we can just compare the string-bytes
        let type_bytes = *string::bytes(&type);

        // Empty byte-arrays are treated as undefined
        if (vector::length(&value) == 0) {
            // These types are allowed to be empty arrays and still count as being "defined"
            if (type_bytes == b"String" || type_bytes == b"VecMap" || encode::is_vector(type) ) {
                value = vector[0u8];
            } else { 
                drop_field(uid, key, type);
                return
            };
        };

        let i = 0;

        if (type_bytes == b"address") {
            let (addr, _) = deserialize::address_(&value, i);
            dynamic_field2::set(uid, key, addr);
        } 
        else if (type_bytes == b"bool") {
            let (boolean, _) = deserialize::bool_(&value, i);
            dynamic_field2::set(uid, key, boolean);
        } 
        else if (type_bytes == b"id") {
            let (object_id, _) = deserialize::id_(&value, i);
            dynamic_field2::set(uid, key, object_id);
        } 
        else if (type_bytes == b"u8") {
            let integer = vector::borrow(&value, i);
            dynamic_field2::set(uid, key, *integer);
        }
        else if (type_bytes == b"u16") {
            let (integer, _) = deserialize::u16_(&value, i);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u32") {
            let (integer, _) = deserialize::u32_(&value, i);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u64") {
            let (integer, _) = deserialize::u64_(&value, i);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u128") {
            let (integer, _) = deserialize::u128_(&value, i);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u256") {
            let (integer, _) = deserialize::u256_(&value, i);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"String") {
            let (string, _) = deserialize::string_(&value, i);
            dynamic_field2::set(uid, key, string);
        }
        else if (type_bytes == b"Url") {
            let (url, _) = deserialize::url_(&value, i);
            dynamic_field2::set(uid, key, url);
        } 
        else if (type_bytes == b"vector<address>") {
            let (vec, _) = deserialize::vec_address(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<bool>") {
            let (vec, _) = deserialize::vec_bool(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<id>") {
            let (vec, _) = deserialize::vec_id(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u8>") {
            let (vec, _) = deserialize::vec_u8(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u16>") {
            let (vec, _) = deserialize::vec_u16(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u32>") {
            let (vec, _) = deserialize::vec_u32(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u64>") {
            let (vec, _) = deserialize::vec_u64(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u128>") {
            let (vec, _) = deserialize::vec_u128(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u256>") {
            let (vec, _) = deserialize::vec_u256(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<vector<u8>>") {
            let (vec, _) = deserialize::vec_vec_u8(&value, i);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<String>") {
            let (strings, _) = deserialize::vec_string(&value, i);
            dynamic_field2::set(uid, key, strings);
        }
        else if (type_bytes == b"vector<Url>") {
            let (urls, _) = deserialize::vec_url(&value, i);
            dynamic_field2::set(uid, key, urls);
        }
        else if (type_bytes == b"VecMap") {
            let (vec_map, _) = deserialize::vec_map_string_string(&value, i);
            dynamic_field2::set(uid, key, vec_map);
        }
        else if (type_bytes == b"vector<VecMap>") {
            let (vec_maps, _) = deserialize::vec_vec_map_string_string(&value, i);
            dynamic_field2::set(uid, key, vec_maps);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // Same function-signature as above, but you pass in the actual value `V`, rather than just the bytes of `V`
    // to be deserialized
    public fun set_field_<K: store + copy + drop, V: store + drop>(
        uid: &mut UID,
        key: K,
        type: String,
        old_type: String,
        value: V,
        overwrite: bool
    ) {
        if (!overwrite && dynamic_field::exists_(uid, key)) {
            return
        };

        if (!string::is_empty(&old_type) && old_type != type) {
            // Type is changing; drop the old field
            drop_field(uid, key, old_type);
        };

        dynamic_field2::set(uid, key, value);
    }

    // If you know the types statically, as type-arguments, this is a lot easier.
    public fun duplicate<K: store + copy + drop, D: store + copy + drop>(
        source_uid: &UID,
        destination_uid: &mut UID,
        source_key: K,
        destination_key: D,
        source_type: String,
        old_destination_type: String,
        overwrite: bool
    ) {
        if (!overwrite && dynamic_field::exists_(destination_uid, destination_key)) {
            return
        };

        // There is no data at this location to copy; if overwrite == true then whatever is at the
        // destination field
        if (!dynamic_field::exists_(source_uid, source_key)) {
            if (overwrite && !string::is_empty(&old_destination_type)) { 
                drop_field(destination_uid, destination_key, old_destination_type) 
            };
            return
        };

        // Type is changing; drop the old field
        if (!string::is_empty(&old_destination_type) && old_destination_type != source_type) {
            drop_field(destination_uid, destination_key, old_destination_type); 
        };

        let type_bytes = *string::bytes(&source_type);

        if (type_bytes == b"address") {
            let addr = *dynamic_field::borrow<K, address>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, addr);
        } 
        else if (type_bytes == b"bool") {
            let boolean = *dynamic_field::borrow<K, bool>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, boolean);
        } 
        else if (type_bytes == b"id") {
            let object_id = *dynamic_field::borrow<K, ID>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, object_id);
        } 
        else if (type_bytes == b"u8") {
            let integer = *dynamic_field::borrow<K, u8>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, integer);
        }
        else if (type_bytes == b"u16") {
            let integer = *dynamic_field::borrow<K, u16>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, integer);
        } 
        else if (type_bytes == b"u32") {
            let integer = *dynamic_field::borrow<K, u32>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, integer);
        } 
        else if (type_bytes == b"u64") {
            let integer = *dynamic_field::borrow<K, u64>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, integer);
        } 
        else if (type_bytes == b"u128") {
            let integer = *dynamic_field::borrow<K, u128>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, integer);
        } 
        else if (type_bytes == b"u256") {
            let integer = *dynamic_field::borrow<K, u256>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, integer);
        } 
        else if (type_bytes == b"String") {
            let string = *dynamic_field::borrow<K, String>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, string);
        }
        else if (type_bytes == b"Url") {
            let url = *dynamic_field::borrow<K, Url>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, url);
        } 
        else if (type_bytes == b"vector<address>") {
            let vec = *dynamic_field::borrow<K, vector<address>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<bool>") {
            let vec = *dynamic_field::borrow<K, vector<bool>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<id>") {
            let vec = *dynamic_field::borrow<K, vector<ID>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<u8>") {
            let vec = *dynamic_field::borrow<K, vector<u8>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<u16>") {
            let vec = *dynamic_field::borrow<K, vector<u16>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<u32>") {
            let vec = *dynamic_field::borrow<K, vector<u32>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<u64>") {
            let vec = *dynamic_field::borrow<K, vector<u64>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<u128>") {
            let vec = *dynamic_field::borrow<K, vector<u128>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<u256>") {
            let vec = *dynamic_field::borrow<K, vector<u256>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<vector<u8>>") {
            let vec = *dynamic_field::borrow<K, vector<vector<u8>>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec);
        }
        else if (type_bytes == b"vector<String>") {
            let strings = *dynamic_field::borrow<K, vector<String>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, strings);
        }
        else if (type_bytes == b"vector<Url>") {
            let urls = *dynamic_field::borrow<K, vector<Url>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, urls);
        }
        else if (type_bytes == b"VecMap") {
            let vec_map = *dynamic_field::borrow<K, VecMap<String, String>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec_map);
        }
        else if (type_bytes == b"vector<VecMap>") {
            let vec_maps = *dynamic_field::borrow<K, vector<VecMap<String, String>>>(source_uid, source_key);
            dynamic_field2::set(destination_uid, destination_key, vec_maps);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // Unfortunately sui::dynamic_field does not have a general 'drop' function; the value of the type
    // being dropped MUST be known. This makes dropping droppable assets unecessarily complex, hence
    // this lengthy function in place of what should be one line of code. I know... ;-(
    public fun drop_field<T: store + copy + drop>(uid: &mut UID, key: T, type: String) {
        let type_bytes = *string::bytes(&type);

        if (type_bytes == b"address") {
            dynamic_field2::drop<T, address>(uid, key);
        } 
        else if (type_bytes == b"bool") {
            dynamic_field2::drop<T, bool>(uid, key);
        } 
        else if (type_bytes == b"id") {
            dynamic_field2::drop<T, ID>(uid, key);
        } 
        else if (type_bytes == b"u8") {
            dynamic_field2::drop<T, u8>(uid, key);
        } 
        else if (type_bytes == b"u64") {
            dynamic_field2::drop<T, u64>(uid, key);
        } 
        else if (type_bytes == b"u128") {
            dynamic_field2::drop<T, u128>(uid, key);
        } 
        else if (type_bytes == b"String") {
            dynamic_field2::drop<T, String>(uid, key);
        }
        else if (type_bytes == b"Url") {
            dynamic_field2::drop<T, Url>(uid, key);
        } 
        else if (type_bytes == b"vector<address>") {
            dynamic_field2::drop<T, vector<address>>(uid, key);
        }
        else if (type_bytes == b"vector<bool>") {
            dynamic_field2::drop<T, vector<bool>>(uid, key);
        }
        else if (type_bytes == b"vector<id>") {
            dynamic_field2::drop<T, vector<ID>>(uid, key);
        }
        else if (type_bytes == b"vector<u8>") {
            dynamic_field2::drop<T, vector<u8>>(uid, key);
        }
        else if (type_bytes == b"vector<u64>") {
            dynamic_field2::drop<T, vector<u64>>(uid, key);
        }
        else if (type_bytes == b"vector<u128>") {
            dynamic_field2::drop<T, vector<u128>>(uid, key);
        }
        else if (type_bytes == b"vector<String>") {
            dynamic_field2::drop<T, vector<String>>(uid, key);
        }
        else if (type_bytes == b"vector<Url>") {
            dynamic_field2::drop<T, vector<Url>>(uid, key);
        }
        else if (type_bytes == b"VecMap") {
            dynamic_field2::drop<T, VecMap<String, String>>(uid, key);
        }
        else if (type_bytes == b"vector<VecMap>") {
            dynamic_field2::drop<T, vector<VecMap<String, String>>>(uid, key);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // Something like dynamic_field::get_bcs_bytes would be nice; we could simplify this down to
    // one line of code
    public fun get_bcs_bytes<T: store + copy + drop>(uid: &UID, key: T, type: String): vector<u8> {
        let type_bytes = *string::bytes(&type);

        if (type_bytes == b"address") {
            let addr = dynamic_field::borrow<T, address>(uid, key);
            bcs::to_bytes(addr)
        } 
        else if (type_bytes == b"bool") {
            let boolean = dynamic_field::borrow<T, bool>(uid, key);
            bcs::to_bytes(boolean)
        } 
        else if (type_bytes == b"id") {
            let object_id = dynamic_field::borrow<T, ID>(uid, key);
            bcs::to_bytes(object_id)
        } 
        else if (type_bytes == b"u8") {
            let int = dynamic_field::borrow<T, u8>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type_bytes == b"u64") {
            let int = dynamic_field::borrow<T, u64>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type_bytes == b"u128") {
            let int = dynamic_field::borrow<T, u128>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type_bytes == b"String") {
            let string = dynamic_field::borrow<T, String>(uid, key);
            bcs::to_bytes(string)
        }
        else if (type_bytes == b"Url") {
            let url = dynamic_field::borrow<T, Url>(uid, key);
            bcs::to_bytes(url)
        } 
        else if (type_bytes == b"vector<address>") {
            let vec = dynamic_field::borrow<T, vector<address>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"vector<bool>") {
            let vec = dynamic_field::borrow<T, vector<bool>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"vector<id>") {
            let vec = dynamic_field::borrow<T, vector<ID>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"vector<u8>") {
            let vec = dynamic_field::borrow<T, vector<u8>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"vector<u64>") {
            let vec = dynamic_field::borrow<T, vector<u64>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"vector<u128>") {
            let vec = dynamic_field::borrow<T, vector<u128>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"vector<String>") {
            let vec = dynamic_field::borrow<T, vector<String>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"vector<Url>") {
            let vec = dynamic_field::borrow<T, vector<Url>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type_bytes == b"VecMap") {
            let vec_map = dynamic_field::borrow<T, VecMap<String, String>>(uid, key);
            bcs::to_bytes(vec_map)
        }
        else if (type_bytes == b"vector<VecMap>") {
            let vec_vec_map = dynamic_field::borrow<T, vector<VecMap<String, String>>>(uid, key);
            bcs::to_bytes(vec_vec_map)
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }
}

#[test_only]
module attach::serializer_tests {
    use std::string::{String, utf8};
    use std::vector;

    use sui::bcs;
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::test_scenario::{Self, Scenario};

    use sui_utils::string2;

    use attach::serializer;

    const SENDER: address = @0x99;

    struct TestObject has key {
        id: UID
    }

    fun create_test_object(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        let object = TestObject { 
            id: object::new(ctx) 
        };

        transfer::share_object(object)
    }

    fun set_fields<T: store + copy + drop>(uid: &mut UID, keys: vector<T>, types: vector<String>, values: vector<vector<u8>>) {
        let (i, len) = (0, vector::length(&keys));
        while (i < len) {
            let key = *vector::borrow(&keys, i);
            let type = *vector::borrow(&types, i);
            let value = *vector::borrow(&values, i);

            serializer::set_field(uid, key, type, string2::empty(), value, true);

            i = i + 1;
        }
    }

    fun assert_deserialize_fields<T: store + copy + drop>(uid: &UID, keys: vector<T>, types: vector<String>, values: vector<vector<u8>>) {
        let (i, len) = (0, vector::length(&keys));
        while (i < len) {
            let key = *vector::borrow(&keys, i);
            let type = *vector::borrow(&types, i);
            let value = *vector::borrow(&values, i);

            let bytes = serializer::get_bcs_bytes(uid, key, type);

            if (type == utf8(b"String")) {
                assert!(bcs::peel_vec_u8(&mut bcs::new(bytes)) == bcs::peel_vec_u8(&mut bcs::new(value)), 0)
            } else if(type == utf8(b"u8")) {
                assert!(bcs::peel_u8(&mut bcs::new(bytes)) == *vector::borrow(&value, 0), 0)
            };

            i = i + 1;
        }
    }

    #[test]
    fun test_set_field() {
        let scenario = test_scenario::begin(SENDER);
        let key = b"name";
        let type = utf8(b"String");
        let value = utf8(b"Max");

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let uid = &mut object.id;

            serializer::set_field_(uid, key, type, string2::empty(), value, true);
            let bytes = serializer::get_bcs_bytes(uid, key, type);

            assert!(utf8(bcs::peel_vec_u8(&mut bcs::new(bytes))) == value, 0);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_field_serialized() {
        let scenario = test_scenario::begin(SENDER);
        let keys = vector[b"name", b"about", b"age"];
        let types = vector[utf8(b"String"), utf8(b"String"), utf8(b"u8")];
        let values = vector[bcs::to_bytes(&b"Max"), bcs::to_bytes(&b"Great guy"), bcs::to_bytes(&30)];

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let uid = &mut object.id;

            set_fields(uid, keys, types, values);
            assert_deserialize_fields(uid, keys, types, values);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1, location = sui::dynamic_field)]
    fun test_drop_fields() {
        let scenario = test_scenario::begin(SENDER);
        let keys = vector[b"name", b"about", b"age"];
        let types = vector[utf8(b"String"), utf8(b"String"), utf8(b"u8")];
        let values = vector[bcs::to_bytes(&b"Max"), bcs::to_bytes(&b"Great guy"), bcs::to_bytes(&30)];

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let uid = &mut object.id;

            set_fields(uid, keys, types, values);
            assert_deserialize_fields(uid, keys, types, values);

            {
                let (key, type) = (b"key", utf8(b"String"));

                serializer::drop_field(uid, key, type);
                serializer::get_bcs_bytes(uid, key, type);
            };

            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_field_duplicate() {
        let scenario = test_scenario::begin(SENDER);
        let key = b"name";
        let type = utf8(b"String");
        let value = utf8(b"Max");

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let source_object = test_scenario::take_shared<TestObject>(&scenario);
            let source_uid = &mut source_object.id;

            serializer::set_field_(source_uid, key, type, string2::empty(), value, true);
            create_test_object(&mut scenario);
            test_scenario::next_tx(&mut scenario, SENDER);
            {
                let dest_object = test_scenario::take_shared<TestObject>(&scenario);
                let dest_uid = &mut dest_object.id;

                serializer::duplicate(source_uid, dest_uid, key, key, type, string2::empty(), true);

                let bytes = serializer::get_bcs_bytes(dest_uid, key, type);
                assert!(utf8(bcs::peel_vec_u8(&mut bcs::new(bytes))) == value, 0);

                test_scenario::return_shared(dest_object);
            };

            test_scenario::return_shared(source_object);
        };

        test_scenario::end(scenario);
    }

}
