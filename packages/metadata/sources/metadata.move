// Sui's On-Chain TypeMetadata program

// The TypeMetadata object has a corresponding dynamic_field, into which the data is stored.
// Keys correspond to the StructName portion of a fully-qualified type-name: address::module_name::StructName
// StructNames need not exist; for example, the module 0x3::outlaw_sky need not define Outlaw;
// it can just be a virtual-type, that exists inside of noot.struct_name = Outlaw
// The module's one-time witness is the key for module as a whole. So for example, for TypeMetadata<SUI>,
// the key SUI is the metadata for the 0x2::sui module as a whole.

// The intent for metadata object is that they should be owned by the module-deployer, or frozen.
// Making a TypeMetadata object a naked shared-object would allow anyone to be able to mutate it (oh no lol).
// Client-apps will read from TypeMetadata using a devInspect transaction, not a regular transaction

// Data is keyed with type_name + data_name:
// `<package-id>::<module_name>::<struct_name> <package-id>::<module_name>::<struct_name>`

// This means that (1) metadata can define types that they do not own, and (2) metadata can hold multiple
// different data types for different types

module metadata::metadata {
    use std::string::{String, utf8};
    use sui::object::{Self, UID};
    use sui::types;
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::types::is_one_time_witness;
    use sui_utils::encode;

    const ENOT_OWNER: u64 = 0;
    const EMISMATCHED_MODULES: u64 = 1;
    const ENOT_ONE_TIME_WITNESS: u64 = 2;
    const ETYPE_METADATA_ALREADY_DEFINED: u64 = 3;
    const EINVALID_METADATA_CAP: u64 = 4;
    const EIMPROPERLY_SERIALIZED_BATCH_BYTES: u64 = 5;
    const ENO_PACKAGE_PERMISSION: u64 = 6;
    const EPACKAGE_ALREADY_REGISTERED: u64 = 7;
    const ENOT_CANNONICAL_BOSS_CAP: u64 = 8;

    // Shared object
    // Defines a type generally, like for all 0x59::outlaw_sky::Outlaw. Even if objects have their own metadata,
    // this acts as a fallback source for undefined metadata keys, so we don't have to duplicate metadata for
    // every individual object unless it's specific to that object
    struct TypeMetadata<phantom T> has key {
        id: UID,
        // <SchemaVersion { }> : ID
        // <Key { String }> : <T: store> <- T must conform to schema_version
    }

    struct Key has store, copy, drop { slot: String }
    struct SchemaVersion has store, copy, drop { }

    // ========= Create Metadata Objects =========

    public entry fun define_type<T>(boss_cap: &BossCap, schema: &Schema, ctx: &mut TxContext) {
        let package_id = encode::package_id<T>();
        assert!(boss_cap::is_valid(boss_cap, package_id), ENO_PACKAGE_PERMISSION);
        assert!(boss_cap::define_type<T>(boss_cap), ETYPE_METADATA_ALREADY_DEFINED);

        let id = object::new(ctx);
        dynamic_field::add(&mut id, SchemaVersion { }, object::id(schema));

        transfer::share_object(TypeMetadata<T> { id });
    }

    // ========= Entry Functions For Modifying Attributes =========

    public entry fun set_world_attribute() {
        
    }

    // ========= Modify Attributes =========

    public entry fun add_world_attribute<G: drop>(
        cap: &MetadataCap<G>,
        world: &mut WorldMetadata<G>,
        slot: String,
        bytes: vector<u8>
    ) {
        remove_world_attribute<G, Value>(cap, world, slot);
        dynamic_field::add(&mut world.id, Key { slot }, bytes);
    }

    public entry fun remove_world_attribute<G: drop>(
        _cap: &MetadataCap<G>,
        world: &mut WorldMetadata<G>,
        slot: String
    ) {
        if (dynamic_field::exists_(&world.id, Key { slot })) {
            dynamic_field::remove<Key, vector<u8>>(&mut world.id, Key { slot });
        };
    }

    public entry fun add_type_attribute<G: drop, T>(
        cap: &MetadataCap<G>,
        type: &mut TypeMetadata<T>,
        slot: String,
        bytes: vector<u8>
    ) {
        remove_type_attribute<G, T, Value>(cap, type, slot);
        dynamic_field::add(&mut type.id, Key { slot }, bytes);
    }

    public entry fun remove_type_attribute<G: drop, T>(
        _cap: &MetadataCap<G>,
        type: &mut TypeMetadata<T>,
        slot: String
    ) {
        assert!(is_valid(cap, type), EINVALID_METADATA_CAP);

        if (dynamic_field::exists_(&type.id, Key { slot })) {
            dynamic_field::remove<Key, vector<u8>>(&mut type.id, Key { slot });
        };dule_attribute
    }

    // ========= Batch-Add Attributes =========

    // Encoded as: [ key: String, value_type: vector<u8> ]
    // Unfortunately bcs does not support peeling strings, so we're just working with raw types
    public entry fun add_world_attributes<G: drop>(
        cap: &MetadataCap<G>,
        world: &mut WorldMetadata<G>,
        attribute_pairs: vector<vector<u8>>
    ) {
        let (i, length) = (0, vector::length(&attribute_pairs));
        assert!(length % 2 == 0, EIMPROPERLY_SERIALIZED_BATCH_BYTES);

        while (i < length) {
            let slot = utf8(*vector::borrow(&attribute_pairs, i));
            let bytes = *vector::borrow(&attribute_pairs, i + 1);
            add_world_attribute(cap, world, slot, bytes);
            i = i + 2;
        };
    }

    public entry fun add_type_attributes() {

    }

    // Requires module authority
    // Requires ownership authority if there is an owner
    public fun batch_add_attributes<World: drop>(
        witness: World,
        id: &mut UID,
        attributes: vector<vector<u8>>,
        schema: &Schema,
        ctx: &TxContext
    ): World {
        assert!(module_authority::is_valid<World>(id), ENO_MODULE_AUTHORITY);
        assert!(ownership::is_valid_owner(id, tx_context::sender(ctx)), ENOT_OWNER);

        let (i, length) = (0, vector::length(&attributes));
        assert!(length % 2 == 0, EIMPROPERLY_SERIALIZED_BATCH_BYTES);

        while (i < length) {
            let slot = utf8(*vector::borrow(&attributes, i));
            let bytes = *vector::borrow(&attributes, i + 1);
            dynamic_field::add(id, slot, bytes);
            i = i + 2;
        };

        witness
    }

    // ========= Make Metadata Immutable =========

    // Being able to freeze shared objects is currently being worked on; when it's available, freeze the module here along with
    // the metadata_cap being destroyed.
    public fun destroy_metadata_cap<G: drop>(metadata_cap: MetadataCap<G>) {
        let MetadataCap { id } = metadata_cap;
        object::delete(id);
    }

    // Not currently possible
    public fun freeze_world_metadata<G: drop>(cap: &MetadataCap<G>, world: WorldMetadata<G>) {
        transfer::freeze_object(world);
    }

    // Not currently possible
    public fun freeze_type<T>(cap: &MetadataCap<G>, type: TypeMetadata<T>) {
        assert!(is_valid(cap, type), EINVALID_METADATA_CAP);
        transfer::freeze_object(type);
    }

    // ============== View Functions for Client apps ============== 

    // Should we return the keys (query_slots) back along with the bytes?
    public fun get_world_attributes(world: &WorldMetadata, query_slots: vector<vector<u8>>): vector<vector<u8>> {
        let (i, response) = (0, vector::empty<vector<u8>>());

        while (i < vector::length(&query_slots)) {
            let slot = utf8(*vector::borrow(&query_slots, i));

            // We leave an empty vector of bytes if the slot does not have any value
            if (dynamic_field::exists_(&world.id, Key { slot })) {
                vector::push_back(&mut response, *dynamic_field::borrow<Key, vector<u8>>(&world.id, slot));
            } else {
                vector::push_back(&mut response, vector::empty<u8>());
            };
            i = i + 1;
        };

        response
    }

    public fun get_world_attribute<G>(world: &WorldMetadata<G>, slot_raw: vector<u8>): Option<vector<u8>> {
        let key = Key { slot: utf8(slot_raw) };
        if (!dynamic_field::exists_(&world.id, key)) { 
            return option::none()
        };
        
        option::some(*dynamic_field::borrow<Key, vector<u8>>(&world.id, key))
    }

    // [ (slot), (value), ]
    // 
    public entry fun add_attributes<Value: store + copy + drop>(
        schema: &MetadataSchema,
        slots: vector<vector<u8>>,
        bytes: vector<vector<u8>>
    ) {
        assert!(vector::length(&slots) == vector::length(&bytes), EKEY_VALUE_LENGTH_MISMATCH);

        // bools, address, ascii, utf8 strings, u8, u16, u32, u64, u128, u256, url, array<> for all of them
        if (utf8(b"0x2::string::String") == encode::type_name<Value>()) {
            let i = 0;
            while (i < vectr::length(&bytes)) {

            }
        } else if (u64) {

        };
    }

    public fun get_type_attribute<T>(type: &TypeMetadata<T>, slot_raw: vector<u8>): Option<vector<u8>> {
        let key = Key { slot: utf8(slot_raw) };
        if (!dynamic_field::exists_(&type.id, key)) { 
            return option::none() 
        };

        option::some(*dynamic_field::borrow<Key, vector<u8>>(&type.id, key))
    }

    // This first checks id for module_addr + data = Data. That is, a record stored on UID that
    // corresponds to module_addr G, with the corresponding Data type. If it's not found, it falls
    // back to using the TypeMetadata object for module G.
    public fun for_object<G, Data: store + copy + drop>(
        id: &UID,
        type_name: String,
        metadata: &TypeMetadata<G>
    ): Data {
        let (key, _) = encode::type_name_<G>();
        string::append(&mut key, encode::type_name<Data>());

        if (dynamic_field::exists_with_type<String, Data>(id, key)) {
            dynamic_field::borrow<String, Data>(id, key)
        } else {
            get_<G, Data>(metadata, type_name)
        }
    }

    public fun for_object_cannonical<G, Data: store + copy + drop>(
        id: &UID,
        type_name: String,
        metadata: &TypeMetadata<G>
    ): Data {
        let (module_addr1, _) = encode::type_name_<G>();
        let (module_addr2, _) = encode::decompose_type_name(type_name);
        assert!(module_addr1 == module_addr2, ENOT_CANONICAL_TYPE);

        for_object<G, Data>(id, type_name, metadata)
    }

    // ========= World Certification System =========

    // Should we allow certifications with object-ids, in addition to user addresses?
    public entry fun add_cert(world: &mut WorldMetadata, ctx: &mut TxContext) {
        let addr = tx_context::sender(ctx);

        if (!dynamic_field::exists_(&world.id, addr)) {
            dynamic_field::add(&mut world.id, addr, true);
        };
    }

    public entry fun revoke_cert(world: &mut WorldMetadata, ctx: &mut TxContext) {
        let addr = tx_context::sender(ctx);

        if (dynamic_field::exists_(&world.id, addr)) {
            dynamic_field::remove<address, bool>(&mut world.id, addr);
        };
    }

    // ========= Authority Checkers =========

    public fun is_valid<G: drop, T>(cap: &MetadataCap<G>, type: &TypeMetadata<T>): bool {
        let (module_addr, _) = encode::type_name_<G>();
        *type.module_authority == module_addr
    }

    public fun check_cert(world: &WorldMetadata, cert_addresses: vector<address>): bool {
        let i = 0;
        while (i < vector::length(&cert_addresses)) {
            if (dynamic_field::exists_with_type<address, bool>(&world.id, *vector::borrow(&cert_addresses, i))) {
                return true
            };
            i = i + 1;
        };

        false
    }

    // ========= Init =========
    
    fun init(ctx: &mut TxContext) {
        transfer::share_object(PackageRegistry { id: object::new(ctx) });
    }
}