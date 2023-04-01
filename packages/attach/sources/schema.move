module attach::schema {
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    use sui_utils::vec_map2;

    // Error constants
    const EMISMATCHED_LENGTHS_OF_INPUTS: u64 = 0;
    const EUNSUPPORTED_TYPE: u64 = 1;

    // Every schema "type" must be included in this list. We do not support (de)serialization of
    // arbitrary structs
    const SUPPORTED_TYPES: vector<vector<u8>> = vector[b"address", b"bool", b"id", b"u8", b"u16", b"u32", b"u64", b"u128", b"u256", b"String", b"Url", b"vector<address>", b"VecMap", b"vector<bool>", b"vector<id>", b"vector<u8>", b"vector<u16>", b"vector<u32>", b"vector<u64>", b"vector<u128>", b"vector<u256>", b"vector<String>", b"vector<Url>", b"vector<VecMap>", b"vector<vector<u8>>"];

    // Key for storing the object + namespace -> schema mapping
    // Schemas allows us to enumerate and serialize an object's fields in the future
    struct Key has store, copy drop { namespace: address } // -> VecMap<String, String>

    // ===== Primary Creation / Deletion Functions =====
    // These can only be called by the `data` module, which has already done an authority-check.
    // If we allowed this to be called publicly, it would be possible for any to edit a schema, and
    // the schema would become wildly different from the actual data stored at the specified keys.

    friend attach::data;

    public(friend) fun update_object_schema_(uid: &mut UID, namespace: address, type: String): vector<String> {
        let fields = vector[vector[namespace, type]];
        update_object_schema_(uid, namespace, fields)
    }

    public(friend) fun update_object_schema(
        uid: &mut UID,
        namespace: address,
        fields: vector<vector<String>>
    ): vector<String> {
        // Get the schema stored in the object
        let schema = borrow_mut(uid, namespace);

        // Update the schema with new keys + types, while noting any types that have changed
        let (i, old_types_to_drop) = (0, vector::empty<String>());
        while (i < vector::length(&fields)) {
            let (key, type) = parse_field(vector::borrow(&fields, i));
            let old_type_maybe = vec_map2::set(schema, key, type);

            // TO DO: make sure this line doesn't abort
            if (option::is_some(&old_type_maybe) && *option::borrow(&old_type_maybe) != type) {
                vector::push_back(&mut old_types_to_drop, option::destroy_some(old_type_maybe));
            } else {
                vector::push_back(&mut old_types_to_drop, string::empty());
            };

            i = i + 1;
        };

        old_types_to_drop
    }

    public(friend) fun remove(uid: &mut UID, namespace: address, keys: vector<String>): vector<String> {
        let schema = borrow_mut(uid, namespace);

        let (i, types) = (0, vector::empty<String>());
        while (i < vector::length(&keys)) {
            let type_maybe = vec_map2::remove_maybe(schema, vector::borrow(&keys, i));
            if (option::is_some(&type_maybe)) {
                vector::push_back(&mut types, option::destroy_some(type_maybe));
            } else {
                vector::push_back(&mut types, string::empty());
            }

            i = i + 1;
        };

        types
    }

    public(friend) fun remove_all(uid: &mut UID, namespace): (vector<String>, vector<String>) {
        let key = Key { namespace };

        if (dynamic_field::exists_(uid, key)) {
            let schema = dynamic_field::remove(uid, key);
            vec_map::into_keys_values(schema)
        } else {
            (vector::empty(), vector::empty())
        }
    }

    // Private so that the schema cannot be edited outside this module
    // Creates an empty schema if one does not exist already for the object + namespace
    fun borrow_mut(uid: &UID, namespace: address): &mut VecMap<String, String> {
        let key = Key { namespace };
        if (!dynamic_field::exists_(uid, key)) {
            dynamic_field::add(uid, key, vec_map::empty<String, String>());
        };
        dynamic_field::borrow_mut<Key, Schema>(uid, Key { namespace })
    }

    // ==== Accessor Functions ====
    
    public fun borrow(uid: &UID, namespace: address): &VecMap<String, String> {
        let key = Key { namespace };
        if (!dynamic_field::exists_(uid, key)) {
            vec_map::empty()
        } else {
            dynamic_field::borrow<Key, Schema>(uid, Key { namespace })
        }
    }

    public fun length(uid: &UID, namespace: address): u64 {
        let schema = borrow(uid, namespace);
        vec_map::size(schema)
    }

    public fun into_keys(uid: &UID, namespace: address): vector<String> {
        let schema = borrow(uid, namespace);
        vec_map::keys(schema)
    }

    public fun has_key(uid: &UID, namespace: address, key: String): bool {
        let schema = borrow(uid, namespace);
        vec_map::contains(schema, &key)
    }

    public fun get_type(uid: &UID, namespace: address, key: String): Option<String> {
        let schema = borrow(uid, namespace);
        vec_map2::get_maybe(schema, key)
    }

    // ==== Utility Functions ====

    // If `T` is supported, it returns the corresponding simple-type string, otherwise it returns a blank string
    // For example, the fully-qualified typename of 'String' is '0x1::string::String', but we return just 'String' instead
    public fun simple_type_name<T>(): String {
        let full_type = encode::type_name<T>();
        let type_bytes = *string::bytes(&full_type);

        if (type == b"0x1::string::String") {
            utf8(b"String")
        } else if (type == b"0x1::url::Url") {
            utf8(b"Url")
        } else if (type == b"0x1::vec_map::VecMap<String,String>") {
            // TO DO: we'll likely change this in the future to support more generics than just strings
            utf8(b"VecMap")
        } else if (type == b"vector<0x1::string::String") {
            utf8(b"vector<String>")
        } else if (type == b"vector<0x1::url::Url") {
            utf8(b"vector<Url>")
        } else if (type == b"vector<0x1::vec_map::VecMap<String,String>") {
            utf8(b"vector<VecMap>")
        } else {
            assert!(is_supported_type(full_type), EUNSUPPORTED_TYPE);

            full_type
        }
    }

    // Expects a tuple of strings [ key, type ]
    // Aborts if the `key` or `type` is missing. Aborts if the `type` is unsupported.
    public fun parse_field(field: vector<String>): (String, String) {
        let key = vector::borrow(&field, 0);
        let type = vector::borrow(&field, 1);

        assert!(is_supported_type(type), EUNSUPPORTED_TYPE);

        (*key, *type)
    }

    // TO DO: Note that type strings are case-sensitive; we could change this potentially
    public fun is_supported_type(type: String): bool {
        vector::contains(&SUPPORTED_TYPES, string::bytes(&type))
    }

    // ========= Comparison Functions =========

    // We may bring this back in the future if they're useful...

    // Returns all of Schema1's keys that are not included in Schema2, i.e., Schema1 - Schema2
    // public fun difference(schema1: &Schema, schema2: &Schema): VecMap<String, Field> {
    //     let (i, remainder) = (0, vec_map::empty());

    //     while (i < vec_map::size(&schema1.fields)) {
    //         let (key, field) = vec_map::get_entry_by_idx(&schema1.fields, i);
    //         if (!has_key(schema2, *key)) {
    //             vec_map::insert(&mut remainder, *key, *field)
    //         };
    //         i = i + 1;
    //     };

    //     remainder
    // }

    // Checks to see if two schemas are compatible, i.e., any overlapping fields map to the same type
    // public fun is_compatible(schema1: &Schema, schema2: &Schema): bool {
    //     if (equals(schema1, schema2)) return true;

    //     let i = 0;
    //     while (i < vec_map::size(&schema1.fields)) {
    //         let (key, fields1) = vec_map::get_entry_by_idx(&schema1.fields, i);
    //         let (type2_maybe, _) = get_field(schema2, *key);
    //         if (option::is_some(&type2_maybe)) {
    //             let type2 = option::destroy_some(type2_maybe);
    //             if (fields1.type != type2) return false;
    //         };
    //         i = i + 1;
    //     };

    //     true
    // }

}