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
    use std::string;
    use std::option;
    use std::vector;
    use sui::bcs::{Self};
    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use metadata::schema::{Self, Schema};
    use sui_utils::ascii2;
    use sui_utils::bcs2;
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

    /// Address length in Sui is 20 bytes.
    const SUI_ADDRESS_LENGTH: u64 = 20;

    struct SchemaID has store, copy, drop { }
    struct Key has store, copy, drop { slot: ascii::String }

    // Schema = vector<ascii::String> = [slot_name, slot_type, optional]
    // for example: "age", "u8", "0", where 0 = required, 1 = optional
    // That is, Schema is a vector with 3 items per item in the schema
    public fun define(uid: &mut UID, schema: &Schema, data: vector<vector<u8>>, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let items = schema::into_items(schema);
        assert!(vector::length(&items) == vector::length(&data), EINCORRECT_DATA_LENGTH);

        let i = 0;
        while (i < vector::length(&items)) {
            let item = vector::borrow(&items, i);
            let (key, type, optional) = schema::item(item);
            let value = *vector::borrow(&data, i);

            set_field(uid, Key { slot: key }, type, optional, value);
            i = i + 1;
        };

        dynamic_field::add(uid, SchemaID { }, object::id(schema));
    }

    // Overwrites existing values
    // Keys are strict, in the sense that if you specify keys that do not exist on the schema, this
    // will abort rather than silently ignoring them.
    public fun update(
        uid: &mut UID,
        keys: vector<vector<u8>>,
        data: vector<vector<u8>>,
        schema: &Schema,
        auth: &TxAuthority
    ) {
        assert_valid_ownership_and_schema(uid, schema, auth);
        assert!(vector::length(&keys) == vector::length(&data), EINCORRECT_DATA_LENGTH);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = ascii::string(*vector::borrow(&keys, i));
            let (type_maybe, optional_maybe) = schema::find_type_for_key(schema, key);
            if (option::is_none(&type_maybe)) abort EKEY_DOES_NOT_EXIST_ON_SCHEMA;
            let value = *vector::borrow(&data, i);

            set_field(uid, Key { slot: key }, option::destroy_some(type_maybe), option::destroy_some(optional_maybe), value);
            i = i + 1;
        };
    }

    public fun remove_optional(uid: &mut UID, keys: vector<vector<u8>>, schema: &Schema, auth: &TxAuthority) {
        assert_valid_ownership_and_schema(uid, schema, auth);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = ascii::string(*vector::borrow(&keys, i));
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

    // Moves from old-schema -> new-schema. Keys and data correspond to each other, in that
    // key[i] corresponds to data[i]. You must supply data for (1) any new fields, (2) any fields
    // that were optional but are now mandatory and are missing on this object, and (3) any fields whose
    // types are changing (i.e., going from ascii-string to utf8-string in the new schema).
    public fun migrate(
        uid: &mut UID,
        old_schema: &Schema,
        new_schema: &Schema,
        keys_raw: vector<vector<u8>>,
        data: vector<vector<u8>>,
        auth: &TxAuthority
    ) {
        assert_valid_ownership_and_schema(uid, old_schema, auth);
        assert!(vector::length(&keys_raw) == vector::length(&data), EINCORRECT_DATA_LENGTH);

        let keys = ascii2::bytes_to_strings(keys_raw);

        // To save space, drop all of the old_schema's fields which no longer exist in the new schema
        let items = schema::difference(old_schema, new_schema);
        let i = 0;
        while (i < vector::length(&items)) {
            let (key, type, _) = schema::item(vector::borrow(&items, i));
            drop_field(uid, Key { slot: key }, type);
        };

        // Iterate through the new schema, making sure that all fields are defined
        let new = schema::into_items(new_schema);
        let i = 0;
        while (i < vector::length(&new)) {
            let (key, type, optional) = schema::item(vector::borrow(&new, i));
            let (old_type_maybe, _) = schema::find_type_for_key(old_schema, key);

            let (exists_, j) = vector::index_of(&keys, &key);
            if (exists_) {
                // the new-type and old-types may be different, so we have to drop the old-value first
                if (option::is_some(&old_type_maybe)) {
                    drop_field(uid, Key { slot: key }, option::destroy_some(old_type_maybe));
                };
                set_field(uid, Key { slot: key }, type, optional, *vector::borrow(&data, j));
            } else {
                // We're not changing the values stored here, so we make sure any old stored values are
                // compatible with the new schema
                let old_bytes = get_bcs_bytes(uid, Key { slot: key }, type);
                if (!optional && old_bytes == vector[0u8]) abort EMISSING_VALUES_NEEDED_FOR_MIGRATION;

                if (option::is_some(&old_type_maybe)) {
                    let old_type = option::destroy_some(old_type_maybe);
                    if (old_type != type && old_bytes != vector[0u8]) {
                        if (optional) {
                            // Delete the old inconsistent field because its optional
                            drop_field(uid, Key { slot: key }, old_type);
                        }
                        else { abort EMISSING_VALUES_NEEDED_FOR_MIGRATION };
                    };
                };
            };

            i = i + 1;
        };

        dynamic_field2::set(uid, SchemaID { }, object::id(new_schema));
    }

    // ============= devInspect Functions ============= 

    // convenience function so you can supply ascii-bytes rather than ascii types
    public fun view(uid: &UID, keys: vector<vector<u8>>, schema: &Schema): vector<vector<u8>> {
        view_(uid, ascii2::bytes_to_strings(keys), schema)
    }

    // This prepends every item with an option byte: 1 (exists) or 0 (doesn't exist)
    // The response we're turning is just raw bytes; it's up to the client app to figure out what the value-types should be,
    // which is why we provide an ID for the object's schema, which is needed in order to deserialize the bytes.
    // Perhaps there is a more convenient way to do this for the client?
    public fun view_(uid: &UID, keys: vector<ascii::String>, schema: &Schema): vector<vector<u8>> {
        assert!(object::id(schema) == schema_id(uid), EINCORRECT_SCHEMA_SUPPLIED);

        let (i, response) = (0, vector::empty<vector<u8>>());
        while (i < vector::length(&keys)) {
            let slot = *vector::borrow(&keys, i);
            vector::push_back(&mut response, view_key(uid, slot, schema));
            i = i + 1;
        };

        response
    }

    fun view_key(uid: &UID, slot: ascii::String, schema: &Schema): vector<u8> {
        let (type_maybe, _) = schema::find_type_for_key(schema, slot);
        if (dynamic_field::exists_(uid, Key { slot }) && option::is_some(&type_maybe)) {
            let type = option::destroy_some(type_maybe);
            let bytes = get_bcs_bytes(uid, Key { slot }, type);
            vector::insert(&mut bytes, 1u8, 0);
            bytes
        } else {
            vector[0u8] // option::is_none
        }
    }

    // This is the same as calling view_ with all the keys of its own schema
    public fun view_all(uid: &UID, schema: &Schema): vector<vector<u8>> {
        let (items, i, keys) = (schema::into_items(schema), 0, vector::empty<ascii::String>());

        while (i < vector::length(&items)) {
            let (key, _, _) = schema::item(vector::borrow(&items, i));
            vector::push_back(&mut keys, key);
            i = i + 1;
        };
        view_(uid, keys, schema)
    }

    // You can specify a set of keys to use by taking them from a 'reader schema'. Note that the reader_schema
    // and object's own schema must be compatible, in the sense that any key overlaps = the same type.
    // Maybe we could take into account optionality or do some sort of type coercian to relax this compatability
    // requirement? I.e., turn a u8 into a u64, or an ascii string into a utf8 string
    public fun view_with_reader_schema(
        uid: &UID,
        reader_schema: &Schema,
        object_schema: &Schema
    ): vector<vector<u8>> {
        assert!(schema::is_compatible(reader_schema, object_schema), EINCOMPATIBLE_READER_SCHEMA);

        let (reader_items, i, keys) = (schema::into_items(reader_schema), 0, vector::empty<ascii::String>());

        while (i < vector::length(&reader_items)) {
            let (key, _, _) = schema::item(vector::borrow(&reader_items, i));
            vector::push_back(&mut keys, key);
            i = i + 1;
        };
        view_(uid, keys, object_schema)
    }

    // Asserting that both the object and the fallback object have compatible schemas is a bit extreme; they
    // really only need to have the same types for overlapping keys
    public fun view_with_default(
        uid: &UID,
        fallback: &UID,
        keys: vector<vector<u8>>,
        schema: &Schema,
        fallback_schema: &Schema,
    ): vector<vector<u8>> {
        assert!(schema::is_compatible(schema, fallback_schema), EINCOMPATIBLE_READER_SCHEMA);
        assert!(object::id(schema) == schema_id(uid), EINCORRECT_SCHEMA_SUPPLIED);
        assert!(object::id(fallback_schema) == schema_id(fallback), EINCORRECT_SCHEMA_SUPPLIED);

        let keys = ascii2::bytes_to_strings(keys);

        let (i, response) = (0, vector::empty<vector<u8>>());
        while (i < vector::length(&keys)) {
            let slot = *vector::borrow(&keys, i);
            let res = view_key(uid, slot, schema);
            if (res != vector[0u8]) {
                vector::push_back(&mut response, view_key(uid, slot, schema));
            } else {
                vector::push_back(&mut response, view_key(fallback, slot, fallback_schema));
            };
            i = i + 1;
        };

        response
    }

    public fun schema_id(uid: &UID): ID {
        *dynamic_field::borrow<SchemaID, ID>(uid, SchemaID { } )
    }

    // ============ (de)serializes objects ============ 

    // BCS serialization for optionals:
    // option::some<u8>() = [1,(8 bytes little endian)]
    // option::none<anything>() = [0]
    // Options prepend a single byte, which is either 0 or 1.
    // Meaning option::some<u64>() has an extra preceeding byte compared to just u64
    // If you are passing in non-optional bytes, such as just u64, rather than Option<u64>, this function will probably abort
    public fun is_some(bytes: vector<u8>): bool {
        let first_byte = *vector::borrow(&bytes, 0);

        if (first_byte == 1) {
            true
        } else if (first_byte == 0) {
            false
        } else {
            abort EMISSING_OPTION_BYTE
        }
    }

    // Private function so that the schema cannot be bypassed
    // Aborts if the type is incorrect because the bcs deserialization will fail
    // Supported: address, bool, objectID, u8, u64, u128, string::String (utf8), ascii::String + vectors of these types
    // Not yet supported: u16, u32, u256 <--not included in sui::bcs
    fun set_field(uid: &mut UID, key: Key, type_: ascii::String, optional: bool, bytes: vector<u8>) {
        // To deserialize, all schema-optional items should be prepended with an option byte, otherwise an abort
        // will occur here.
        if (optional) {
            if (is_some(bytes)) {
                vector::remove(&mut bytes, 0); // remove the optional-byte
            } else { return }; // nothing to add
        };

        let bcs = &mut bcs::new(copy bytes);
        let type = ascii::into_bytes(type_);

        if (type == b"address") {
            let addr = bcs::peel_address(bcs);
            dynamic_field2::set(uid, key, addr);
        } 
        else if (type == b"bool") {
            let boolean = bcs::peel_bool(bcs);
            dynamic_field2::set(uid, key, boolean);
        } 
        else if (type == b"id") {
            let object_id = object::id_from_bytes(bytes);
            dynamic_field2::set(uid, key, object_id);
        } 
        else if (type == b"u8") {
            let integer = bcs::peel_u8(bcs);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u64") {
            let integer = bcs::peel_u64(bcs);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"u128") {
            let integer = bcs::peel_u128(bcs);
            dynamic_field2::set(uid, key, integer);
        } 
        else if (type == b"utf8") {
            let string = string::utf8(bytes);
            dynamic_field2::set(uid, key, string);
        } 
        else if (type == b"ascii") {
            let string = ascii::string(bytes);
            dynamic_field2::set(uid, key, string);
        } 
        else if (type == b"vector<address>") {
            let vec = bcs::peel_vec_address(bcs);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<bool>") {
            let vec = bcs::peel_vec_bool(bcs);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<id>") {
            let vec = bcs2::peel_vec_id(bcs);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u8>") {
            let vec = bcs::peel_vec_u8(bcs);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u64>") {
            let vec = bcs::peel_vec_u64(bcs);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<u128>") {
            let vec = bcs::peel_vec_u128(bcs);
            dynamic_field2::set(uid, key, vec);
        }
        else if (type == b"vector<utf8>") {
            let (string, _) = bcs2::peel_vec_utf8_string(*bcs);
            dynamic_field2::set(uid, key, string);
        }
        else if (type == b"vector<ascii>") {
            let (string, _) = bcs2::peel_vec_ascii_string(*bcs);
            dynamic_field2::set(uid, key, string);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // Private function so that the schema cannot be bypassed
    // Unfortunately sui::dynamic_field does not have a general 'drop' function; the value of the type
    // being dropped MUST be known. This makes dropping droppable assets unecessarily complex, hence
    // this lengthy function in place of what should be one line of code. I know... believe me I've asked.
    fun drop_field(uid: &mut UID, key: Key, type_: ascii::String) {
        let type = ascii::into_bytes(type_);

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
        else if (type == b"utf8") {
            dynamic_field2::drop<Key, string::String>(uid, key);
        } 
        else if (type == b"ascii") {
            dynamic_field2::drop<Key, ascii::String>(uid, key);
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
        else if (type == b"vector<utf8>") {
            dynamic_field2::drop<Key, vector<string::String>>(uid, key);
        }
        else if (type == b"vector<ascii>") {
            dynamic_field2::drop<Key, vector<ascii::String>>(uid, key);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    fun get_bcs_bytes(uid: &UID, key: Key, type_: ascii::String): vector<u8> {
        if (!dynamic_field::exists_(uid, key)) return vector[0u8]; // empty option byte
        let type = ascii::into_bytes(type_);

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
            let string = dynamic_field::borrow<Key, string::String>(uid, key);
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
            let vec = dynamic_field::borrow<Key, vector<string::String>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<ascii>") {
            let vec = dynamic_field::borrow<Key, vector<ascii::String>>(uid, key);
            bcs::to_bytes(vec)
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