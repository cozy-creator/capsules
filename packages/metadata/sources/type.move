// Sui's On-Chain Type Metadata

// Type objects are root-level owned objects storing metadata.
// Clients can use devInspect transactions with the metadata::view() functions to learn more about the corresponding resource.
// Type objects can additionally be used as fallbacks when querying for data on object-instances. For example,
// if you're creating a Capsule like 0x599::outlaw_sky::Outlaw, and you have a metadata field like 'created_by', which is
// identical for every object, it would be useful to duplicate this field 10,000x times. Instead you can leave it undefined
// on the object itself, and define it once on Type<0x599::outlaw_sky::Outlaw>.

// The intent for metadata object is that they should be owned and maintained by the package-publisher, or frozen.

// To do: 
// authorize yourself to metadata

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

    // Singleton, root-level owned object
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
        schema: &Schema,
        data: vector<u8>,
        ctx: &mut TxContext
    ) {
        let type = define_<T>(publisher, schema, data, ctx);
        transfer::transfer(type, tx_context::sender(ctx));
    }

    public fun define_<T>(
        publisher: &mut PublishReceipt,
        schema: &Schema,
        data: vector<u8>,
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
        metadata::define(&mut type.id, schema, data, &tx_authority::empty());

        type
    }

    // ======== Metadata Module's API =====
    // For convenience, we replicate the Metadata Module's API here to make it easier to access Type's
    // UID, otherwise we would need Sui advanced-batch-transactions (not yet available), or the user would
    // need to deploy their own custom module  that combines type::extend to get `&mut UID` which can then be
    // pumped into metadata::whatever(). (Sui doesn't support Diem-style scripts either.)

    public entry fun overwrite<T>(type: &mut Type<T>, keys: vector<ascii::String>, data: vector<u8>, schema: &Schema, overwrite_existing: bool) {
        metadata::overwrite(&mut type.id, keys, data, schema, overwrite_existing, &tx_authority::empty());
    }

    public entry fun remove_optional<T>(type: &mut Type<T>, keys: vector<ascii::String>, schema: &Schema) {
        metadata::remove_optional(&mut type.id, keys, schema, &tx_authority::empty());
    }

    public entry fun remove_all<T>(type: &mut Type<T>, schema: &Schema) {
        metadata::remove_all(&mut type.id, schema, &tx_authority::empty());
    }

    public entry fun migrate<T>(
        type: &mut Type<T>,
        old_schema: &Schema,
        new_schema: &Schema,
        keys: vector<ascii::String>,
        data: vector<u8>
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
        let type = option::destroy_some(ownership::type(uid));
        let binding_type = option::destroy_some(encode::binding_type<Type<T>>());
        assert!(type == binding_type, ETYPE_METADATA_IS_INVALID_FALLBACK);
        assert!(encode::type_name<T>() == type, EINCORRECT_TYPE_SPECIFIED_FOR_UID);

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