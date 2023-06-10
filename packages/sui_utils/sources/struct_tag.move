// Instead of storing type-name strings like "0x15::devnet_nft::NFT<0x99::outlaw::Outlaw>" we can instead
// parse them out into their 4 components and store them as a StructTag. This saves us the compute cost of
// having to re-parse them every time in future transactions.

// address: a725e7cd33d5092af4f338c58329641dadf7c7bd471e6fa90cec6a37fe24122d, module: Identifier("my_hero"), name: Identifier("Hero"), type_params: [] } - example struct tag from RPC

module sui_utils::struct_tag {
    use std::string::{Self, String, utf8};
    use std::vector;

    use sui::object::{Self, ID};

    use sui_utils::encode;
    use sui_utils::string2;

    // Error enums
    const ESUPPLIED_TYPE_CANNOT_BE_ABSTRACT: u64 = 0;

    // Move does not allow for generic struct definitions, meaning we have to use Strings rather than
    // StructTags for 'generics'. We use the term `generics` here, but the term `type-params` is also used
    // in Sui.
    struct StructTag has store, copy, drop {
        package_id: ID,
        module_name: String,
        struct_name: String,
        generics: vector<String>, 
    }

    public fun get<T>(): StructTag {
        let (package_id, module_name, struct_name, generics) = encode::type_name_decomposed<T>();

        StructTag { package_id, module_name, struct_name, generics }
    }

    // Same as above, except generics are stripped, i.e., you get just sui::coin::Coin rather than
    // sui::coin::Coin<T>
    public fun get_abstract<T>(): StructTag {
        let (package_id, module_name, struct_name, _) = encode::type_name_decomposed<T>();

        StructTag { package_id, module_name, struct_name, generics: vector::empty<String>() }
    }

    // ======== Getter Functions ========

    public fun package_id(type: &StructTag): ID {
        *&type.package_id
    }

    public fun module_name(type: &StructTag): String {
        *&type.module_name
    }

    public fun struct_name(type: &StructTag): String {
        *&type.struct_name
    }

    public fun generics(type: &StructTag): vector<String> {
        *&type.generics
    }

    // ======== Comparison ========

    public fun is_same_type(type1: &StructTag, type2: &StructTag): bool {
        (type1.package_id == type2.package_id
            && type1.module_name == type2.module_name
            && type1.struct_name == type2.struct_name
            && type1.generics == type2.generics)
    }

    // More relaxed comparison; if type1's generic is left undefined, then it's treated as *, meaning it
    // matches any value for type2's generics. This is NOT commutative; type2's generics being undefined
    // does not mean that it matches any value for type1.
    public fun match(type1: &StructTag, type2: &StructTag): bool {
        (type1.package_id == type2.package_id
            && type1.module_name == type2.module_name
            && type1.struct_name == type2.struct_name
            && (type1.struct_name == type2.struct_name || vector::length(&type1.generics) == 0))
    }

    public fun is_same_abstract_type(type1: &StructTag, type2: &StructTag): bool {
        (type1.package_id == type2.package_id
            && type1.module_name == type2.module_name
            && type1.struct_name == type2.struct_name)
    }

    public fun is_same_module(type1: &StructTag, type2: &StructTag): bool {
        (type1.package_id == type2.package_id
            && type1.module_name == type2.module_name)
    }

    // Uses a relaxed comparison that allows for * generics
    public fun contains(types: &vector<StructTag>, type: &StructTag): bool {
        let i = 0;
        while (i < vector::length(types)) {
            if (match(vector::borrow(types, i), type)) {
                return true
            };
            i = i + 1;
        };

        false
    }

    // Turns a StructTag back into its original String type name.
    public fun into_string(type: &StructTag): String {
        let result = string2::empty();

        string::append(&mut result, utf8(object::id_to_bytes(&type.package_id)));
        string::append(&mut result, utf8(b"::"));
        string::append(&mut result, type.module_name);
        string::append(&mut result, utf8(b"::"));
        string::append(&mut result, type.struct_name);

        if (vector::length(&type.generics) > 0) {
            string::append(&mut result, utf8(b"<"));

            let (i, first) = (0, true);
            while (i < vector::length(&type.generics)) {
                if (!first) {
                    string::append(&mut result, utf8(b", "));
                };
                string::append(&mut result, *vector::borrow(&type.generics, i));
                i = i + 1;
                first = false;
            };

            string::append(&mut result, utf8(b">"));
        };
        
        result
    }
}