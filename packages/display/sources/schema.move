module metadata::schema {
    use std::string::{Self, String};
    use std::hash;
    use std::option::{Self, Option};
    use std::vector;

    use sui::bcs;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    use sui_utils::encode;

    // error constants
    const EMISMATCHED_LENGTHS_OF_INPUTS: u64 = 0;
    const EUNSUPPORTED_TYPE: u64 = 1;

    // Every schema "type" must be included in this list. We do not support (de)serialization of arbitrary structs
    const SUPPORTED_TYPES: vector<vector<u8>> = vector[b"address", b"bool", b"id", b"u8", b"u16", b"u32", b"u64", b"u128", b"u256", b"String", b"Url", b"vector<address>", b"VecMap", b"vector<bool>", b"vector<id>", b"vector<u8>", b"vector<u16>", b"vector<u32>", b"vector<u64>", b"vector<u128>", b"vector<u256>", b"vector<String>", b"vector<Url>", b"vector<VecMap>", b"vector<vector<u8>>"];

    // Intended to be an immutable root-level object. But can also be stored.
    struct Schema has key, store {
        id: UID,
        fields: vector<Field>,
        hash_id: vector<u8>
    }

    struct Field has store, copy, drop {
        key: String,
        type: String,
        optional: bool,
        resolver: String
    }

    // The input to this funtion should be shaped like:
    // [ [name, type, resolver], [name, type, resolver], ... ]
    //
    // The resolver strings are optional and can be excluded. Example:
    // [ ["name", "Option<String>"], ["image", "Url"], ["balances", "vector<u64>"] ]
    public entry fun create(schema_fields: vector<vector<String>>, ctx: &mut TxContext) {
        let schema = create_(schema_fields, ctx);
        transfer::freeze_object(schema);
    }

    // It's safe to return a schema here; the caller will eventually have to return the schema
    // before the end of the transaction because schemas only have `key`, so we can guarantee this
    // schema will be frozen
    public fun create_(schema_fields: vector<vector<String>>, ctx: &mut TxContext): Schema {
        let fields = from_fields(schema_fields);

        Schema { 
            id: object::new(ctx), 
            fields, 
            hash_id: compute_hash_id(&fields) 
        }
    }

    public fun create_from_fields(fields: vector<Field>, ctx: &mut TxContext): Schema {
        Schema { 
            id: object::new(ctx),
            fields,
            hash_id: compute_hash_id(&schema_fields) 
        }
    }

    public fun from_fields(schema_fields: vector<vector<String>>): vector<Field> {
        let len = vector::length(&schema_fields);

        let (i, fields) = (0, vector::empty<Field>());
        while (i < len) {
            let tuple = vector::borrow(&schema_fields, i);
            let field = new_field(tuple);
            vector::push_back(&mut fields, field);
            i = i + 1;
        };

        fields
    }

    public fun freeze(schema: Schema) {
        transfer::freeze_object(schema);
    }

    public fun destroy(schema: Schema) {
        let Schema { id, fields: _, hash_id: _ } = schema;
        object::delete(id);
    }

    // Returns all of Schema1's keys that are not included in Schema2, i.e., Schema1 - Schema2
    public fun difference(schema1: &Schema, schema2: &Schema): vector<Field> {
        let fields = into_fields(schema1);
        let (i, remaining_fields) = (0, vector::empty<Field>());

        while (i < vector::length(&fields)) {
            let field = vector::borrow(&fields, i);
            let (key, _, _) = field(field);
            if (!has_key(schema2, key)) {
                vector::push_back(&mut remaining_fields, *field)
            };
            i = i + 1;
        };

        remaining_fields
    }

    // Checks to see if two schemas are compatible, i.e., any overlapping fields map to the same type
    public fun is_compatible(schema1: &Schema, schema2: &Schema): bool {
        if (equals(schema1, schema2)) return true;

        let fields = into_fields(schema1);
        let i = 0;
        while (i < vector::length(&fields)) {
            let (key, type1, _) = field(vector::borrow(&fields, i));
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

    public fun duplicate(schema: &Schema, ctx: &mut TxContext): Schema {
        Schema { 
            id: object::new(ctx),
            fields: into_fields(schema),
            hash_id: into_schema_id(schema)
        }
    }

    public fun into_fields(schema: &Schema): vector<Field> {
        *&schema.fields
    }

    // Breaks a field down into its components
    public fun field_into_components(field: &Field): (String, String, bool, String) {
        (field.key, field.type, field.optional, field.resolver)
    }

    // input strings: [ name, type, resolver ]
    public fun new_field(tuple: &vector<String>): Field {
        let type_raw = *vector::borrow(tuple, 1);
        let type_parsed = encode::parse_option(type_raw);
        let (type, optional) = if (string::is_empty(&type_parsed)) {
            (type_raw, false)
        } else {
            (type_parsed, true)
        };

        assert!(is_supported_type(type), EUNSUPPORTED_TYPE);

        let resolver = if (vector::length(tuple) >= 3) {
            *vector::borrow(tuple, 2)
        } else { string2::empty() };

        let key = *vector::borrow(tuple, 0);

        Field { key, type, optional, resolver }
    }

    public fun is_field_key(field: &Field, key: String): bool {
        field.key == key
    }

    public fun length(schema: &Schema): u64 {
        vector::length(&schema.fields)
    }

    public fun into_keys(schema: &Schema): vector<String> {
        let (fields, i, keys) = (into_fields(schema), 0, vector::empty<String>());
        while (i < vector::length(&fields)) {
            let (key, _, _) = field(vector::borrow(&fields, i));
            vector::push_back(&mut keys, key);
            i = i + 1;
        };

        keys
    }

    // ============ Helper Function ============

    // Note that type strings are case-sensitive; we could change this potentially
    public fun is_supported_type(type: String): bool {
        if (vector::contains(&SUPPORTED_TYPES, string::bytes(type))) true
        else {
            let option_type = encode::parse_option(type);
            if (string::is_empty(&option_type)) false
            else if (vector::contains(&SUPPORTED_TYPES, string::bytes(option_type))) true
            else false
        }
    }

    public fun has_key(schema: &Schema, key: String): bool {
        let (fields, i) = (into_fields(schema), 0);
        while (i < vector::length(&fields)) {
            if (key == *&vector::borrow(&fields, i).key) return true;
            i = i + 1;
        };

        false
    }

    // We find the type corresponding to the given key in a Schema, if it exists. Returns option::none() if it doesn't.
    public fun find_type_for_key(schema: &Schema, key: String): (Option<String>, Option<bool>) {
        let (fields, i) = (into_fields(schema), 0);
        while (i < vector::length(fields)) {
            let field = vector::borrow(fields, i);
            if (field.key == key) {
                return (option::some(field.type), option::some(field.optional))
            };
            i = i + 1;
        };

        (option::none(), option::none())
    }

    // ======= Schema Hash ID =======
    // We use the hash of a schema's fields to uniquely identify a schema, rather than its object-id.

    public fun equals(schema1: &Schema, schema2: &Schema): bool {
        (schema1.hash_id == schema2.hash_id)
    }

    public fun equals_(schema: &Schema, hash_id: vector<u8>): bool {
        (schema.hash_id == hash_id)
    }

    // Resolver strings are ignored for the purposes of computing the schema's hash_id
    public fun compute_schema_id(fields: vector<Field>): vector<u8> {
        let (i, len) = (0, vector::len(fields));
        while (i < len) {
            let field = vector::borrow_mut(&mut fields, i);
            field.resolver = string2::empty();
            i = i + 1;
        };

        let bytes = bcs::to_bytes(fields);
        hash::sha3_256(bytes)
    }

    public fun compute_schema_id_(schema_fields: vector<vector<String>>): vector<u8> {
        let schema = from_fields(schema_fields);
        compute_schema_id(&schema)
    }

    public fun into_schema_id(schema: &Schema): vector<u8> {
        schema.hash_id
    }
}