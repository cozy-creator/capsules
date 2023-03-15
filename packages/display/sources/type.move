// Sui's On-Chain Type Display Objects

// Type objects are root-level owned objects storing default display data for a given type.
// Rather than using devInspect transactions along with display::view(), the intention is that the Fullnodes
// will handle this all for clients behind the scenes.
//
// Type objects act as fallbacks when querying for the display-data of an object. For example, if you're creating
// a Capsule like 0x599::outlaw_sky::Outlaw, and you have a field on your display schema like 'created_by', which
// will be  identical for every object, it would be dumb to duplicate this field once for every object (10,000x times).
// Instead you can leave that field undefined, and define it once on Type<0x599::outlaw_sky::Outlaw>.

// The intent for display object is that they should be owned and maintained by the package-publisher, or frozen.

module display::type {
    use std::string::String;
    use std::option;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::typed_id;

    use sui_utils::encode;
    use sui_utils::struct_tag;

    use ownership::ownership;
    use ownership::tx_authority;

    use display::display;
    use display::schema::{Self, Schema, Field};
    use display::publish_receipt::{Self, PublishReceipt};

    friend display::abstract_type;

    // error enums
    const EINVALID_PUBLISH_RECEIPT: u64 = 0;
    const ETYPE_ALREADY_DEFINED: u64 = 1;
    const ETYPE_DOES_NOT_MATCH_UID_OBJECT: u64 = 2;
    const ETYPE_IS_NOT_CONCRETE: u64 = 3;
    const EKEY_UNDEFINED_IN_SCHEMA: u64 = 4;
    const EVEC_LENGTH_MISMATCH: u64 = 5;

    // ========= Concrete Type =========

    // Singleton, owned, root-level object. Cannot be destroyed. Unique on `T`.
    struct Type<phantom T> has key {
        id: UID,
        fields: vector<Field>
        // <display::Key { slot: String }> : <T: store> <- T conforms to the specified schema
    }

    // Added to publish receipt
    struct Key has store, copy, drop { slot: String } // slot is a type-name, value is boolean
    
    // Module authority
    struct Witness has drop { }

    // ========= Create Type Metadata =========

    // Convenience entry function
    public entry fun define<T>(
        publisher: &mut PublishReceipt,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        let type = define_<T>(publisher, data, fields, ctx);
        transfer::transfer(type, tx_context::sender(ctx));
    }

    // `T` must not contain any generics. If it does, you must first use `define_abstract()` to create
    // an AbstractType object, which is then used with `define_from_abstract()` to define a concrete type
    // per instance of its generics.
    //
    // The `fields` input to this function is work just like the inputs to a Schema, and are structured like:
    // [ [name, type, resolver], [name, type, resolver], ... ]
    // Resolvers can be skipped
    public fun define_<T>(
        publisher: &mut PublishReceipt,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        ctx: &mut TxContext
    ): Type<T> {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(publisher), EINVALID_PUBLISH_RECEIPT);
        assert!(!encode::has_generics<T>(), ETYPE_IS_NOT_CONCRETE);

        // Ensures that this concrete type can only ever be defined once
        let key = Key { slot: encode::module_and_struct_name<T>() };
        let uid = publish_receipt::extend(publisher);
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);

        dynamic_field::add(uid, key, true);

        define_internal<T>(data, resolvers, fields, ctx)
    }

    // This is used by abstract_type as well, to define concrete types from abstract types
    public(friend) fun define_internal<T>(
        data: vector<vector<u8>>,
        raw_fields: vector<vector<String>>,
        ctx: &mut TxContext
    ): Type<T> {
        let (resolvers, i) = (vec_map::empty(), 0);
        let fields = schema::from_fields(raw_fields);

        let type = Type {
            id: object::new(ctx),
            fields: schema::into_fields(schema),
        };
        let auth = tx_authority::begin_with_type(&Witness { });
        let typed_id = typed_id::new(&type);

        ownership::initialize_with_module_authority(&mut type.id, typed_id, &auth);
        display::attach_(&mut type.id, data, fields, &tx_authority::empty());
        ownership::as_owned_object(&mut type.id, &auth);

        type
    }

    // ====== Modify Schema and Resolvers ======
    
    // Combination of add and edit. If a key already exists, it will be overwritten, otherwise
    // it will be added.
    public entry fun set_fields<T>(
        self: &mut Type<T>,
        new_fields: vector<vector<String>>,
        data: vector<vector<u8>>,
    ) {
        let (len, i) = (vector::length(&new_fields), 0);

        while (i < len) {
            let (new_field, j) = (schema::new_field(vector::borrow(&new_fields, i)), 0);
            let (key, _, _, _) = schema::field_into_components(&new_field);
            let old_field = option::none<Field>();

            while (j < vector::length(&self.fields)) {
                if (schema::is_field_key(*vector::borrow(&self.fields, j), key)) {
                    old_field = option::some(*vector::borrow(&self.fields, j));
                    vector::borrow_mut(&mut self.fields, j) = new_field;
                    break
                };
                j = j + 1;
            };

            // Existing key not found
            if (j == vector::length(&self.fields)) {
                vector::push_back(&mut self.fields, new_field);
            };

            display::set_field_manually(
                &mut self.id, *vector::borrow(data, i), new_field, old_field, tx_authority::empty());

            i = i + 1;
        };
    }

    /// Remove keys from the Type Display.
    public entry fun remove_fields<T>(self: &mut Display<T>, keys: vector<String>) {
        let (len, i) = (vector::length(&keys), 0);

        while (i < len) {
            let key = vector::borrow(&keys, i);
            let j = 0;
            let old_field = option::none();

            while (j < vector::length(&self.fields)) {
                if (schema::is_field_key(*vector::borrow(&self.fields, j), key)) {
                    old_field = option::some(vector::remove(&mut self.fields, j));
                    break
                };
                j = j + 1;
            };

            if (option::is_some(old_field)) {
                display::remove_field_manually(
                    &mut self.id, option::destroy_some(old_field), tx_authority::empty());
            };

            i = i + 1;
        };
    }

    // ======== Accessor Functions =====

    public fun borrow_fields<T>(type: &Type<T>): &vector<Field> {
        &type.fields
    }

    // ======== View Functions =====

    // Type objects serve as convenient view-function fallbacks
    public fun view_with_default<T>(
        uid: &UID,
        fallback_type: &Type<T>,
        keys: vector<String>,
        schema: &Schema,
        fallback_schema: &Schema,
    ): vector<u8> {
        let object_type = option::destroy_some(ownership::get_type(uid));
        assert!(struct_tag::get<T>() == object_type, ETYPE_DOES_NOT_MATCH_UID_OBJECT);

        let fallbac_schema = 

        display::view_with_default(uid, &fallback_type.id, keys, schema, fallback_schema)
    }

    // ======== For Owners ========
    // Because Type lacks the `store` ability, polymorphic transfer and freeze do not work outside of this module

    public entry fun transfer<T>(type: Type<T>, new_owner: address) {
        transfer::transfer(type, new_owner);
    }

    // Makes the display immutable. This cannot be undone
    public entry fun freeze_<T>(type: Type<T>) {
        transfer::freeze_object(type);
    }

    // `Type` is an owned object, so there's no need for an ownership check
    public fun extend<T>(type: &mut Type<T>): &mut UID {
        &mut type.id
    }
}

#[test_only]
module display::type_tests {
    use std::string::{Self, String};
    use sui::test_scenario;
    use sui::transfer;
    use sui::tx_context;
    use type::type;
    use display::display;
    use display::publish_receipt;
    use display::schema;

    struct TEST_OTW has drop {}

    struct TestDisplay {}

    #[test]
    public fun test_define_type() {
        let sender = @0x123;

        let schema_fields = vector[ vector[ string::utf8(b"name"), string::utf8(b"String")], vector[ string::utf8(b"description"), string::utf8(b"Option<String>")], vector[ string::utf8(b"image"), string::utf8(b"String")], vector[ string::utf8(b"power_level"), string::utf8(b"u64")]];

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

            type::define<TestDisplay>(&mut publisher, data, &schema, ctx);

            test_scenario::return_immutable(schema);
            transfer::transfer(publisher, tx_context::sender(ctx));
        };

        test_scenario::next_tx(scenario, sender);
        {
            let type_object = test_scenario::take_from_address<type::Type<display::type_tests::TestDisplay>>(scenario, sender);

            let uid = type::extend(&mut type_object);

            let name = display::borrow<String>(uid, string::utf8(b"name"));
            assert!(*name == string::utf8(b"Outlaw"), 0);

            let power_level = display::borrow<u64>(uid, string::utf8(b"power_level"));
            assert!(*power_level == 199, 0);

            test_scenario::return_to_address(sender, type_object);
        };

        test_scenario::end(scenario_val);
    }
}