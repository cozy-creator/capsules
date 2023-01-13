module metadata::schema {
    use std::ascii;
    use std::option::{Self, Option};
    use std::vector;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    // error constants
    const EMISMATCHED_LENGTHS_OF_INPUTS: u64 = 0;

    // Immutable root-level object
    struct Schema has key {
        id: UID,
        schema: vector<Item>
    }

    struct Item has store, copy, drop {
        key: ascii::String,
        type: ascii::String,
        optional: bool
    }

    public entry fun create(keys: vector<vector<u8>>, types: vector<vector<u8>>, optionals: vector<bool>, ctx: &mut TxContext) {
        let len = vector::length(&keys);
        assert!(len == vector::length(&types) && len == vector::length(&optionals), EMISMATCHED_LENGTHS_OF_INPUTS);

        let (i, schema) = (0, vector::empty<Item>());
        while (i < len) {
            let key = ascii::string(*vector::borrow(&keys, i));
            let type = ascii::string(*vector::borrow(&types, i));
            let optional = *vector::borrow(&optionals, i);
            let item = Item { key, type, optional };
            vector::push_back(&mut schema, item);
            i = i + 1;
        };

        transfer::freeze_object(Schema {
            id: object::new(ctx),
            schema
        });
    }

    // Returns all of Schema1's keys that are not included in Schema2, i.e., Schema1 - Schema2
    public fun difference(schema1: &Schema, schema2: &Schema): vector<Item> {
        let (items1, items2) = (into_items(schema1), into_items(schema2));
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
    public fun is_compatible(schema1_: &Schema, schema2_: &Schema): bool {
        let schema1 = into_items(schema1_);
        let i = 0;
        while (i < vector::length(&schema1)) {
            let (key, type1, _) = item(vector::borrow(&schema1, i));
            let (type2_maybe, _) = find_type_for_key(schema2_, key);
            if (option::is_some(&type2_maybe)) {
                let type2 = option::destroy_some(type2_maybe);
                if (type1 != type2) return false;
            };
            i = i + 1;
        };

        true
    }

    // ========= Accessor Functions =========

    public fun into_items(schema_: &Schema): vector<Item> {
        *&schema_.schema
    }

    public fun item(item: &Item): (ascii::String, ascii::String, bool) {
        let Item { key, type, optional } = *item;
        (key, type, optional)
    }

    public fun length(schema_: &Schema): u64 {
        vector::length(&schema_.schema)
    }

    // ============ Helper Function ============

    public fun has_key(schema: &Schema, key: ascii::String): bool {
        let (items, i) = (into_items(schema), 0);
        while (i < vector::length(&items)) {
            if (key == *&vector::borrow(&items, i).key) return true;
            i = i + 1;
        };

        false
    }

    // We find the type corresponding to the given key in a Schema, if it exists. Returns option::none() if it doesn't.
    public fun find_type_for_key(schema_: &Schema, key: ascii::String): (Option<ascii::String>, Option<bool>) {
        let (schema, i) = (&schema_.schema, 0);
        while (i < vector::length(schema)) {
            let item = vector::borrow(schema, i);
            if (item.key == key) {
                return (option::some(item.type), option::some(item.optional))
            };
            i = i + 1;
        };

        (option::none(), option::none())
    }
}