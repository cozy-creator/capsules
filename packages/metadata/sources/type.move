// Sui's On-Chain Type program

// The Type object has a corresponding dynamic_field, into which the data is stored.
// Keys correspond to the StructName portion of a fully-qualified type-name: address::module_name::StructName
// StructNames need not exist; for example, the module 0x3::outlaw_sky need not define Outlaw;
// it can just be a virtual-type, that exists inside of noot.struct_name = Outlaw
// The module's one-time witness is the key for module as a whole. So for example, for Type<SUI>,
// the key SUI is the metadata for the 0x2::sui module as a whole.

// The intent for metadata object is that they should be owned by the module-deployer, or frozen.
// Making a Type object a naked shared-object would allow anyone to be able to mutate it (oh no lol).
// Client-apps will read from Type using a devInspect transaction, not a regular transaction

// Data is keyed with type_name + data_name:
// `<package-id>::<module_name>::<struct_name> <package-id>::<module_name>::<struct_name>`

// This means that (1) metadata can define types that they do not own, and (2) metadata can hold multiple
// different data types for different types

module metadata::package {
    use std::string::{String, utf8};
    use sui::object::{Self, UID};
    use sui::types;
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::types::is_one_time_witness;
    use metadata::schema::Schema;
    use sui_utils::encode;

    const ETYPE_METADATA_ALREADY_DEFINED: u64 = 3;
    const EINVALID_METADATA_CAP: u64 = 4;
    const ENO_PACKAGE_PERMISSION: u64 = 6;

    // module witness
    struct PACKAGE has drop {};

    // Shared object
    // Defines a type generally, like for all 0x59::outlaw_sky::Outlaw. Even if objects have their own metadata,
    // this acts as a fallback source for undefined metadata keys, so we don't have to duplicate metadata for
    // every individual object unless it's specific to that object
    struct Type<phantom T> has key {
        id: UID,
        // <metadata::SchemaVersion { }> : ID
        // <metadata::Key { slot ascii::String }> : <T: store> <- where T is specified in the schema object
    }

    // ========= Create Type Metadata =========

    public fun define<T>(creator: &mut Creator, schema: &Schema, data: vector<vector<u8>>, creator_cap: &CreatorCap, ctx: &mut TxContext) {
        let uid = creator::extend(creator, auth);
        let auth = tx_authority::add_capability_id(creator_cap, tx_authority::begin(ctx));
        assert!(ownership::is_valid_owner(uid, auth), ENO_CREATOR_PERMISSION);

        let package_id = encode::package_id<T>();
        assert!(creator::contains_package(creator, package_id), EINCORRECT_CREATOR_FOR_TYPE);
        assert!(!creator::type_is_defined<T>(creator), ETYPE_METADATA_ALREADY_DEFINED);

        creator::add_type<T>(creator); // So we can't define Type<T> twice
        
        let type = Type<T> { id: object::new(ctx) };

        ownership::initialize(&mut type.id, &type, TYPE { }); // full control defaults to owner
        metadata::define_with_owner_as_editor(&mut type.id, schema, data, &auth); // who gets to edit it though?
        ownership::bind_transfer_authority_to_type<OwnerTransfer>(&mut type.id, &auth);

        // creator cap - but now we're stuck with it, cannot change it or migrate it
        // 

        // This doesn't need auth, because there is no metadata-editor or owner yet
        permissions::set_metadata_editor(&mut outlaw.id, &auth);

        ownership::bind_creator(&mut outlaw.id, &outlaw, creator);
        ownership::bind_transfer_authority_to_type<Royalty_Market>(&mut outlaw.id, &auth);
        metadata::define(&mut outlaw.id, schema, data, &auth);
        ownership::bind_owner(&mut outlaw.id, owner, &auth);






        metadata::define(&mut type.id, schema, data);
        
        transfer::share_object(type);
    }

    public entry fun define<T>(creator_cap: &CreatorCap, schema: &Schema, data: vector<vector<u8>>, ctx: &mut TxContext) {
        let package_id = encode::package_id<T>();
        assert!(boss_cap::is_valid(boss_cap, package_id), ENO_PACKAGE_PERMISSION);
        assert!(boss_cap::define_type<T>(boss_cap), ETYPE_METADATA_ALREADY_DEFINED);
        // Do they have authority to do this? 
        // Has this type already been defined?
        
        let type = Type<T> { id: object::new(ctx) };
        metadata::define(&mut type.id, schema, data);

        // set owner authority here
        transfer::share_object(type);
    }

    // ======== These are convenience wrappers to make it easier to access a type's UID =====

    public entry fun remove_optional<T>(type: &mut Type<T>) {

    }

    // Works if the updated value is already defined or undefined (optional)
    public entry fun update<T>(type: &mut Type<T>) {

    }

    // ========= Make Metadata Immutable =========

    // Being able to freeze shared objects is currently being worked on; when it's available, freeze the module here along with
    // the metadata_cap being destroyed.
    public fun destroy_metadata_cap<G: drop>(metadata_cap: MetadataCap<G>) {
        let MetadataCap { id } = metadata_cap;
        object::delete(id);
    }

    // Not currently possible
    public fun freeze_type<T>(cap: &MetadataCap<G>, type: Type<T>) {
        assert!(is_valid(cap, type), EINVALID_METADATA_CAP);
        transfer::freeze_object(type);
    }

    // ========= View Functions =========



    // ========= Authority Checker =========

    public fun is_valid<G: drop, T>(cap: &MetadataCap<G>, type: &Type<T>): bool {
        let (module_addr, _) = encode::type_name_<G>();
        *type.module_authority == module_addr
    }

    public fun extend<T>(type: &mut Type<T>): &mut UID {
        // add ownership check
        &mut type.id
    }
}