// Abstract types are display objects used to produce display objects for concrete types
// For example, `Coin<T>` is a single abstract type; `T` can be filled in to produce a boundless number
// of concrete types, such as: Coin<0x2::sui::SUI> and Coin<0xc0ffee::diem::DIEM>

module display::abstract_type {
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::typed_id;

    use sui_utils::encode;
    use sui_utils::struct_tag::{Self, StructTag};

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use display::display;
    use display::publish_receipt::{Self, PublishReceipt};
    use display::schema::{Self, Schema};
    use display::type::{Self, Type};

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EINVALID_PUBLISH_RECEIPT: u64 = 1;
    const ETYPE_IS_NOT_ABSTRACT: u64 = 2;
    const ETYPE_ALREADY_DEFINED: u64 = 3;
    const EINCORRECT_SCHEMA_SUPPLIED: u64 = 4;
    const EINVALID_SCHEMA_ID: u64 = 5;
    const EABSTRACT_DOES_NOT_MATCH_CONCRETE: u64 = 6;

    // Singleton, shared root-level object. Cannot be destroyed. Unique on its `type` field.
    struct AbstractType has key {
        id: UID,
        type: StructTag,
        // These will be used as the default schema and display template when defining a concrete type based on
        // this abstract type
        fields: VecMap<String, Field>
    }

    // Added to publish receipt to ensure an abstract type is only defined once
    struct Key has store, copy, drop { slot: String }

    // Added to abstract-type to ensure that each concrete type (set of generics) is only ever defined once
    struct KeyGenerics has store, copy, drop { slot: vector<String> }

    // Module authority
    struct Witness has drop { }

    // When create an abstract type like `Coin<E>`, the `E` can be filled in as anything for the
    // type argument.
    // T must be abstract, in the sense that it has at least one generic
    public entry fun define<T>(
        publisher: &mut PublishReceipt,
        owner: Option<address>,
        data: vector<vector<u8>>,
        raw_fields: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        let abstract_type = define_<T>(publisher, data, raw_fields, ctx);
        return_and_share(abstract_type, owner, ctx);
    }

    public fun define_<T>(
        publisher: &mut PublishReceipt,
        data: vector<vector<u8>>,
        raw_fields: vector<vector<String>>,
        ctx: &mut TxContext
    ): AbstractType {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(publisher), EINVALID_PUBLISH_RECEIPT);
        assert!(encode::has_generics<T>(), ETYPE_IS_NOT_ABSTRACT);

        // Ensures that this abstract type can only ever be defined once
        let key = Key { slot: encode::module_and_struct_name<T>() };
        let uid = publish_receipt::extend(publisher);
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);
        dynamic_field::add(uid, key, true);

        let abstract_type = AbstractType { 
            id: object::new(ctx),
            type: struct_tag::get_abstract<T>(),
            fields: schema::fields_from_strings(raw_fields)
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

        ownership::as_shared_object<SimpleTransfer>(&mut abstract_type.id, vector[owner], &tx_authority::empty());

        transfer::share_object(abstract_type);
    }

    // Convenience entry function
    public entry fun define_from_abstract<T>(
        abstract_type: &mut AbstractType,
        data: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        let type = define_from_abstract_<T>(abstract_type, data, raw_fields, tx_authority::begin(ctx), ctx);
        type::transfer(type, tx_context::sender(ctx));
    }

    // Returns a concrete type based on an abstract type, like Type<Coin<0x2::sui::SUI>> from
    // AbstractType Coin<T>
    // The raw_fields supplied will be used as a Schema to define the concrete type's display, and must be the same 
    // schema specified in the abstract type's `schema_id` field
    public fun define_from_abstract_<T>(
        abstract: &mut AbstractType,
        data: vector<vector<u8>>,
        auth: TxAuthority,
        ctx: &mut TxContext
    ): Type<T> {
        assert!(ownership::is_authorized_by_owner(&abstract.id, auth), ENO_OWNER_AUTHORITY);
        let struct_tag = struct_tag::get<T>();
        assert!(struct_tag::is_same_abstract_type(&abstract.type, &struct_tag), EABSTRACT_DOES_NOT_MATCH_CONCRETE);

        // Ensures that this concrete type can only ever be created once
        let generics = struct_tag::generics(&struct_tag);
        let key = KeyGenerics { slot: generics };
        assert!(!dynamic_field::exists_(&abstract.id, key), ETYPE_ALREADY_DEFINED);
        dynamic_field::add(&mut abstract.id, key, true);

        type::define_internal<T>(data, abstract.fields, ctx)
    }

    // ====== Modify Schema and Resolvers ======
    // This is Abstract Type's own custom API for editing the display-data stored on the object.
    
    public entry fun set_field(
        self: &mut AbstractType,
        data: vector<vector<u8>>,
        raw_fields: vector<vector<String>>,
        auth: TxAuthority
    ) {
        assert!(ownership::is_authorized_by_owner(&self.id, &auth), ENO_OWNER_AUTHORITY);

        let (len, i) = (vector::length(&raw_fields), 0);

        while (i < len) {
            let (key, field) = schema::new_field(vector::borrow(&raw_fields, i));
            let index_maybe = schema::get_idx_opt(&self.fields, key);
            let old_field = if (option::is_some(&index_maybe)) {
                let (_, field_ref) = vec_map::get_entry_by_idx_mut(&self.fields, option::destroy_some(index_maybe));
                let old_field = option::some(*field_ref);
                field_ref = field;
                old_field
            } else {
                vec_map::insert(&mut self.fields, key, field);
                option::none()
            };

            display::set_field_manually(
                &mut self.id,
                key,
                *vector::borrow(data, i),
                field,
                old_field,
                tx_authority::begin_with_type(&Witness { })
            );

            i = i + 1;
        };
    }

    /// Remove keys from the Type object
    public entry fun remove_fields(self: &mut AbstractType, keys: vector<String>, auth: TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&self.id, &auth), ENO_OWNER_AUTHORITY);

        let (len, i) = (vector::length(&keys), 0);

        while (i < len) {
            let key = vector::borrow(&keys, i);
            let index_maybe = schema::get_idx_opt(&self.fields, key);
            if (option::is_some(&index_maybe)) {
                let (_, old_field) = vec_map::remove_entry_by_idx(
                    &mut self.fields,
                    option::destroy_some(index_maybe)
                );

                display::remove_field_manually(
                    &mut self.id,
                    key,
                    old_field,
                    tx_authority::begin_with_type(&Witness { })
                );
            };

            i = i + 1;
        };
    }

    // ======== Accessor Functions =====

    public fun borrow_fields(type: &AbstractType): &VecMap<String, Field> {
        &type.fields
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
        
        let fallback_schema = schema::create_from_fields(&fallback_type.fields);

        display::view_with_default(uid, &fallback_type.id, keys, schema, &fallback_schema)
    }

    // ======== For Owners ========

    public fun extend<T: store>(abstract: &mut AbstractType, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&abstract.id, auth), ENO_OWNER_AUTHORITY);

        &mut abstract.id
    }
}