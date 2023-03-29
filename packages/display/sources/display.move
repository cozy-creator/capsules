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

module display::display {
    use std::string::String;
    use std::option;
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::typed_id;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    use sui_utils::struct_tag;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use display::publish_receipt::{Self, PublishReceipt};
    use display::abstract_display::{Self, AbstractDisplay};

    use data::data;
    use data::schema::{Self, Schema, Field};

    // error enums
    const EINVALID_PUBLISH_RECEIPT: u64 = 0;
    const ETYPE_ALREADY_DEFINED: u64 = 1;
    const ETYPE_DOES_NOT_MATCH_UID_OBJECT: u64 = 2;
    const ETYPE_IS_NOT_CONCRETE: u64 = 3;
    const EKEY_UNDEFINED_IN_SCHEMA: u64 = 4;
    const EVEC_LENGTH_MISMATCH: u64 = 5;
    const ENO_OWNER_AUTHORITY: u64 = 6;
    const EABSTRACT_DOES_NOT_MATCH_CONCRETE: u64 = 7;

    // ========= Concrete Type =========

    // Owned, root-level object. Cannot be destroyed. Singleton, unique on `T`.
    struct Display<phantom T> has key {
        id: UID,
        resolvers: VecMap<String, vector<String>>
        // <data::Key { slot: String }> : <T: store>, data-fields owned by owner
    }

    // Added to publish receipt
    struct Key has store, copy, drop { slot: String } // slot is a type-name, value is boolean

    // Added to abstract-type to ensure that each concrete type (set of generics) can only ever be defined once
    struct KeyGenerics has store, copy, drop { slot: vector<String> }
    
    // Module authority
    struct Witness has drop { }

    // ========= Create Type Metadata =========

    // Convenience entry function
    public entry fun create<T>(
        publisher: &mut PublishReceipt,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        let display = create_<T>(publisher, keys, resolver_strings, ctx);
        transfer::transfer(type, tx_context::sender(ctx));
    }

    // `T` must not contain any generics. If it does, you must first use `define_abstract()` to create
    // an AbstractDisplay object, which is then used with `define_from_abstract()` to define a concrete type
    // per instance of its generics.
    //
    // The `resolver_strings` input to this function is work just like the inputs to a Schema, and look like:
    // [ [type, resolver-1, resolver-2], [type, resolver-1], ... ]
    //
    // Resolvers can be left undefined, which means that it resolves to object.key; for example, if the key is
    // `name` then we it will just return `object.name`.
    //
    // Multiple resolvers can be defined per key, and they will be tried in order until one returns a value.
    public fun create_<T>(
        publisher: &mut PublishReceipt,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>,
        ctx: &mut TxContext
    ): Display<T> {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(publisher), EINVALID_PUBLISH_RECEIPT);
        assert!(!encode::has_generics<T>(), ETYPE_IS_NOT_CONCRETE);
        assert!(vector::length(&keys) == vector::length(&resolver_strings), EVEC_LENGTH_MISMATCH);

        // Ensures that this concrete type can only ever be defined once
        let key = Key { slot: encode::module_and_struct_name<T>() };
        let uid = publish_receipt::extend(publisher);
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);

        dynamic_field::add(uid, key, true);

        let (i, resolvers) = (0, vec_map::empty());
        while (i < vector::length(&keys)) {
            vec_map::insert(&mut resolvers, *vector::borrow(key, i), *vector::borrow(&resolver_strings, i));
            i = i + 1;
        };

        define_internal<T>(resolvers, ctx)
    }

    // Convenience entry function
    public entry fun define_from_abstract<T>(
        abstract_display: &mut AbstractDisplay,
        data: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        let display = define_from_abstract_<T>(abstract_type, data, &tx_authority::begin(ctx), ctx);
        transfer(type, tx_context::sender(ctx));
    }

    // Returns a concrete type based on an abstract type, like Type<Coin<0x2::sui::SUI>> from
    // AbstractDisplay Coin<T>
    // The raw_fields supplied will be used as a Schema to define the concrete type's display, and must be the same 
    // schema specified in the abstract type's `schema_id` field
    public fun define_from_abstract_<T>(
        abstract: &mut AbstractDisplay,
        data: vector<vector<u8>>,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Display<T> {
        let struct_tag = struct_tag::get<T>();
        assert!(struct_tag::is_same_abstract_type(
            &abstract_type::into_struct_tag(abstract), &struct_tag), EABSTRACT_DOES_NOT_MATCH_CONCRETE);

        // We use the existing resolvers and fields from the abstract type
        let resolvers = *abstract_type::borrow_resolvers(abstract);

        // The owner of the abstract type must authorize this action
        let uid = abstract_type::uid_mut(abstract, auth);
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        // Ensures that this concrete type can only ever be created once
        let generics = struct_tag::generics(&struct_tag);
        let key = KeyGenerics { slot: generics };
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);

        dynamic_field::add(uid, key, true);

        // We use the abstract type's existing data as default data for the concrete type's data,
        // assuming we haven't been supplied any data
        if (vector::length(&data) == 0) {
            data = data::view_parsed(uid, vec_map::keys(&fields), &fields);
        };

        define_internal<T>(resolvers, ctx)
    }

    // This is used by abstract_type as well, to define concrete types from abstract types
    fun define_internal<T>(
        resolvers: VecMap<String, vector<String>>,
        ctx: &mut TxContext
    ): Display<T> {
        let display = Display {
            id: object::new(ctx),
            resolvers
        };

        let auth = tx_authority::begin_with_type(&Witness { });
        let typed_id = typed_id::new(&type);

        ownership::initialize_without_module_authority(&mut type.id, typed_id, &auth);
        // data::attach_(&mut type.id, data, fields, &auth);
        ownership::as_owned_object(&mut type.id, &auth);

        display
    }

    // ====== Modify Schema and Resolvers ======
    // This is Type's own custom API for editing the display-data stored on the Type object.
    
    // Combination of add and edit. If a key already exists, it will be overwritten, otherwise
    // it will be added.
    public entry fun set_resolvers<T>(
        self: &mut Display<T>,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>,
    ) {
        let (len, i) = (vector::length(&keys), 0);
        assert!(len == vector::length(&resolver_strings), EVEC_LENGTH_MISMATCH);

        while (i < len) {
            let key = *vector::borrow(&keys, i);
            let value = *vector::borrow(&resolver_strings, i);

            if (vec_map::contains(&self.resolvers, &key)) {
                *vec_map::get_mut(&mut self.resolvers, &key) = value;
            } else {
                vec_map::insert(&mut self.resolvers, key, value);
            };

            i = i + 1;
        };
    }

    /// Remove keys from the Type object
    public entry fun remove_fields<T>(self: &mut Display<T>, keys: vector<String>) {
        let (len, i) = (vector::length(&keys), 0);

        while (i < len) {
            let index_maybe = vec_map::get_idx_opt(&self.resolvers, vector::borrow(&keys, i));

            if (option::is_some(&index_maybe)) {
                vec_map::remove_entry_by_idx(&mut self.resolvers, option::destroy_some(index_maybe));
            };

            i = i + 1;
        };
    }

    // ======== Accessor Functions =====

    public fun borrow_resolvers<T>(self: &Display<T>): &VecMap<String, vector<String>> {
        &self.resolvers
    }

    public fun borrow_mut_resolvers<T>(self: &mut Display<T>): &mut VecMap<String, vector<String>> {
        &mut self.resolvers
    }

    // ======== View Functions =====

    // Type objects serve as convenient view-function fallbacks
    public fun view_with_default<T>(
        uid: &UID,
        fallback_type: &Display<T>,
        keys: vector<String>,
        schema: &Schema
    ): vector<u8> {
        let object_type = option::destroy_some(ownership::get_type(uid));
        assert!(struct_tag::get<T>() == object_type, ETYPE_DOES_NOT_MATCH_UID_OBJECT);

        display::view_with_default(uid, &fallback_type.id, keys, schema)
    }

    // ======== For Owners ========
    // Because Type lacks the `store` ability, polymorphic transfer and freeze do not work outside of this module

    public entry fun transfer<T>(self: Display<T>, new_owner: address) {
        transfer::transfer(self, new_owner);
    }

    // Makes the display immutable. This cannot be undone
    public entry fun freeze_<T>(self: Display<T>) {
        transfer::freeze_object(self);
    }

    public fun uid<T>(self: &Display<T>): &UID {
        &self.id
    }

    // `Type` is an owned object, so there's no need for an ownership check
    public fun uid_mut<T>(type: &mut Display<T>): &mut UID {
        &mut type.id
    }
}

#[test_only]
module display::type_tests {
    use std::string::{Self, String};
    use sui::test_scenario;
    use sui::transfer;
    use sui::tx_context;
    use display::display;
    use display::publish_receipt;

    use data::data;
    use data::schema;

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

            type::define<TestDisplay>(&mut publisher, data, vector<vector<String>>[], schema_fields, ctx);

            test_scenario::return_immutable(schema);
            transfer::transfer(publisher, tx_context::sender(ctx));
        };

        test_scenario::next_tx(scenario, sender);
        {
            let type_object = test_scenario::take_from_address<type::Type<display::type_tests::TestDisplay>>(scenario, sender);

            let uid = type::extend(&mut type_object);

            let name = data::borrow<String>(uid, string::utf8(b"name"));
            assert!(*name == string::utf8(b"Outlaw"), 0);

            let power_level = data::borrow<u64>(uid, string::utf8(b"power_level"));
            assert!(*power_level == 199, 0);

            test_scenario::return_to_address(sender, type_object);
        };

        test_scenario::end(scenario_val);
    }
}