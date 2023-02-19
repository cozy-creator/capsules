// Instead of storing type-name strings like "0x15::devnet_nft::NFT<0x99::outlaw::Outlaw>" we can instead
// parse them out into their 4 components and store them as a StructTag. This saves us the compute cost of
// having to re-parse them every time in future transactions.

module sui_utils::struct_tag {
    use std::ascii::String;

    // Error enums
    const ESUPPLIED_TYPE_CANNOT_BE_ABSTRACT: u64 = 0;

    struct StructTag has store, copy, drop {
        package_id: ID,
        module_name: String,
        struct_name: String,
        generics: vector<String>, // we have to use Strings rather than recursive StructTags
    }

    public fun create<T>(): StructTag {
        let (package_id, module_name, struct_name, generics) = type_name_decomposed<T>();

        StructTag { package_id, module_name, struct_name, generics }
    }

    // Same as above, except generics are stripped.
    // Aborts if generics are not present.
    public fun create_abstract<T>(): StructTag {
        let (package_id, module_name, struct_name, generics) = type_name_decomposed<T>();
        assert!(vector::length(&generics) > 0. ESUPPLIED_TYPE_CANNOT_BE_ABSTRACT);

        AbstractStructTag { package_id, module_name, struct_name, vector::empty<String>() }
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

    public fun is_same_abstract_type(type1: &StructTag, type2: &StructTag): bool {
        (type1.package_id == type2.package_id
            && type1.module_name == type2.module_name
            && type1.struct_name == type2.struct_name)
    }
}