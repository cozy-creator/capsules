// Dispenser schema
// The dispenser schema format is flat vector containing byte representation of the type name of each fields. 
// unlike the capsule's metadata schema, the dispenser schema does not include the field name.

module dispenser::schema {
    use std::hash;
    use std::vector;

    use sui::bcs;

    use sui_utils::deserialize;

    struct Schema has store, drop {
        schema_id: vector<u8>,
        fields: vector<vector<u8>>
    }

    const EUnspportedType: u64 = 0;
    const EInvalidDataLength: u64 = 1;

    const SUPPORTED_TYPES: vector<vector<u8>> = vector[b"address", b"bool", b"id", b"u8", b"u16", b"u32", b"u64", b"u128", b"u256", b"String", b"vector<address>", b"vector<bool>", b"vector<id>", b"vector<u8>", b"vector<u16>", b"vector<u32>", b"vector<u64>", b"vector<u128>", b"vector<u256>", b"vector<String>", b"VecMap<String,String>", b"vector<vector<u8>>"];

    public fun create(fields: vector<vector<u8>>): Schema {
        let (i, len) = (0, vector::length(&fields));

        while(i < len) {
            assert!(is_supported_type(vector::borrow(&fields, i)), EUnspportedType);
            i = i + 1;
        };

        Schema {
            schema_id: compute_schema_id(fields),
            fields
        }
    }

    public fun validate(schema: &Schema, data: vector<u8>) {
        let (i, len) = (0, vector::length(&schema.fields));
        let start = 0;

        while(i < len) {
            let type = *vector::borrow(&schema.fields, i);

            if (type == b"address") {
                (_, start) = deserialize::address_(&data, start);
            } else if (type == b"bool") {
                (_, start) = deserialize::bool_(&data, start);
            } else if (type == b"id") {
                (_, start) = deserialize::id_(&data, start);
            } else if (type == b"u8") {
                vector::borrow(&data, start);
                start = start + 1;
            } else if (type == b"u16") {
                (_, start) = deserialize::u16_(&data, start);
            } else if (type == b"u32") {
                (_, start) = deserialize::u32_(&data, start);
            } else if (type == b"u64") {
                (_, start) = deserialize::u64_(&data, start);
            } else if (type == b"u128") {
                (_, start) = deserialize::u128_(&data, start);      
            } else if (type == b"u256") {
                (_, start) = deserialize::u256_(&data, start);
            } else if (type == b"String") {
                (_, start) = deserialize::string_(&data, start);
            } else if (type == b"vector<address>") {
                (_, start) = deserialize::vec_address(&data, start);
            } else if (type == b"vector<bool>") {
                (_, start) = deserialize::vec_bool(&data, start);
            } else if (type == b"vector<id>") {
                (_, start) = deserialize::vec_id(&data, start);
            } else if (type == b"vector<u8>") {
                (_, start) = deserialize::vec_u8(&data, start);
            } else if (type == b"vector<u16>") {
                (_, start) = deserialize::vec_u16(&data, start);
            } else if (type == b"vector<u32>") {
                (_, start) = deserialize::vec_u32(&data, start);
            } else if (type == b"vector<u64>") {
                (_, start) = deserialize::vec_u64(&data, start);
            } else if (type == b"vector<u128>") {
                (_, start) = deserialize::vec_u128(&data, start);
            } else if (type == b"vector<u256>") {
                (_, start) = deserialize::vec_u256(&data, start);
            } else if (type == b"vector<vector<u8>>") {
                (_, start) = deserialize::vec_vec_u8(&data, start);
            } else if (type == b"vector<String>") {
                (_, start) = deserialize::vec_string(&data, start);
            } else if (type == b"VecMap<String,String>") {
                (_, start) = deserialize::vec_map_string_string(&data, start);
            } else {
                abort EUnspportedType
            };

            i = i + 1;
        }
    }

    fun compute_schema_id(fields: vector<vector<u8>>): vector<u8> {
        let bytes = bcs::to_bytes(&fields);
        hash::sha3_256(bytes)
    }

    fun is_supported_type(type: &vector<u8>): bool {
        vector::contains(&SUPPORTED_TYPES, type)
    }

}