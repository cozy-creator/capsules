// Sui's On-Chain Type Metadata

// Type objects are root-level owned objects storing metadata.
// Clients can use devInspect transactions with the metadata::view() functions to learn more about the corresponding resource.
// Type objects can additionally be used as fallbacks when querying for data on object-instances. For example,
// if you're creating a Capsule like 0x599::outlaw_sky::Outlaw, and you have a metadata field like 'created_by', which is
// identical for every object, it would be useful to duplicate this field 10,000x times. Instead you can leave it undefined
// on the object itself, and define it once on Type<0x599::outlaw_sky::Outlaw>.

// The intent for metadata object is that they should be owned and maintained by the package-publisher, or frozen.

module metadata::type {
    use std::ascii;
    use std::option;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::transfer;
    use sui_utils::encode;
    use ownership::ownership;
    use ownership::tx_authority;
    use metadata::metadata;
    use metadata::schema::Schema;
    use metadata::publish_receipt::{Self, PublishReceipt};

    // error enums
    const EINVALID_PUBLISH_RECEIPT: u64 = 0;
    const ETYPE_ALREADY_DEFINED: u64 = 1;
    const ETYPE_METADATA_IS_INVALID_FALLBACK: u64 = 2;
    const EINCORRECT_TYPE_SPECIFIED_FOR_UID: u64 = 3;

    // Singleton, Owned root-level object. Cannot be destroyed.
    struct Type<phantom T> has key {
        id: UID,
        // <metadata::SchemaVersion { }> : ID
        // <metadata::Key { slot: ascii::String }> : <T: store> <- T conforms to the specified schema type
    }

    struct Key has store, copy, drop { slot: ascii::String } // slot is a type, value is boolean
    struct Witness has drop { }

    // ========= Create Type Metadata =========

    public entry fun define<T>(
        publisher: &mut PublishReceipt,
        data: vector<vector<u8>>,
        schema: &Schema,
        ctx: &mut TxContext
    ) {
        let type = define_<T>(publisher, data, schema, ctx);
        transfer::transfer(type, tx_context::sender(ctx));
    }

    public fun define_<T>(
        publisher: &mut PublishReceipt,
        data: vector<vector<u8>>,
        schema: &Schema,
        ctx: &mut TxContext
    ): Type<T> {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(publisher), EINVALID_PUBLISH_RECEIPT);

        let key = Key { slot: encode::module_and_struct_names<T>() };
        let uid = publish_receipt::extend(publisher);
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);

        dynamic_field::add(uid, key, true); 

        let type = Type { id: object::new(ctx) };
        let auth = tx_authority::begin_with_type(&Witness { });
        let proof = ownership::setup(&type);
        ownership::initialize_without_module_authority(&mut type.id, proof, &auth);
        metadata::attach(&mut type.id, data, schema, &tx_authority::empty());

        type
    }

    // ======== Metadata Module's API =====
    // For convenience, we replicate the Metadata Module's API here to make it easier to access Type's UID.
    // 
    // Once Sui Programmable transactions can support returning mutable references, we can remove these.
    // Otherwise without these, the app-developer could deploy their own custom module that calls into type::extend to get `&mut UID`
    // and then uses it in metadata::whatever(). (Sui doesn't support Diem-style scripts either.)

    public entry fun update<T>(type: &mut Type<T>, keys: vector<ascii::String>, data: vector<vector<u8>>, schema: &Schema, overwrite_existing: bool) {
        metadata::update(&mut type.id, keys, data, schema, overwrite_existing, &tx_authority::empty());
    }

    public entry fun delete_optional<T>(type: &mut Type<T>, keys: vector<ascii::String>, schema: &Schema) {
        metadata::delete_optional(&mut type.id, keys, schema, &tx_authority::empty());
    }

    public entry fun delete_all<T>(type: &mut Type<T>, schema: &Schema) {
        metadata::delete_all(&mut type.id, schema, &tx_authority::empty());
    }

    public entry fun migrate<T>(
        type: &mut Type<T>,
        old_schema: &Schema,
        new_schema: &Schema,
        keys: vector<ascii::String>,
        data: vector<vector<u8>>
    ) {
        metadata::migrate(&mut type.id, old_schema, new_schema, keys, data, &tx_authority::empty());
    }

    // ======== View Functions =====

    // Type serves as a convenient metadata fallback
    public fun view_with_default<T>(
        uid: &UID,
        fallback_type: &Type<T>,
        keys: vector<ascii::String>,
        schema: &Schema,
        fallback_schema: &Schema,
    ): vector<u8> {
        let object_type = option::destroy_some(ownership::type(uid));
        let generic_type = option::destroy_some(encode::type_of_generic<Type<T>>());
        assert!(object_type == generic_type, ETYPE_METADATA_IS_INVALID_FALLBACK);
        assert!(encode::type_name<T>() == object_type, EINCORRECT_TYPE_SPECIFIED_FOR_UID);

        metadata::view_with_default(uid, &fallback_type.id, keys, schema, fallback_schema)
    }

    // ======== For Owners =====

    // Makes the metadata immutable. This cannot be undone
    public entry fun freeze_<T>(type: Type<T>) {
        transfer::freeze_object(type);
    }

    // Because Type lacks `store`, polymorphic transfer does not work outside of this module
    public entry fun transfer<T>(type: Type<T>, new_owner: address) {
        transfer::transfer(type, new_owner);
    }

    // Owned object, so no need for an ownership check
    public fun extend<T>(type: &mut Type<T>): &mut UID {
        &mut type.id
    }
}

#[test_only]
module metadata::type_tests {
    use std::ascii;
    use std::string::{Self, String};
    use sui::test_scenario;
    use sui::transfer;
    use sui::tx_context;
    use metadata::type;
    use metadata::metadata;
    use metadata::publish_receipt;
    use metadata::schema;

    struct TEST_OTW has drop {}

    struct TestType {}

    #[test]
    public fun test_define_type() {
        let sender = @0x123;

        let schema_fields = vector[ vector[ ascii::string(b"name"), ascii::string(b"String")], vector[ ascii::string(b"description"), ascii::string(b"Option<String>")], vector[ ascii::string(b"image"), ascii::string(b"String")], vector[ ascii::string(b"power_level"), ascii::string(b"u64")]];

        let data = vector[ vector[6, 79, 117, 116, 108, 97, 119], vector[1, 35, 84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67], vector[34, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103], vector[199, 0, 0, 0, 0, 0, 0, 0] ];

        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            schema::create(schema_fields, ctx);
        };

        test_scenario::next_tx(scenario, sender);
        {
            let schema = test_scenario::take_immutable<schema::Schema>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let publisher = publish_receipt::test_claim(&TEST_OTW {}, ctx);

            type::define<TestType>(&mut publisher, data, &schema, ctx);

            test_scenario::return_immutable(schema);
            transfer::transfer(publisher, tx_context::sender(ctx));
        };

        test_scenario::next_tx(scenario, sender);
        {
            let type_object = test_scenario::take_from_address<type::Type<metadata::type_tests::TestType>>(scenario, sender);

            let uid = type::extend(&mut type_object);

            let name = metadata::borrow<String>(uid, ascii::string(b"name"));
            assert!(*name == string::utf8(b"Outlaw"), 0);

            let power_level = metadata::borrow<u64>(uid, ascii::string(b"power_level"));
            assert!(*power_level == 199, 0);

            test_scenario::return_to_address(sender, type_object);
        };

        test_scenario::end(scenario_val);
    }
}