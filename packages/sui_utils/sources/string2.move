module sui_utils::string2 {
    use std::address;
    use std::bcs;
    use std::string::{Self, String};
    use std::vector;

    use sui::address as sui_address;
    use sui::hex;
    use sui::object::{Self, ID};

    const EINCORRECT_SIZE_FOR_ADDRESS: u64 = 0;

    public fun empty(): String {
        string::utf8(vector::empty())
    }

    // Does not include the 0x prefix. Addresses are 32 bytes and the hex-string are 64 characters
    public fun from_address(addr: address): String {
        let bytes = bcs::to_bytes(&addr);
        string::utf8(hex::encode(bytes))
    }

    public fun from_id(id: ID): String {
        let bytes = object::id_to_bytes(&id);
        string::utf8(hex::encode(bytes))
    }

    public fun into_address(str: String): address {
        assert!(string::length(&str) == address::length() * 2, EINCORRECT_SIZE_FOR_ADDRESS);

        let bytes = string::bytes(&str);
        let addr_bytes = hex::decode(*bytes);
        sui_address::from_bytes(addr_bytes)
    }

    public fun into_id(str: String): ID {
        assert!(string::length(&str) == address::length() * 2, EINCORRECT_SIZE_FOR_ADDRESS);

        let bytes = string::bytes(&str);
        let id_bytes = hex::decode(*bytes);
        object::id_from_bytes(id_bytes)
    }
}