// General purpose functions for converting data types

// Definitions:
// Full-qualified type-name, or simply 'type name' for short. Contains no abbreviations or 0x address prefixes:
// 0000000000000000000000000000000000000000000000000000000000000002::devnet_nft::DevNetNFT
// 0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<0000000000000000000000000000000000000000000000000000000000000002::sui::SUI>
// 0000000000000000000000000000000000000001::string::String
// This is <package_id>::<module_name>::<struct_name>
//
// A `module-address` is <package_id>::<module_name>

module sui_utils::encode {
    use std::ascii;
    use std::string::{Self, String, utf8};
    use std::type_name;
    use std::vector;

    use sui::address;
    use sui::bcs;
    use sui::hash;
    use sui::hex;
    use sui::object::{Self, ID};

    use sui_utils::vector2;
    use sui_utils::string2;

    // error constants
    const EINVALID_TYPE_NAME: u64 = 0;
    const ESUPPLIED_TYPE_CANNOT_BE_ABSTRACT: u64 = 1;

    public fun is_same_type<A, B>(): bool {
        type_name::get<A>() == type_name::get<B>()
    }

    public fun type_name<T>(): String {
        utf8(ascii::into_bytes(type_name::into_string(type_name::get<T>())))
    }

    public fun type_name_decomposed<T>(): (ID, String, String, vector<String>) {
        decompose_type_name(type_name<T>())
    }

    // Accepts any valid type-name strings and decomposes it into its components:
    // (package_id, module_name, struct name, generics). Supports both structs and primitive types.
    // Primitive types are considered to have an ID of 0x0 and a module name of "".
    // Example output:
    // (0000000000000000000000000000000000000000000000000000000000000002, devnet_nft, DevnetNFT, [])
    // ("0000000000000000000000000000000000000000", "", vector, ["0000000000000000000000000000000000000000000000000000000000000002::devnet_nft::DevnetNFT"])
    // Note that all of these operations assume that the Strings, despite being utf8, are actually ascii bytes.
    // If this assumption is violated, this will abort. We have an open PR in the Move core to allow utf8
    // strings to be more user-friendly.
    public fun decompose_type_name(s1: String): (ID, String, String, vector<String>) {
        let delimiter = utf8(b"::");
        let len = address::length();

        if ((string::length(&s1) > len * 2 + 2) && (string::sub_string(&s1, len * 2, len * 2 + 2) == delimiter)) {
            // This is a fully qualified type, like <package-id>::<module-name>::<struct-name>

            let s2 = string::sub_string(&s1, len * 2 + 2, string::length(&s1));
            let j = string::index_of(&s2, &delimiter);
            assert!(string::length(&s2) > j, EINVALID_TYPE_NAME);

            let package_id_str = string::sub_string(&s1, 0, len * 2);
            let module_name = string::sub_string(&s2, 0, j);
            let struct_name_and_generics = string::sub_string(&s2, j + 2, string::length(&s2));

            let package_id = object::id_from_bytes(hex::decode(*string::bytes(&package_id_str)));
            let (struct_name, generics) = decompose_struct_name(struct_name_and_generics);

            (package_id, module_name, struct_name, generics)
        } else {
            // This is a primitive type, like vector<u64>
            let (struct_name, generics) = decompose_struct_name(s1);
            
            (object::id_from_address(@0x0), string2::empty(), struct_name, generics)
        }
    }

    // Takes a struct-name like `MyStruct<T, G>` and returns (MyStruct, [T, G])
    public fun decompose_struct_name(s1: String): (String, vector<String>) {
        let (struct_name, generics_string) = parse_angle_bracket(s1);
        let generics = parse_comma_delimited_list(generics_string);
        (struct_name, generics)
    }

    // Faster than decomposing the entire type name
    public fun package_id<T>(): ID {
        let bytes_full = ascii::into_bytes(type_name::into_string(type_name::get<T>()));
        // hex doubles the number of characters used
        let bytes = vector2::slice(&bytes_full, 0, address::length() * 2); 
        object::id_from_bytes(hex::decode(bytes))
    }

    // Aborts if type_name is incorrectly formatted
    public fun package_id_(type_name: String): ID {
        let bytes = vector2::slice(string::bytes(&type_name), 0, address::length() * 2); 
        object::id_from_bytes(hex::decode(bytes))
    }

    // Same as above, except an address instead of an ID
    public fun package_addr<T>(): address {
        let bytes_full = ascii::into_bytes(type_name::into_string(type_name::get<T>()));
        let bytes = vector2::slice(&bytes_full, 0, address::length() * 2); 
        address::from_bytes(hex::decode(bytes))
    }
    
    public fun package_addr_(type_name: String): address {
        let bytes = vector2::slice(string::bytes(&type_name), 0, address::length() * 2); 
        address::from_bytes(hex::decode(bytes))
    }

    // Faster than decomposing the entire type name
    public fun module_name<T>(): String {
        let s1 = type_name<T>();
        let s2 = string::sub_string(&s1, address::length() * 2 + 2, string::length(&s1));
        let j = string::index_of(&s2, &utf8(b"::"));
        assert!(string::length(&s2) > j, EINVALID_TYPE_NAME);

        string::sub_string(&s2, 0, j)
    }

    // Returns <package_id>::<module_name>
    public fun package_id_and_module_name<T>(): String {
        let s1 = type_name<T>();
        package_id_and_module_name_(s1)
    }

    // More efficient than doing the package_id and module_name calls separately
    public fun package_id_and_module_name_(s1: String): String {
        let delimiter = utf8(b"::");
        let s2 = string::sub_string(&s1, (address::length() * 2) + 2, string::length(&s1));
        let j = string::index_of(&s2, &delimiter);

        assert!(string::length(&s2) > j, EINVALID_TYPE_NAME);

        let i = (address::length() * 2) + 2 + j;
        string::sub_string(&s1, 0, i)
    }

    // Returns the module_name + struct_name, without any generics, such as `my_module::CoolStruct`
    public fun module_and_struct_name<T>(): String {
        let (_, module_name, struct_name, _) = type_name_decomposed<T>();
        string::append(&mut module_name, utf8(b"::"));
        string::append(&mut module_name, struct_name);

        module_name
    }

    // Takes the module address of Type `T`, and appends an arbitrary string to the end of it
    // This creates a fully-qualified address for a struct that may not exist
    public fun append_struct_name<Type>(struct_name: String): String {
        append_struct_name_(package_id_and_module_name<Type>(), struct_name)
    }

    // Contains no input-validation that `module_addr` is actually a valid module address
    public fun append_struct_name_(module_addr: String, struct_name: String): String {
        string::append(&mut module_addr, utf8(b"::"));
        string::append(&mut module_addr, struct_name);

        module_addr
    }

    // ========== Convert Types into Addresses ==========

    public fun type_into_address<T>(): address {
        let typename = type_name<T>();
        type_string_into_address(typename)
    }

    public fun type_string_into_address(type: String): address {
        let typename_bytes = string::bytes(&type);
        let hashed_typename = hash::blake2b256(typename_bytes);
        bcs::peel_address(&mut bcs::new(hashed_typename))
    }

    // ========== Parser Functions ==========

    // Takes something like `Option<u64>` and returns `u64`. Returns an empty-string if the string supplied 
    // does not contain `Option<`
    public fun parse_option(str: String): String {
        let len = string::length(&str);
        let i = string::index_of(&str, &utf8(b"Option"));

        if (i == len) string2::empty()
        else {
            let (_, t) = parse_angle_bracket(string::sub_string(&str, i + 6, len));
            t
        }
    }

    // Example output:
    // "Option<vector<u64>>" -> ("Option", "vector<u64>")
    // "Coin<0x599::paul_coin::PaulCoin>" -> ("Coin", "0x599::paul_coin::PaulCoin")
    // NFT<ABC, XYZ> -> ("NFT", "ABC, XYZ")
    public fun parse_angle_bracket(str: String): (String, String) {
        let bytes = *string::bytes(&str);
        let (opening_bracket, closing_bracket) = (60u8, 62u8);
        let len = vector::length(&bytes);
        let (start, i, count) = (len, 0, 0);

        while (i < len) {
                let byte = *vector::borrow(&bytes, i);

                if (byte == opening_bracket) {
                    if (count == 0) start = i; // we found the first opening bracket
                    count = count + 1;
                } else if (byte == closing_bracket) {
                    if (count == 0 || count == 1) break; // we found the last closing bracket
                    count = count - 1;
                };

                i = i + 1;
            };

        if (i == len || (start + 1) >= i) (str, string2::empty())
        else (string::sub_string(&str, 0, start), string::sub_string(&str, start + 1, i))
    }

    public fun parse_comma_delimited_list(str: String): vector<String> {
        let bytes = *string::bytes(&str);
        let (space, comma) = (32u8, 44u8);
        let result = vector::empty<String>();
        let (i, j, len) = (0, 0, string::length(&str));

        while (i < len) {
            let byte = *vector::borrow(&bytes, i);

            if (byte == comma) {
                let s = string::sub_string(&str, j, i);
                vector::push_back(&mut result, s);

                // We skip over single-spaces after commas
                if (i < len - 1) {
                    if (*vector::borrow(&bytes, i + 1) == space) {
                        j = i + 2;
                    } else {
                        j = i + 1;
                    };
                } else j = i + 1;
            } else if (i == len - 1) { // We've reached the end of the string
                let s = string::sub_string(&str, j, len);
                vector::push_back(&mut result, s);
            };

            i = i + 1;
        };

        // We didn't find any commas, so we just return the original string
        if (vector::length(&result) == 0) result = vector[str];

        result
    }

    // =============== Validation ===============

    // Returns true for types with generics like `Coin<T>`, returns false for all others
    public fun has_generics<T>(): bool {
        let str = type_name<T>();
        let i = string::index_of(&str, &utf8(b"<"));

        if (i == string::length(&str)) false
        else true
    }

    // Returns true for strings like 'vector<u8>', returns false for all others
    public fun is_vector(str: String): bool {
        if (string::length(&str) < 6) false
        else {
            if (string::sub_string(&str, 0, 6) == utf8(b"vector")) true
            else false
        }
    }

    // =============== Module Comparison ===============

    public fun is_same_module<Type1, Type2>(): bool {
        let module1 = package_id_and_module_name<Type1>();
        let module2 = package_id_and_module_name<Type2>();

        (module1 == module2)
    }
}

#[test_only]
module sui_utils::encode_test {
    use std::debug;
    use std::option::Option;
    use std::string::{Self, utf8, EINVALID_UTF8};
    use std::vector;

    use sui::test_scenario;
    use sui::object;
    use sui::bcs;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use sui_utils::encode;
    use sui_utils::string2;

    // test failure codes
    const EID_DOES_NOT_MATCH: u64 = 1;

    struct SillyStruct<phantom A, phantom B, phantom C> has drop { }

    // bcs bytes != utf8 bytes
    #[test]
    #[expected_failure(abort_code = EINVALID_UTF8)]
    public fun bcs_is_not_utf8() {
        let scenario = test_scenario::begin(@0x5);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let uid = object::new(ctx);
            let addr = object::uid_to_address(&uid);
            let addr_string = string::utf8(bcs::to_bytes(&addr));
            debug::print(&addr_string);
            object::delete(uid);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun decompose_sui_coin_type_name() {
        let scenario = test_scenario::begin(@0x77);
        let _ctx = test_scenario::ctx(&mut scenario);
        {
            let name = encode::type_name<Coin<SUI>>();
            let (_, module_addr, struct_name, _) = encode::decompose_type_name(name);
            assert!(utf8(b"coin") == module_addr, 0);
            assert!(utf8(b"Coin") == struct_name, 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun is_same_module() {
        let scenario = test_scenario::begin(@0x420);
        let _ctx = test_scenario::ctx(&mut scenario);
        {
            assert!(encode::is_same_module<coin::Coin<SUI>, coin::TreasuryCap<SUI>>(), 0);
            assert!(!encode::is_same_module<bcs::BCS, object::ID>(), 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = encode::EINVALID_TYPE_NAME)]
    public fun invalid_string() {
        let scenario = test_scenario::begin(@0x69);
        {
            let (_, _addr, _type, _) = encode::decompose_type_name(utf8(b"0000000000000000000000000000000000000000000000000000000000000000::gotcha_bitch"));
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun package_id() {
        let scenario = test_scenario::begin(@0x79);
        let _ctx = test_scenario::ctx(&mut scenario);
        {
            assert!(encode::package_id<Coin<SUI>>() == object::id_from_address(@0x2), EID_DOES_NOT_MATCH);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun test_parse_option() {
        let none = utf8(b"Does not contain");
        let value1 = encode::parse_option(none);

        let some = utf8(b"Does contain Option<vector<vector<u8>>>");
        let value2 = encode::parse_option(some);

        let none = utf8(b"Failure is not an Option");
        let value3 = encode::parse_option(none);

        assert!(value1 == string2::empty(), 0);
        assert!(value2 == utf8(b"vector<vector<u8>>"), 0);
        assert!(value3 == string2::empty(), 0);
    }

    #[test]
    public fun test_append_struct_name() {
        let module_addr1 = encode::package_id_and_module_name<SUI>();
        let struct1 = encode::append_struct_name_(module_addr1, utf8(b"Witness"));
        assert!(struct1 == utf8(b"0000000000000000000000000000000000000000000000000000000000000002::sui::Witness"), 0);

        let module_addr2 = encode::package_id_and_module_name_(encode::type_name<SUI>());
        assert!(module_addr1 == module_addr2, 0);

        let struct2 = encode::append_struct_name<SUI>(utf8(b"Witness"));
        assert!(struct1 == struct2, 0);
    }

    #[test]
    public fun parse_comma_delimited_list() {
        let string = utf8(b"Paul, George, John, Ringo");
        let parsed_vec = encode::parse_comma_delimited_list(string);
        assert!(vector::length(&parsed_vec) == 4, 0);
        assert!(*vector::borrow(&parsed_vec, 0) == utf8(b"Paul"), 0);
        assert!(*vector::borrow(&parsed_vec, 1) == utf8(b"George"), 0);
        assert!(*vector::borrow(&parsed_vec, 2) == utf8(b"John"), 0);
        assert!(*vector::borrow(&parsed_vec, 3) == utf8(b"Ringo"), 0);
    }

    #[test]
    public fun is_vector() {
        let type_name = encode::type_name<SUI>();
        let (_, _, struct_name, _) = encode::decompose_type_name(type_name);
        assert!(!encode::is_vector(struct_name), 0);

        let type_name = encode::type_name<vector<SUI>>();
        assert!(encode::is_vector(type_name), 0);

        let (_, _, struct_name, _) = encode::decompose_type_name(type_name);
        assert!(struct_name == utf8(b"vector"), 0);
    }

    #[test]
    public fun module_name() {
        let module_name = encode::module_name<SUI>();
        assert!(module_name == utf8(b"sui"), 0);

        let module_name = encode::module_name<Option<u64>>();
        assert!(module_name == utf8(b"option"), 0);
    }

    #[test]
    public fun package_id_and_module_name() {
        let pkg_mod_name = encode::package_id_and_module_name<SUI>();
        assert!(pkg_mod_name == utf8(b"0000000000000000000000000000000000000000000000000000000000000002::sui"), 0);

        let pkg_mod_name = encode::package_id_and_module_name<Option<u64>>();
        assert!(pkg_mod_name == utf8(b"0000000000000000000000000000000000000000000000000000000000000001::option"), 0);
    }

    // There is currently a bug in Move core that prevents this from working. We'll bring this back
    // once it's fixed.
    #[test]
    public fun generics() {
        // let (_, _, struct_name, generics) = encode::type_name_decomposed<SillyStruct<SUI, u64, vector<u8>>>();
        // debug::print(&generics);

        // debug::print(&encode::type_name<SillyStruct<SUI, u64, vector<u8>>>());

        // assert!(struct_name == utf8(b"SillyStruct"), 0);
        // assert!(vector::length(&generics) == 3, 0);
        // assert!(*vector::borrow(&generics, 0) == utf8(b"0000000000000000000000000000000000000000000000000000000000000002::sui::SUI"), 0);
        // assert!(*vector::borrow(&generics, 1) == utf8(b"u64"), 0);
        // assert!(*vector::borrow(&generics, 2) == utf8(b"vector<u8>"), 0);
    }
}