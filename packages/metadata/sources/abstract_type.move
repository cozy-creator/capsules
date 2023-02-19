// Abstract types are metadata objects used to produce metadata objects for concrete types
// For example, `Coin<T>` is a single abstract type; `T` can be filled in to produce a boundless number
// of concrete types, such as: Coin<0x2::sui::SUI> and Coin<0xc0ffee::diem::DIEM>

module metadata::abstract_type {
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

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EINVALID_PUBLISH_RECEIPT: u64 = 1;
    const ETYPE_IS_NOT_ABSTRACT: u64 = 2;
    const ETYPE_ALREADY_DEFINED: u64 = 3;
    const EINCORRECT_SCHEMA_SUPPLIED: u64 = 4;

    // Singleton, shared root-level object. Cannot be destroyed. Unique on its `type` field.
    struct AbstractType has key {
        id: UID,
        type: StructTag
    }

    struct Key has store, copy, drop { slot: vector<String> }

    public entry fun define<T>(
        publisher: &mut PublishReceipt,
        owner: Option<address>,
        data: vector<vector<u8>>,
        schema: &Schema,
        ctx: &mut TxContext
    ) {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(publisher), EINVALID_PUBLISH_RECEIPT);
        assert!(encode::contains_generics<T>(), ETYPE_IS_NOT_ABSTRACT);

        let key = Key { slot: encode::module_and_struct_names<T>() };
        let uid = publish_receipt::extend(publisher);
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);

        dynamic_field::add(uid, key, true); 

        let owner = if (option::is_some(owner)) { option::destroy_some(owner) }
            else { tx_context::sender(ctx) };

        let abstract_type = AbstractType { id: uid, struct_tag: encode::abstract_struct_tag<T>() };
        let auth = tx_authority::begin_with_type(&Witness { });
        let proof = ownership::setup(&abstract_type);
        ownership::initialize_without_module_authority(&mut type.id, proof, &auth);
        metadata::attach(&mut type.id, data, schema, &tx_authority::empty());
        ownership::initialize_owner_and_transfer_authority<SimpleTransfer>(&mut abstract_type.id, owner, &auth);
        
        transfer::share_object(abstract_type);
    }

    // Convenience entry function
    public entry fun define_from_abstract<T>(
        abstract_type: &mut AbstractType,
        data: vector<vector<u8>>,
        schema: &Schema,
        ctx: &mut TxContext
    ) {
        let type = define_from_abstract_<T>(abstract_type, data, schema, &tx_authority::begin(ctx), ctx);
        transfer::transfer(type, tx_context::sender(ctx));
    }

    // Returns a concrete type based on an abstract type, like Type<Coin<0x2::sui::SUI>> from
    // AbstractType Coin<T>
    // The schema supplied will be used to define the concrete type's metadata, and must be the same 
    // schema as was used with the abstract type
    public fun define_from_abstract_<T>(
        abstract: &mut AbstractType,
        data: vector<vector<u8>>,
        schema: &Schema,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Type<T> {
        let struct_tag = struct_tag::create<T>();
        assert!(struct_tag::is_same_abstract_type(&abstract.type, &struct_tag), EABSTRACT_DOES_NOT_MATCH_CONCRETE);
        assert!(ownership::is_authorized_by_owner(&abstract.id, auth), ENO_OWNER_AUTHORITY);
        assert!(object::id(schema) == metadata::schema_id(&abstract.id), EINCORRECT_SCHEMA_SUPPLIED);

        // Ensures that this concrete type can only ever be created once
        let generics = encode::generics(&struct_tag);
        let key = Key { slot: generics };
        assert!(!dynamic_field::exists_(&abstract.id, key), ETYPE_ALREADY_DEFINED);

        dynamic_field::add(&mut abstract.id, key, true);

        type::define_internal<T>(data, schema, ctx)
    }

    // ======== Metadata Module's API =====
    // These can be removed once Sui supports programmable transactions that can return mutable references

    public entry fun update<T>(abstract_type: &mut AbstractType, keys: vector<ascii::String>, data: vector<vector<u8>>, schema: &Schema, overwrite_existing: bool, ctx: &mut TxContext) {
        metadata::update(&mut abstract_type.id, keys, data, schema, overwrite_existing, &tx_authority::begin(ctx));
    }

    public entry fun delete_optional<T>(abstract_type: &mut AbstractType, keys: vector<ascii::String>, schema: &Schema, ctx: &mut TxContext) {
        metadata::delete_optional(&mut abstract_type.id, keys, schema, &tx_authority::begin(ctx));
    }

    public entry fun delete_all<T>(abstract_type: &mut AbstractType, schema: &Schema, ctx: &mut TxContext) {
        metadata::delete_all(&mut abstract_type.id, schema, &tx_authority::begin(ctx));
    }

    public entry fun migrate<T>(
        abstract_type: &mut AbstractType,
        old_schema: &Schema,
        new_schema: &Schema,
        keys: vector<ascii::String>,
        data: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        metadata::migrate(&mut abstract_type.id, old_schema, new_schema, keys, data, &tx_authority::begin(ctx));
    }

    // ======== View Functions =====

    // AbstractType serves as a convenient metadata fallback
    public fun view_with_default<T>(
        uid: &UID,
        fallback_type: &AbstractType,
        keys: vector<ascii::String>,
        schema: &Schema,
        fallback_schema: &Schema,
    ): vector<u8> {
        let struct_tag = option::destroy_some(ownership::type(uid));
        assert!(struct_tag::is_same_abstract_type(&fallback_type.type, &struct_tag), EABSTRACT_DOES_NOT_MATCH_CONCRETE);

        metadata::view_with_default(uid, &fallback_type.id, keys, schema, fallback_schema)
    }

    // ======== For Owners ========

    // Public extend
    public fun extend<T: store>(abstract: &mut AbstractType, auth: &TxAuthority): (&mut UID) {
        assert!(ownership::is_authorized_by_owner(&abstract.id, auth), ENO_OWNER_AUTHORITY);

        &mut abstract.id
    }
}