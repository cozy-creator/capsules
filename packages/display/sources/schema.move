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
        fields: VecMap<String, Field>,
        hash_id: vector<u8>
    }

    struct Field has store, copy, drop {
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
    public fun create_from_strings(schema_fields: vector<vector<String>>, ctx: &mut TxContext): Schema {
        let fields = fields_from_strings(schema_fields);

        Schema { 
            id: object::new(ctx), 
            fields, 
            hash_id: compute_hash_id(fields) 
        }
    }

    public fun create_from_vec_map(fields: VecMap<String, Field>, ctx: &mut TxContext): Schema {
        Schema { 
            id: object::new(ctx),
            fields,
            hash_id: compute_hash_id(fields) 
        }
    }

    public fun fields_from_strings(schema_fields: vector<vector<String>>): VecMap<String, Field> {
        let len = vector::length(&schema_fields);

        let (i, fields) = (0, vec_map::empty<String, Field>());
        while (i < len) {
            let tuple = vector::borrow(&schema_fields, i);
            let (key, field) = new_field(tuple);
            vec_map::insert(&mut fields, key, field);
            i = i + 1;
        };

        fields
    }

    // Creates a `Field` from a vector of Strings
    // input strings: [ name, type, resolver ]
    public fun new_field(tuple: &vector<String>): (String, Field) {
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

        (*vector::borrow(&tuple, 0), Field { type, optional, resolver })
    }

    public fun freeze(schema: Schema) {
        transfer::freeze_object(schema);
    }

    public fun destroy(schema: Schema) {
        let Schema { id, fields: _, hash_id: _ } = schema;
        object::delete(id);
    }

    // Schemas cannot have 'copy' because they have 'key', but we can still duplicate them manually
    public fun duplicate(schema: &Schema, ctx: &mut TxContext): Schema {
        Schema { 
            id: object::new(ctx),
            fields: *&schema.fields,
            hash_id: *&schema.hash_id
        }
    }

    // ========= Comparison Functions =========

    // Returns all of Schema1's keys that are not included in Schema2, i.e., Schema1 - Schema2
    public fun difference(schema1: &Schema, schema2: &Schema): vector<Field> {
        let (i, remaining_keys) = (0, vector::empty<String>());

        while (i < vec_map::size(&schema1.fields)) {
            let (key, _) = vec_map::get_entry_by_idx(&schema.fields, i);
            if (!has_key(schema2, key)) {
                vector::push_back(&mut remaining_keys, *key)
            };
            i = i + 1;
        };

        remaining_keys
    }

    // Checks to see if two schemas are compatible, i.e., any overlapping fields map to the same type
    public fun is_compatible(schema1: &Schema, schema2: &Schema): bool {
        if (equals(schema1, schema2)) return true;

        let i = 0;
        while (i < vec_map::size(&schema1.fields)) {
            let (key, fields1) = vec_map::get_entry_by_idx(&schema1.fields, i);
            let (type2_maybe, _) = find_type_for_key(schema2, key);
            if (option::is_some(&type2_maybe)) {
                let type2 = option::destroy_some(type2_maybe);
                if (fields1.type != type2) return false;
            };
            i = i + 1;
        };

        true
    }

    // ========= Accessor Functions =========

    public fun get_fields(schema: &Schema): VecMap<String, Field> {
        *&schema.fields
    }

    public fun get_hash_id(schema: &Schema): vector<u8> {
        schema.hash_id
    }

    // Breaks a field down into its components
    public fun field_into_components(field: &Field): (String, bool, String) {
        (field.type, field.optional, field.resolver)
    }

    public fun length(schema: &Schema): u64 {
        vec_map::size(&schema.fields)
    }

    public fun into_keys(schema: &Schema): vector<String> {
        vec_map::keys(&schema.fields)
    }

    public fun has_key(schema: &Schema, key: String): bool {
        vec_map::contains(&schema.fields, key)
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

    // We find the type corresponding to the given key in a Schema, if it exists. Returns option::none() if it doesn't.
    public fun get_field(schema: &Schema, key: String): (Option<String>, Option<bool>, Option<String>) {
        let index_maybe = vec_map::get_idx_opt(&schema.fields, key);

        if (option::is_some(&index_maybe)) {
            let index = option::destroy_some(index_maybe);
            let (_, field) = vec_map::get_entry_by_idx(&schema.fields, index);
            (option::some(field.type), option::some(field.optional), option::some(field.resolver))
        } else {
            (option::none(), option::none(), option::none())
        }
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
    // Note that the hash_id depends on the order of the fields
    public fun compute_hash_id(fields: VecMap<String, Field>): vector<u8> {
        let (i, len) = (0, vec_map::size(fields));

        while (i < len) {
            let (_, field) = vec_map::get_entry_by_idx_mut(fields, i);
            field.resolver = string2::empty();
            i = i + 1;
        };

        let bytes = bcs::to_bytes(fields);
        hash::sha3_256(bytes)
    }

    public fun compute_hash_id_(raw_fields: vector<vector<String>>): vector<u8> {
        let fields = fields_from_strings(raw_fields);
        compute_hash_id(fields)
    }
}