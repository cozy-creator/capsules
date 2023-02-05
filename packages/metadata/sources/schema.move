module metadata::schema {
    use std::ascii::{Self, String};
    use std::option::{Self, Option};
    use std::vector;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui_utils::encode;

    // error constants
    const EMISMATCHED_LENGTHS_OF_INPUTS: u64 = 0;
    const EUNSUPPORTED_TYPE: u64 = 1;

    // Every schema "type" must be included in this list. We do not support (de)serialization of arbitrary structs
    const SUPPORTED_TYPES: vector<vector<u8>> = vector[b"address", b"bool", b"id", b"u8", b"u16", b"u32", b"u64", b"u128", b"u256", b"string", b"vector<address>", b"vector<bool>", b"vector<id>", b"vector<u8>", b"vector<u16>", b"vector<u32>", b"vector<u64>", b"vector<u128>", b"vector<u256>", b"vector<string>", b"VecMap<string,string>", b"vector<vector<u8>>"];

    // Immutable root-level object
    struct Schema has key {
        id: UID,
        schema: vector<Item>
    }

    struct Item has store, copy, drop {
        key: String,
        type: String,
        optional: bool
    }

    // Schema is defined like [ [name, type], [name, type], ... ]
    public entry fun define(schema_fields: vector<vector<String>>, ctx: &mut TxContext) {
        let len = vector::length(&schema_fields);

        let (i, schema) = (0, vector::empty<Item>());
        while (i < len) {
            let tuple = vector::borrow(&schema_fields, i);
            let type_raw = *vector::borrow(tuple, 1);
            let type_parsed = encode::parse_option(type_raw);
            let (type, optional) = if (ascii::length(&type_parsed) == 0) {
                (type_raw, false)
            } else {
                (type_parsed, true)
            };

            assert!(is_supported_type(type), EUNSUPPORTED_TYPE);

            let key = *vector::borrow(tuple, 0);
            vector::push_back(&mut schema, Item { key, type, optional });
            i = i + 1;
        };

        transfer::freeze_object(Schema {
            id: object::new(ctx),
            schema
        });
    }

    // Returns all of Schema1's keys that are not included in Schema2, i.e., Schema1 - Schema2
    public fun difference(schema1: &Schema, schema2: &Schema): vector<Item> {
        let items1 = into_items(schema1);
        let (i, items) = (0, vector::empty<Item>());
        while (i < vector::length(&items1)) {
            let item = vector::borrow(&items1, i);
            let (key, _, _) = item(item);
            if (!has_key(schema2, key)) {
                vector::push_back(&mut items, *item)
            };
            i = i + 1;
        };

        items
    }

    // Checks to see if two schemas are compatible, i.e., any overlapping fields map to the same type
    public fun is_compatible(schema1: &Schema, schema2: &Schema): bool {
        if (schema1 == schema2) return true;

        let items1 = into_items(schema1);
        let i = 0;
        while (i < vector::length(&items1)) {
            let (key, type1, _) = item(vector::borrow(&items1, i));
            let (type2_maybe, _) = find_type_for_key(schema2, key);
            if (option::is_some(&type2_maybe)) {
                let type2 = option::destroy_some(type2_maybe);
                if (type1 != type2) return false;
            };
            i = i + 1;
        };

        true
    }

    // ========= Accessor Functions =========

    public fun into_items(schema: &Schema): vector<Item> {
        *&schema.schema
    }

    public fun item(item: &Item): (String, String, bool) {
        (item.key, item.type, item.optional)
    }

    public fun length(schema: &Schema): u64 {
        vector::length(&schema.schema)
    }

    // ============ Helper Function ============

    public fun is_supported_type(type: String): bool {
        if (vector::contains(&SUPPORTED_TYPES, &ascii::into_bytes(type))) true
        else {
            let option_type = encode::parse_option(type);
            if (ascii::length(&option_type) == 0) false
            else if (vector::contains(&SUPPORTED_TYPES, &ascii::into_bytes(option_type))) true
            else false
        }
    }

    public fun has_key(schema: &Schema, key: ascii::String): bool {
        let (items, i) = (into_items(schema), 0);
        while (i < vector::length(&items)) {
            if (key == *&vector::borrow(&items, i).key) return true;
            i = i + 1;
        };

        false
    }

    // We find the type corresponding to the given key in a Schema, if it exists. Returns option::none() if it doesn't.
    public fun find_type_for_key(schema: &Schema, key: ascii::String): (Option<ascii::String>, Option<bool>) {
        let (items, i) = (&schema.schema, 0);
        while (i < vector::length(items)) {
            let item = vector::borrow(items, i);
            if (item.key == key) {
                return (option::some(item.type), option::some(item.optional))
            };
            i = i + 1;
        };

        (option::none(), option::none())
    }
}