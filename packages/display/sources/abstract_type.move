// Abstract types are display objects used to produce display objects for concrete types
// For example, `Coin<T>` is a single abstract type; `T` can be filled in to produce a boundless number
// of concrete types, such as: Coin<0x2::sui::SUI> and Coin<0xc0ffee::diem::DIEM>

module display::abstract_type {
    use std::string::String;
    use std::option::{Self, Option};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    use sui_utils::typed_id;
    use sui_utils::struct_tag::{Self, StructTag};

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use display::display;
    use display::publish_receipt::{Self, PublishReceipt};
    use display::schema::{Self, Schema, Field};

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EINVALID_PUBLISH_RECEIPT: u64 = 1;
    const ETYPE_IS_NOT_ABSTRACT: u64 = 2;
    const ETYPE_ALREADY_DEFINED: u64 = 3;
    const EINCORRECT_SCHEMA_SUPPLIED: u64 = 4;
    const EINVALID_SCHEMA_ID: u64 = 5;
    const EABSTRACT_DOES_NOT_MATCH_CONCRETE: u64 = 6;
    const EUNDEFINED_KEY: u64 = 7;

    // Singleton, shared root-level object. Cannot be destroyed. Unique on its `type` field.
    struct AbstractType has key {
        id: UID,
        type: StructTag,
        // These will be used as the default schema and display template when defining a concrete type based on
        // this abstract type
        resolvers: VecMap<String, String>,
        fields: VecMap<String, Field>,
    }

    // Added to publish receipt to ensure an abstract type is only defined once
    struct Key has store, copy, drop { slot: String }

    // Module authority
    struct Witness has drop { }

    // When create an abstract type like `Coin<E>`, the `E` can be filled in as anything for the
    // type argument.
    // T must be abstract, in the sense that it has at least one generic
    public entry fun define<T>(
        publisher: &mut PublishReceipt,
        owner: Option<address>,
        data: vector<vector<u8>>,
        resolver_strings: vector<vector<String>>,
        schema_fields: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        let abstract_type = define_<T>(publisher, data, resolver_strings, schema_fields, ctx);
        return_and_share(abstract_type, owner, ctx);
    }

    public fun define_<T>(
        publisher: &mut PublishReceipt,
        data: vector<vector<u8>>,
        resolver_strings: vector<vector<String>>,
        schema_fields: vector<vector<String>>,
        ctx: &mut TxContext
    ): AbstractType {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(publisher), EINVALID_PUBLISH_RECEIPT);
        assert!(encode::has_generics<T>(), ETYPE_IS_NOT_ABSTRACT);

        // Ensures that this abstract type can only ever be defined once
        let key = Key { slot: encode::module_and_struct_name<T>() };
        let uid = publish_receipt::extend(publisher);
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);
        dynamic_field::add(uid, key, true);

        let fields = schema::fields_from_strings(schema_fields);
        let resolvers = parse_resolvers(resolver_strings, &fields);

        let abstract_type = AbstractType { 
            id: object::new(ctx),
            type: struct_tag::get_abstract<T>(),
            resolvers,
            fields
        };
        let auth = tx_authority::begin_with_type(&Witness { });
        let typed_id = typed_id::new(&abstract_type);

        ownership::initialize_with_module_authority(&mut abstract_type.id, typed_id, &auth);
        display::attach_(&mut abstract_type.id, data, fields, &auth);

        abstract_type
    }

    public fun return_and_share(abstract_type: AbstractType, owner: Option<address>, ctx: &TxContext) {
        let owner = if (option::is_some(&owner)) { 
            option::destroy_some(owner) 
        } else { 
            tx_context::sender(ctx)
        };

        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<SimpleTransfer>(&mut abstract_type.id, vector[owner], &auth);

        transfer::share_object(abstract_type);
    }

    // ====== Modify Schema and Resolvers ======
    // This is Abstract Type's own custom API for editing the display-data stored on the object.

    public entry fun set_field(
        self: &mut AbstractType,
        data: vector<vector<u8>>,
        raw_fields: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        set_field_(self, data, raw_fields, &tx_authority::begin(ctx));
    }
    
    public fun set_field_(
        self: &mut AbstractType,
        data: vector<vector<u8>>,
        raw_fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), ENO_OWNER_AUTHORITY);

        let (len, i) = (vector::length(&raw_fields), 0);

        while (i < len) {
            let (key, field) = schema::create_field(vector::borrow(&raw_fields, i));
            let index_maybe = vec_map::get_idx_opt(&self.fields, &key);
            let old_field = if (option::is_some(&index_maybe)) {
                let (_, field_ref) = vec_map::get_entry_by_idx_mut(&mut self.fields, option::destroy_some(index_maybe));
                let old_field = option::some(*field_ref);
                *field_ref = field;
                old_field
            } else {
                vec_map::insert(&mut self.fields, key, field);
                option::none()
            };

            display::set_field_manually(
                &mut self.id,
                key,
                *vector::borrow(&data, i),
                field,
                old_field,
                &tx_authority::begin_with_type(&Witness { })
            );

            i = i + 1;
        };
    }

    public entry fun remove_fields(self: &mut AbstractType, keys: vector<String>, ctx: &mut TxContext) {
        remove_fields_(self, keys, &tx_authority::begin(ctx));
    }

    /// Remove keys from the Type object
    public fun remove_fields_(self: &mut AbstractType, keys: vector<String>, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), ENO_OWNER_AUTHORITY);

        let (len, i) = (vector::length(&keys), 0);

        while (i < len) {
            let key = vector::borrow(&keys, i);
            let index_maybe = vec_map::get_idx_opt(&self.fields, key);
            if (option::is_some(&index_maybe)) {
                let (_, old_field) = vec_map::remove_entry_by_idx(
                    &mut self.fields,
                    option::destroy_some(index_maybe)
                );

                display::remove_field_manually(
                    &mut self.id,
                    *key,
                    old_field,
                    &tx_authority::begin_with_type(&Witness { })
                );
            };

            i = i + 1;
        };
    }

    // ======== Helper Functions ======== 

    public fun parse_resolvers(
        resolver_strings: vector<vector<String>>,
        fields: &VecMap<String, Field>
    ): VecMap<String, String> {
        let (i, resolvers) = (0, vec_map::empty<String, String>());
        while (i < vector::length(&resolver_strings)) {
            let item = vector::borrow(&resolver_strings, i);
            let (key, resolver) = (vector::borrow(item, 0), vector::borrow(item, 1));
            assert!(vec_map::contains(fields, key), EUNDEFINED_KEY);

            vec_map::insert(&mut resolvers, *key, *resolver);
            i = i + 1;
        };

        resolvers
    }

    // ======== Accessor Functions =====

    public fun borrow_resolvers(type: &AbstractType): &VecMap<String, String> {
        &type.resolvers
    }

    public fun borrow_fields(type: &AbstractType): &VecMap<String, Field> {
        &type.fields
    }

    public fun into_struct_tag(type: &AbstractType): StructTag {
        type.type
    }

    // ======== View Functions =====

    // AbstractType serves as a convenient display fallback
    public fun view_with_default<T>(
        uid: &UID,
        fallback_type: &AbstractType,
        keys: vector<String>,
        schema: &Schema,
    ): vector<u8> {
        let struct_tag = option::destroy_some(ownership::get_type(uid));
        assert!(
            struct_tag::is_same_abstract_type(&fallback_type.type, &struct_tag),
            EABSTRACT_DOES_NOT_MATCH_CONCRETE);

        display::view_with_default(uid, &fallback_type.id, keys, schema)
    }

    // ======== For Owners ========

    public fun extend(abstract: &mut AbstractType, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&abstract.id, auth), ENO_OWNER_AUTHORITY);

        &mut abstract.id
    }
}