// Sui's On-Chain Metadata program

// On-chain metadata is store in its serialized state, not its raw bytes.
// Schemas are stored as root-level objects, rather than being stored inside the objects themselves, in order to save space.
//
// Future to do:
// - have a better url type
// - Upgrade BCS: objectID, peel_u16, peel_u32, peel_u256, peel_ascii_string, peel_utf8_string, and vector versions of
// all of these

module metadata::metadata {
    use std::ascii;
    use std::string::String;
    use std::option;
    use std::vector;
    use sui::bcs::{Self};
    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use sui::vec_map::VecMap;
    use metadata::schema::{Self, Schema};
    use sui_utils::deserialize;
    use sui_utils::dynamic_field2;
    use ownership::ownership;
    use ownership::tx_authority::TxAuthority;

    // Error enums
    const EINCORRECT_DATA_LENGTH: u64 = 0;
    const EMISSING_OPTION_BYTE: u64 = 1;
    const EUNRECOGNIZED_TYPE: u64 = 2;
    const EINCORRECT_SCHEMA_SUPPLIED: u64 = 3;
    const EINCOMPATIBLE_READER_SCHEMA: u64 = 4;
    const EINCOMPATIBLE_MIGRATION_SCHEMA: u64 = 5;
    const ENO_MODULE_AUTHORITY: u64 = 6;
    const ENO_OWNER_AUTHORITY: u64 = 7;
    const EKEY_DOES_NOT_EXIST_ON_SCHEMA: u64 = 8;
    const EMISSING_VALUES_NEEDED_FOR_MIGRATION: u64 = 9;
    const EKEY_IS_NOT_OPTIONAL: u64 = 10;
    const ETYPE_METADATA_IS_INVALID_FALLBACK: u64 = 11;
    const EINCORRECT_TYPE_SPECIFIED_FOR_UID: u64 = 12;

    struct SchemaID has store, copy, drop { }
    struct Key has store, copy, drop { slot: ascii::String }

    // Schema = vector<ascii::String> = [slot_name, slot_type, optional]
    // for example: "age", "u8", "0", where 0 = required, 1 = optional
    // That is, Schema is a vector with 3 fields per item in the schema
    // This is assuming that BCS serialized each value individually, and then appended their bytes in an array
    // What may happen insetad is you get vector<u8>, where all of the bytes are concatanated together, and require
    // prepended length bytes to deserialize.
    public fun define(uid: &mut UID, schema: &Schema, data: vector<vector<u8>>, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let items = schema::into_items(schema);

        let i = 0;
        while (i < vector::length(&items)) {
            let item = vector::borrow(&items, i);
            let (key, type, optional) = schema::item(item);
            let value = *vector::borrow(&data, i);

            set_field(uid, Key { slot: key }, type, optional, value, true);
            i = i + 1;
        };

        dynamic_field::add(uid, SchemaID { }, object::id(schema));
    }

    // If `overwrite` == true, then values or overwritten. Otherwise they are filled-in, in the sense that
    // data will only be written if (1) it is missing, or (2) if the existing data is of the wrong type.
    // This is strict on keys, in the sense that if you specify keys that do not exist on the schema, this
    // will abort rather than silently ignoring them or allowing you to write to keys outside of the schema.
    public fun overwrite(
        uid: &mut UID,
        keys: vector<ascii::String>,
        data: vector<vector<u8>>,
        schema: &Schema,
        overwrite_existing: bool,
        auth: &TxAuthority
    ) {
        assert!(vector::length(&keys) == vector::length(&data), EINCORRECT_DATA_LENGTH);
        assert_valid_ownership_and_schema(uid, schema, auth);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let (type_maybe, optional_maybe) = schema::find_type_for_key(schema, key);
            if (option::is_none(&type_maybe)) abort EKEY_DOES_NOT_EXIST_ON_SCHEMA;
            let value = *vector::borrow(&data, i);

            set_field(
                uid,
                Key { slot: key },
                option::destroy_some(type_maybe),
                option::destroy_some(optional_maybe),
                value,
                overwrite_existing);
            i = i + 1;
        };
    }

    // Useful if you want to borrow_mut but want to avoid an abort in case the value doesn't exist
    public fun exists_(uid: &UID, key: ascii::String): bool {
        dynamic_field::exists_(uid, Key { slot: key } )
    }

    // We allow any metadata field to be read without any permission. T must be correct, otherwise this will abort
    public fun borrow<T: store>(uid: &UID, key: ascii::String): &T {
        dynamic_field::borrow<Key, T>(uid, Key { slot: key } )
    }

    // For atomic updates (like incrementing a counter) use this rather than an `overwrite` to ensure no
    // writes are lost. `T` must be the type corresponding to the schema, and the value must be defined, or
    // this will abort
    public fun borrow_mut<T: store>(uid: &mut UID, key: ascii::String, auth: &TxAuthority): &mut T {
        assert!(ownership::is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field::borrow_mut<Key, T>(uid, Key { slot: key } )
    }

    // You can accomplish this by using `overwrite` with option bytes set to 0 (none) for all keys you
    // want to remove, but this function exists for convenience
    public fun remove_optional(uid: &mut UID, keys: vector<ascii::String>, schema: &Schema, auth: &TxAuthority) {
        assert_valid_ownership_and_schema(uid, schema, auth);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let (type_maybe, optional_maybe) = schema::find_type_for_key(schema, key);
            if (option::is_none(&type_maybe)) abort EKEY_DOES_NOT_EXIST_ON_SCHEMA;
            if (!option::destroy_some(optional_maybe)) abort EKEY_IS_NOT_OPTIONAL;

            drop_field(uid, Key { slot: key }, option::destroy_some(type_maybe));
            i = i + 1;
        };
    }
    
    // Wipes all metadata, including the schema. This allows you to start from scratch again using a new
    // schema and new data using define().
    public fun remove_all(uid: &mut UID, schema: &Schema, auth: &TxAuthority) {
        assert_valid_ownership_and_schema(uid, schema, auth);

        let (i, items) = (0, schema::into_items(schema));
        while (i < vector::length(&items)) {
            let item = vector::borrow(&items, i);
            let (key, type, _) = schema::item(item);

            drop_field(uid, Key { slot: key }, type);
            i = i + 1;
        };

        dynamic_field2::drop<SchemaID, ID>(uid, SchemaID { });
    }

    // Moves from old-schema -> new-schema.
    // Keys and data act as fill-ins; i.e., if there is already a value at 'name' of the type specified in
    // new_schema, then the old view will be left in place. However, if the value is missing, or if the type
    // is different from the one specified in new_schema, the data will be used to fill it in.
    // You must supply [keys, data] for (1) any new fields, (2) any fields that were optional but are now
    // mandatory and are missing on this object, and (3) any fields whose types are changing in the new
    // schema (ex: migrating from ascii-string --> utf8-string).
    public fun migrate(
        uid: &mut UID,
        old_schema: &Schema,
        new_schema: &Schema,
        keys: vector<ascii::String>,
        data: vector<vector<u8>>,
        auth: &TxAuthority
    ) {
        assert_valid_ownership_and_schema(uid, old_schema, auth);

        // Drop all of the old_schema's fields which no longer exist in the new schema
        let items = schema::difference(old_schema, new_schema);
        let i = 0;
        while (i < vector::length(&items)) {
            let (key, type, _) = schema::item(vector::borrow(&items, i));
            drop_field(uid, Key { slot: key }, type);
        };

        // Drop any of the fields whose types are changing
        let new = schema::into_items(new_schema);
        let i = 0;
        while (i < vector::length(&new)) {
            let (key, type, _) = schema::item(vector::borrow(&new, i));
            let (old_type_maybe, _) = schema::find_type_for_key(old_schema, key);
            if (option::is_some(&old_type_maybe)) {
                let old_type = option::destroy_some(old_type_maybe);
                if (old_type != type) drop_field(uid, Key { slot: key }, old_type);
            };
            i = i + 1;
        };

        dynamic_field2::set(uid, SchemaID { }, object::id(new_schema));

        // Fill-in all the newly supplied values
        overwrite(uid, keys, data, new_schema, false, auth);

        // Check to make sure that all required fields are defined
        let i = 0;
        while (i < vector::length(&new)) {
            let (key, _, optional) = schema::item(vector::borrow(&new, i));
            if (!optional) {
                assert!(dynamic_field::exists_(uid, Key { slot: key }), EMISSING_VALUES_NEEDED_FOR_MIGRATION);
            };
            i = i + 1;
        };
    }

    // ============= devInspect Functions ============= 

    // The response is raw BCS bytes; the client app will need to consult this object's cannonical schema for the
    // corresponding keys that were queried in order to deserialize the results.
    public fun view(uid: &UID, keys: vector<ascii::String>, schema: &Schema): vector<u8> {
        assert!(object::id(schema) == schema_id(uid), EINCORRECT_SCHEMA_SUPPLIED);

        let (i, response, len) = (0, vector::empty<u8>(), vector::length(&keys));

        while (i < len) {
            let slot = *vector::borrow(&keys, i);
            vector::append(&mut response, view_key(uid, slot, schema));
            i = i + 1;
        };

        response
    }

    // Note that this doesn't validate that the schema you supplied is the cannonical schema for this object, or that the keys
    // you've specified exist on your suppplied schema. Deserialize these results with the schema you supplied, not with the
    // object's cannonical schema
    public fun view_key(uid: &UID, key: ascii::String, schema: &Schema): vector<u8> {
        let (type_maybe, optional_maybe) = schema::find_type_for_key(schema, key);

        if (dynamic_field::exists_(uid, Key { slot: key }) && option::is_some(&type_maybe)) {
            let type = option::destroy_some(type_maybe);
            let bytes = get_bcs_bytes(uid, Key { slot: key }, type);

            // We only prepend option-bytes if the key is optional
            if (option::destroy_some(optional_maybe)) { 
                vector::insert(&mut bytes, 1u8, 0); // option::is_some
            };

            bytes
        } else {
            vector[0u8] // option::is_none
        }
    }

    // This is the same as calling view with all the keys of its own schema
    public fun view_all(uid: &UID, schema: &Schema): vector<u8> {
        let (items, i, keys) = (schema::into_items(schema), 0, vector::empty<ascii::String>());

        while (i < vector::length(&items)) {
            let (key, _, _) = schema::item(vector::borrow(&items, i));
            vector::push_back(&mut keys, key);
            i = i + 1;
        };

        view(uid, keys, schema)
    }

    // Query all keys specified inside of `reader_schema`
    // Note that the reader_schema and the object's own schema must be compatible, in the sense that any key
    // overlaps are the same type.
    // Maybe we could take into account optionality or do some sort of type coercian to relax this compatability
    // requirement? I.e., turn a u8 into a u64, or an ascii string into a utf8 string
    public fun view_with_reader_schema(
        uid: &UID,
        reader_schema: &Schema,
        object_schema: &Schema
    ): vector<u8> {
        assert!(schema::is_compatible(reader_schema, object_schema), EINCOMPATIBLE_READER_SCHEMA);
        assert!(object::id(object_schema) == schema_id(uid), EINCORRECT_SCHEMA_SUPPLIED);

        let (reader_items, i, keys) = (schema::into_items(reader_schema), 0, vector::empty<ascii::String>());

        while (i < vector::length(&reader_items)) {
            let (key, _, _) = schema::item(vector::borrow(&reader_items, i));
            vector::push_back(&mut keys, key);
            i = i + 1;
        };

        view(uid, keys, object_schema)
    }

    // Asserting that both the object and the fallback object have compatible schemas is a bit extreme; they
    // really only need to have the same types for the keys being used here
    public fun view_with_default(
        uid: &UID,
        fallback: &UID,
        keys: vector<ascii::String>,
        schema: &Schema,
        fallback_schema: &Schema,
    ): vector<u8> {
        assert!(schema::is_compatible(schema, fallback_schema), EINCOMPATIBLE_READER_SCHEMA);
        assert!(object::id(schema) == schema_id(uid), EINCORRECT_SCHEMA_SUPPLIED);
        assert!(object::id(fallback_schema) == schema_id(fallback), EINCORRECT_SCHEMA_SUPPLIED);

        let (i, response, len) = (0, vector::empty<u8>(), vector::length(&keys));

        while (i < len) {
            let slot = *vector::borrow(&keys, i);
            let res = view_key(uid, slot, schema);
            if (res != vector[0u8]) {
                vector::append(&mut response, view_key(uid, slot, schema));
            } else {
                vector::append(&mut response, view_key(fallback, slot, fallback_schema));
            };
            i = i + 1;
        };

        response
    }

    public fun schema_id(uid: &UID): ID {
        *dynamic_field::borrow<SchemaID, ID>(uid, SchemaID { } )
    }

    // ============ (de)serializes objects ============ 

    // Private function so that the schema cannot be bypassed
    // Aborts if the type is incorrect because the bcs deserialization will fail
    // Supported: address, bool, objectID, u8, u64, u128, string (utf8), + vectors of these types
    // + VecMap<string,string>, vector<vector<u8>>
    // Not yet supported: u16, u32, u256 <--not included in sui::bcs
    fun set_field(
        uid: &mut UID,
        key: Key,
        type_string: ascii::String,
        optional: bool,
        value: vector<u8>,
        overwrite: bool
    ) {
        if (vector::length(&value) == 0) {
            if (optional) {
                drop_field(uid, key, type_string);
                return
            } else abort EKEY_IS_NOT_OPTIONAL
        };

        let type = ascii::into_bytes(type_string);

        if (type == b"address") {
            let addr = deserialize::address_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, addr);
        } 
        else if (type == b"bool") {
            let boolean = deserialize::bool_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, boolean);
        } 
        else if (type == b"id") {
            let object_id = deserialize::id_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, object_id);
        } 
        else if (type == b"u8") {
            let integer = deserialize::u8_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        }
        else if (type == b"u16") {
            let integer = deserialize::u16_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u32") {
            let integer = deserialize::u32_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u64") {
            let integer = deserialize::u64_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u128") {
            let integer = deserialize::u128_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u256") {
            let integer = deserialize::u256_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"string") {
            let string = deserialize::string_(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, string);
        } 
        else if (type == b"vector<address>") {
            let vec = deserialize::vec_address(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<bool>") {
            let vec = deserialize::vec_bool(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<id>") {
            let vec = deserialize::vec_id(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u8>") {
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, value);
        }
        else if (type == b"vector<u16>") {
            let vec = deserialize::vec_u16(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u32>") {
            let vec = deserialize::vec_u32(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u64>") {
            let vec = deserialize::vec_u64(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u128>") {
            let vec = deserialize::vec_u128(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u256>") {
            let vec = deserialize::vec_u256(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<vector<u8>>") {
            let vec = deserialize::vec_vec_u8(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<string>") {
            let strings = deserialize::vec_string(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, strings);
        }
        else if (type == b"VecMap<string,string>") {
            let vec_map = deserialize::vec_map_string_string(value);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec_map);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // Private function so that the schema cannot be bypassed
    // Unfortunately sui::dynamic_field does not have a general 'drop' function; the value of the type
    // being dropped MUST be known. This makes dropping droppable assets unecessarily complex, hence
    // this lengthy function in place of what should be one line of code. I know... believe me I've asked.
    fun drop_field(uid: &mut UID, key: Key, type_string: ascii::String) {
        let type = ascii::into_bytes(type_string);

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
        else if (type == b"string") {
            dynamic_field2::drop<Key, String>(uid, key);
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
        else if (type == b"vector<string>") {
            dynamic_field2::drop<Key, vector<String>>(uid, key);
        }
        else if (type == b"VecMap<string,string>") {
            dynamic_field2::drop<Key, VecMap<String, String>>(uid, key);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    public fun get_bcs_bytes(uid: &UID, key: Key, type_string: ascii::String): vector<u8> {
        if (!dynamic_field::exists_(uid, key)) return vector[0u8]; // empty option byte
        let type = ascii::into_bytes(type_string);

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
        else if (type == b"utf8") {
            let string = dynamic_field::borrow<Key, String>(uid, key);
            bcs::to_bytes(string)
        } 
        else if (type == b"ascii") {
            let string = dynamic_field::borrow<Key, ascii::String>(uid, key);
            bcs::to_bytes(string)
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
        else if (type == b"vector<utf8>") {
            let vec = dynamic_field::borrow<Key, vector<String>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<ascii>") {
            let vec = dynamic_field::borrow<Key, vector<ascii::String>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"VecMap<utf8,utf8>") {
            let vec_map = dynamic_field::borrow<Key, VecMap<String, String>>(uid, key);
            bcs::to_bytes(vec_map)
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // ========= Helper Functions ========= 

    public fun assert_valid_ownership_and_schema(uid: &UID, schema: &Schema, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);
        assert!(schema_id(uid) == object::id(schema), EINCORRECT_SCHEMA_SUPPLIED);
    }
}

#[test_only]
module metadata::metadata_tests {
    use std::ascii::string;
    use sui::bcs;
    use sui::object::{Self, UID};
    use sui::test_scenario;
    use metadata::metadata;
    use metadata::schema;
    use ownership::tx_authority;
    use ownership::ownership;
    use sui::transfer;

    struct Witness has drop {}

    struct TestObject has key {
        id: UID
    }

    #[test]
    public fun test_define() {
        let data = vector<vector<u8>>[ b"Kyrie", vector[], b"https://wikipedia.org/", bcs::to_bytes(&19999u64) ];
        // let data = vector<u8>[5, 75, 121, 114, 105, 101,  22, 104, 116, 116, 112, 115,  58,  47,  47, 119, 105, 107, 105, 112, 101, 100, 105,  97,  46, 111, 114, 103,  47,  54,  13, 3, 0, 0, 0, 0, 0];

        let scenario_val = test_scenario::begin(@0x99);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            schema::define(vector[ 
                vector[string(b"name"), string(b"string")],
                vector[string(b"description"), string(b"Option<string>")],
                vector[string(b"image"), string(b"string")], 
                vector[string(b"power_level"), string(b"u64")] 
            ], ctx);
        };

        test_scenario::next_tx(scenario, @0x99);
        let schema = test_scenario::take_immutable<schema::Schema>(scenario);
        {
            let ctx = test_scenario::ctx(scenario);

            let object = TestObject { id: object::new(ctx) };
            let auth = tx_authority::add_capability_type(&Witness {}, &tx_authority::begin(ctx));

            let proof = ownership::setup(&object);
            ownership::initialize(&mut object.id, proof, &auth);

            metadata::define(&mut object.id, &schema, data, &auth);

            transfer::share_object(object);
        };
        test_scenario::return_immutable(schema);

        test_scenario::end(scenario_val);
    }
}