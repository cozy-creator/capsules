// General purpose functions for converting data types

// Definitions:
// Full-qualified type-name, or simply 'type name' for short. Contains no abbreviations or 0x address prefixes:
// 0000000000000000000000000000000000000002::devnet_nft::DevNetNFT
// 0000000000000000000000000000000000000002::coin::Coin<0000000000000000000000000000000000000002::sui::SUI>
// 0000000000000000000000000000000000000001::ascii::String
// This is <package_id>::<module_name>::<struct_name>
//
// A `module-address` is <package_id>::<module_name>

module sui_utils::encode {
    use std::ascii::{Self, String};
    use std::type_name;
    use std::vector;
    use sui::address;
    use sui::object::ID;
    use sui_utils::vector2;
    use sui_utils::ascii2;

    // error constants
    const EINVALID_TYPE_NAME: u64 = 0;
    const ESUPPLIED_TYPE_CANNOT_BE_ABSTRACT: u64 = 1;

    public fun type_name<T>(): String {
        type_name::into_string(type_name::get<T>())
    }

    public fun type_name_decomposed<T>(): (ID, String, String, vector<String>) {
        decompose_type_name(type_name<T>())
    }

    // Accepts a full-qualified type-name strings and decomposes it into its components:
    // (package_id, module_name, struct name, generics).
    // Aborts if the string does not conform to the `address::module::type` format
    // Example output:
    // (0000000000000000000000000000000000000002, devnet_nft, DevnetNFT, [])
    public fun decompose_type_name(s1: String): (ID, String, String, vector<String>) {
        let delimiter = ascii::string(b"::");
        let len = address::length();
        assert!(ascii::length(&s1) > len, EINVALID_TYPE_NAME);
        assert!(ascii2::sub_string(&s1, len * 2, len * 2 + 2) == delimiter, EINVALID_TYPE_NAME);

        let s2 = ascii2::sub_string(&s1, len * 2 + 2, ascii::length(&s1));
        let j = ascii2::index_of(&s2, &delimiter);
        assert!(ascii::length(&s2) > j, EINVALID_TYPE_NAME);

        let package_id_str = ascii2::sub_string(&s1, 0, len * 2);
        let module_name = ascii2::sub_string(&s2, 0, j);
        let struct_name_and_generics = ascii2::sub_string(&s2, j + 2, ascii::length(&s2));

        let package_id = ascii2::ascii_bytes_into_id(ascii::into_bytes(package_id_str));
        let (struct_name, generics) = decompose_struct_name(struct_name_and_generics);

        (package_id, module_name, struct_name, generics)
    }

    // Takes a struct-name like `MyStruct<T, G>` and returns (MyStruct, [T, G])
    public fun decompose_struct_name(s1: String): (String, vector<String>) {
        let (struct_name, generics_string) = parse_angle_bracket(s1);
        let generics = parse_comma_delimited_list(generics_string);
        (struct_name, generics)
    }

    // Faster than decomposing the entire type name
    public fun package_id<T>(): ID {
        let bytes_full = ascii::into_bytes(type_name<T>());
        // hex doubles the number of characters used
        let bytes = vector2::slice(&bytes_full, 0, address::length() * 2); 
        ascii2::ascii_bytes_into_id(bytes)
    }

    // Faster than decomposing the entire type name
    public fun module_name<T>(): String {
        let s1 = type_name<T>();
        let s2 = ascii2::sub_string(&s1, address::length() * 2 + 2, ascii::length(&s1));
        let j = ascii2::index_of(&s2, &ascii::string(b"::"));
        assert!(ascii::length(&s2) > j, EINVALID_TYPE_NAME);

        ascii2::sub_string(&s2, 0, j)
    }

    // Returns <package_id>::<module_name>
    public fun package_id_and_module_name<T>(): String {
        let s1 = type_name<T>();
        package_id_and_module_name_(s1)
    }

    public fun package_id_and_module_name_(s1: String): String {
        let delimiter = ascii::string(b"::");
        let s2 = ascii2::sub_string(&s1, (address::length() * 2) + 2, ascii::length(&s1));
        let j = ascii2::index_of(&s2, &delimiter);

        assert!(ascii::length(&s2) > j, EINVALID_TYPE_NAME);

        let i = (address::length() * 2) + 2 + j;
        ascii2::sub_string(&s1, 0, i)
    }

    // Returns the module_name + struct_name, without any generics, such as `my_module::CoolStruct`
    public fun module_and_struct_name<T>(): String {
        let (_, module_name, struct_name, _) = type_name_decomposed<T>();
        ascii2::append(&mut module_name, ascii::string(b"::"));
        ascii2::append(&mut module_name, struct_name);

        module_name
    }

    // Takes the module address of Type `T`, and appends an arbitrary ascii string to the end of it
    // This creates a fully-qualified address for a struct that may not exist
    public fun append_struct_name<Type>(struct_name: String): String {
        append_struct_name_(package_id_and_module_name<Type>(), struct_name)
    }

    // Contains no input-validation that `module_addr` is actually a valid module address
    public fun append_struct_name_(module_addr: String, struct_name: String): String {
        ascii2::append(&mut module_addr, ascii::string(b"::"));
        ascii2::append(&mut module_addr, struct_name);

        module_addr
    }

    // ========== Parser Functions ==========

    // Takes something like `Option<u64>` and returns `u64`. Returns an empty-string if the string supplied 
    // does not contain `Option<`
    public fun parse_option(str: String): String {
        let len = ascii::length(&str);
        let i = ascii2::index_of(&str, &ascii::string(b"Option"));

        if (i == len) ascii2::empty()
        else {
            let (_, t) = parse_angle_bracket(ascii2::sub_string(&str, i + 6, len));
            t
        }
    }

    // Example output:
    // Option<vector<u64>> -> (Option, vector<u64>)
    // Coin<0x599::paul_coin::PaulCoin> -> (Coin, 0x599::paul_coin::PaulCoin)
    public fun parse_angle_bracket(str: String): (String, String) {
        let (opening_bracket, closing_bracket) = (ascii::char(60u8), ascii::char(62u8));
        let len = ascii::length(&str);
        let (start, i, count) = (len, 0, 0);
        while (i < len) {
                let char = ascii2::into_char(&str, i);

                if (char == opening_bracket) {
                    if (count == 0) start = i; // we found the first opening bracket
                    count = count + 1;
                } else if (char == closing_bracket) {
                    if (count == 0 || count == 1) break; // we found the last closing bracket
                    count = count - 1;
                };

                i = i + 1;
            };

        if (i == len || (start + 1) >= i) (str, ascii2::empty())
        else (ascii2::sub_string(&str, 0, start), ascii2::sub_string(&str, start + 1, i))
    }

    public fun parse_comma_delimited_list(str: String): vector<String> {
        let (space, comma) = (ascii::char(32u8), ascii::char(44u8));
        let result = vector::empty<String>();
        let (i, j, len) = (0, 0, ascii::length(&str));
        while (i < len) {
            let char = ascii2::into_char(&str, i);

            if (char == comma) {
                let s = ascii2::sub_string(&str, j, i);
                vector::push_back(&mut result, s);

                // We skip over single-spaces after commas
                if (i < len - 1) {
                    if (ascii2::into_char(&str, i + 1) == space) {
                        j = i + 2;
                    } else {
                        j = i + 1;
                    };
                } else j = i + 1;
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
        let i = ascii2::index_of(&str, &ascii::string(b"<"));

        if (i == ascii::length(&str)) false
        else true
    }

    // Returns true for strings like 'vector<u8>', returns false for all others
    public fun is_vector(str: String): bool {
        if (ascii::length(&str) < 6) false
        else {
            if (ascii2::sub_string(&str, 0, 6) == ascii::string(b"vector")) true
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
    use sui::test_scenario;
    use std::ascii;
    use std::string;
    use sui::object;
    use sui::bcs;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui_utils::encode;
    use sui_utils::ascii2;

    // test failure codes
    const EID_DOES_NOT_MATCH: u64 = 1;

    // bcs bytes != utf8 bytes
    #[test]
    #[expected_failure]
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
            assert!(ascii::string(b"coin") == module_addr, 0);
            assert!(ascii::string(b"Coin") == struct_name, 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun match_modules() {
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
            let (_, _addr, _type, _) = encode::decompose_type_name(ascii::string(b"1234567890"));
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun package_id_test() {
        let scenario = test_scenario::begin(@0x79);
        let _ctx = test_scenario::ctx(&mut scenario);
        {
            assert!(encode::package_id<Coin<SUI>>() == object::id_from_address(@0x2), EID_DOES_NOT_MATCH);
        };
        test_scenario::end(scenario);
    }

    // #[test]
    // public fun test_type_name_with_generic() {
    //     let (type, generic) = encode::type_name_with_generic<Coin<SUI>>();
    //     assert!(ascii::string(b"0000000000000000000000000000000000000002::coin::Coin") == type, 0);
    //     assert!(ascii::string(b"0000000000000000000000000000000000000002::sui::SUI") == generic, 0);

    //     let (type, generic) = encode::type_name_with_generic<SUI>();
    //     assert!(ascii::string(b"0000000000000000000000000000000000000002::sui::SUI") == type, 0);
    //     assert!(ascii2::empty() == generic, 0);
    // }

    #[test]
    public fun test_parse_option() {
        let none = ascii::string(b"Does not contain");
        let value1 = encode::parse_option(none);

        let some = ascii::string(b"Does contain Option<vector<vector<u8>>>");
        let value2 = encode::parse_option(some);

        let none = ascii::string(b"Failure is not an Option");
        let value3 = encode::parse_option(none);

        assert!(value1 == ascii2::empty(), 0);
        assert!(value2 == ascii::string(b"vector<vector<u8>>"), 0);
        assert!(value3 == ascii2::empty(), 0);
    }
}