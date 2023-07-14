// Dispenser schema
// The dispenser schema format is flat vector containing byte representation of the type name of each fields. 
// unlike the capsule's metadata schema, the dispenser schema does not include the field name.

module dispenser::schema {
    use std::hash;
    use std::vector;

    use sui::bcs;

    use sui_utils::deserialize;

    struct Schema has store, drop {
        fields: vector<vector<u8>>
    }

    const EUNRECOGNIZED_TYPE: u64 = 0;

    const SUPPORTED_TYPES: vector<vector<u8>> = vector[b"address", b"bool", b"id", b"u8", b"u16", b"u32", b"u64", b"u128", b"u256", b"String", b"vector<address>", b"vector<bool>", b"vector<id>", b"vector<u8>", b"vector<u16>", b"vector<u32>", b"vector<u64>", b"vector<u128>", b"vector<u256>", b"vector<String>", b"VecMap<String,String>", b"vector<vector<u8>>"];

    public fun create(fields: vector<vector<u8>>): Schema {
        let (i, len) = (0, vector::length(&fields));

        while(i < len) {
            assert!(is_supported_type(vector::borrow(&fields, i)), EUNRECOGNIZED_TYPE);
            i = i + 1;
        };

        Schema { fields }
    }

    public fun validate(schema: &Schema, data: vector<u8>) {
        let (i, len) = (0, vector::length(&schema.fields));
        let index = 0;

        while(i < len) {
            let type = *vector::borrow(&schema.fields, i);

            if (type == b"address") {
                (_, index) = deserialize::address_(&data, index);
            } else if (type == b"bool") {
                (_, index) = deserialize::bool_(&data, index);
            } else if (type == b"id") {
                (_, index) = deserialize::id_(&data, index);
            } else if (type == b"u8") {
                vector::borrow(&data, index); 
                index = index + 1;
            } else if (type == b"u16") {
                (_, index) = deserialize::u16_(&data, index);
            } else if (type == b"u32") {
                (_, index) = deserialize::u32_(&data, index);
            } else if (type == b"u64") {
                (_, index) = deserialize::u64_(&data, index);
            } else if (type == b"u128") {
                (_, index) = deserialize::u128_(&data, index);      
            } else if (type == b"u256") {
                (_, index) = deserialize::u256_(&data, index);
            } else if (type == b"String") {
                (_, index) = deserialize::string_(&data, index);
            } else if (type == b"vector<address>") {
                (_, index) = deserialize::vec_address(&data, index);
            } else if (type == b"vector<bool>") {
                (_, index) = deserialize::vec_bool(&data, index);
            } else if (type == b"vector<id>") {
                (_, index) = deserialize::vec_id(&data, index);
            } else if (type == b"vector<u8>") {
                (_, index) = deserialize::vec_u8(&data, index);
            } else if (type == b"vector<u16>") {
                (_, index) = deserialize::vec_u16(&data, index);
            } else if (type == b"vector<u32>") {
                (_, index) = deserialize::vec_u32(&data, index);
            } else if (type == b"vector<u64>") {
                (_, index) = deserialize::vec_u64(&data, index);
            } else if (type == b"vector<u128>") {
                (_, index) = deserialize::vec_u128(&data, index);
            } else if (type == b"vector<u256>") {
                (_, index) = deserialize::vec_u256(&data, index);
            } else if (type == b"vector<vector<u8>>") {
                (_, index) = deserialize::vec_vec_u8(&data, index);
            } else if (type == b"vector<String>") {
                (_, index) = deserialize::vec_string(&data, index);
            } else if (type == b"VecMap<String,String>") {
                (_, index) = deserialize::vec_map_string_string(&data, index);
            } else {
                abort EUNRECOGNIZED_TYPE
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