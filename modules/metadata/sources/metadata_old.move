// Sui's On-Chain ModuleMetadata program

// The ModuleMetadata object has a corresponding dynamic_field, into which the data is stored.
// Keys correspond to the StructName portion of a fully-qualified type-name: address::module_name::StructName
// StructNames need not exist; for example, the module 0x3::outlaw_sky need not define Outlaw;
// it can just be a virtual-type, that exists inside of noot.struct_name = Outlaw
// The module's one-time witness is the key for module as a whole. So for example, for ModuleMetadata<SUI>,
// the key SUI is the metadata for the 0x2::sui module as a whole.

// The intent for metadata object is that they should be owned by the module-deployer, or frozen.
// Making a ModuleMetadata object a naked shared-object would allow anyone to be able to mutate it (oh no lol).
// Client-apps will read from ModuleMetadata using a devInspect transaction, not a regular transaction

// Data is keyed with type_name + data_name:
// `<package-id>::<module_name>::<struct_name> <package-id>::<module_name>::<struct_name>`

// This means that (1) metadata can define types that they do not own, and (2) metadata can hold multiple
// different data types for different types

module metadata::metadata {
    use std::string::String;
    use sui::object::{Self, UID};
    use sui::types;
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use utils::encode;
    use noot::noot::Link;

    const ENOT_OWNER: u64 = 0;
    const EBAD_WITNESS: u64 = 1;
    const ENOT_CANONICAL_TYPE: u64 = 2;
    const EDATA_TYPE_MISMATCH: u64 = 3;

    // GENESIS is a one-time witness
    // This has to be a shared object because view-functions can only use single-writer objects from
    // one account. We often use a fallback-pattern, in which querying metadata for a specific object
    // falls back to the defaults provided by that object's module's metadata
    struct ModuleMetadata<phantom GENESIS> has key, store {
        id: UID,
        owner: address,
        module_addr: String, // 0x59::module_name
        struct_names: vector<String> // vector of struct-names defined at module_addr
    }

    struct Key has store, copy, drop { struct_name: String }

    // ============== First-Party Functions ============== 

    // We use a reference to the witness, rather than its value, so that it can also be
    // used by other modules, such as sui::coin::create_currency. Unfortunately this
    // means this method can be called multiple times within the same init function, so we
    // cannot GUARANTEE that there is no other instance of this.
    // There is probably a better way to create Singleton objects than using a one-time-witness pattern
    public fun create<GENESIS: drop>(genesis: &GENESIS, ctx: &mut TxContext) {
        assert!(types::is_one_time_witness(genesis), EBAD_WITNESS);
        
        let (module_addr, _) = encode::type_name_<GENESIS>();

        let metadata = ModuleMetadata {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            module_addr
        };
        transfer::share_object(metadata);
    }

    public entry fun transfer<G: drop>(metadata: &mut ModuleMetadata<G>, new_addr: address, ctx: &mut TxContext) {
        assert!(is_owner(metadata, tx_context::sender(ctx)), ENOT_OWNER);

        metadata.owner = new_addr;
    }

    // This currently isn't possible; you cannot freeze shared objects. But this may work in the future
    // To freeze cannonical metadata, simply transfer to the 0x0 null address
    public entry fun freeze<G: drop>(metadata: ModuleMetadata<G>, ctx: &mut TxContext) {
        assert!(is_owner(&metadata, tx_context::sender(ctx)), ENOT_OWNER);

        transfer::freeze_object(metadata);
    }

    // ============== Add or Delete Types ==============

    // This adds an entry for the specified type, overwriting any pre-existing data
    // However, this does not change the Data's type, if one existed
    public entry fun add_type<GENESIS: drop, Type, Data: store + copy + drop>(
        metadata: &mut ModuleMetadata<GENESIS>,
        type_metadata: Data,
        ctx: &mut TxContext
    ) {
        remove_type<GENESIS, Type, Data>(metadata, ctx);

        dynamic_field::add(&mut metadata.id, into_key<Type>(), type_metadata);
    }

    // In the future, Sui will allow us to drop data generically without knowing the Data type
    // Here a data-type mismatch causes an abort
    public entry fun remove_type<GENESIS: drop, Type, Data: store + copy + drop>(
        metadata: &mut ModuleMetadata<GENESIS>,
        ctx: &mut TxContext
    ) {
        assert!(is_owner(metadata, tx_context::sender(ctx)), ENOT_OWNER);
        assert!(encode::is_same_module<GENESIS, Type>(), ENOT_CANONICAL_TYPE);

        let key = into_key<Type>();
        if (dynamic_field::exists_with_type<String, Data>(&metadata.id, key)) {
            dynamic_field::remove<String, Data>(&mut metadata.id, key);
        } else if (dynamic_field::exists_(&metadata.id, key)) {
            assert!(false, EDATA_TYPE_MISMATCH);
        };
    }

    // ============== Authority-Checking Functions ============== 

    public fun is_owner<G: drop>(metadata: &ModuleMetadata<G>, addr: address): bool {
        metadata.owner == addr
    }

    // ============== View Functions for Client apps ============== 

    // Returns the list of all types defined in this metadata object
    public fun get_types<G: drop>(metadata: &ModuleMetadata<G>): vector<String> {
        *metadata.struct_names
    }

    public fun get_type<G: drop, Type, Data: store + copy + drop>(metadata: &ModuleMetadata<G>): Data {
        *dynamic_field::borrow<Key, Data>(&metadata.id, into_key<Type>())
    }

    public fun get_type_<G: drop, Data: store + copy + drop>(metadata: &ModuleMetadata<G>, struct_name: String): Data {
        *dynamic_field::borrow<Key, Data>(&metadata.id, Key { struct_name })
    }

    // For the given type, it returns a list of available display shapes as a vector of types
    public fun get_data_shapes(type: String): vector<String> {
        vector::empty();
    }

    public fun get_canonical<G, Object, Data: store + copy + drop>(metadata: &ModuleMetadata<G>): Data {
        assert!(encode::is_same_module<G, Object>(), ENOT_CANONICAL_TYPE);

        get<G, Object, Data>(metadata)
    }

    public fun get<G, Object, Data: store + copy + drop>(metadata: &ModuleMetadata<G>): Data {
        let type_name = encode::type_name<Object>();
        get_(metadata, type_name)
    }

    public fun get_<G, Data: store + copy + drop>(metadata: &ModuleMetadata<G>, type_name: String): Data {
        let data_type = encode::type_name<Data>();
        string::append(&mut type_name, data_type);

        *dynamic_field::borrow(&metadata.id, type_name)
    }

    // This first checks id for module_addr + data = Data. That is, a record stored on UID that
    // corresponds to module_addr G, with the corresponding Data type. If it's not found, it falls
    // back to using the ModuleMetadata object for module G.
    public fun for_object<G, Data: store + copy + drop>(
        id: &UID,
        type_name: String,
        metadata: &ModuleMetadata<G>
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
        metadata: &ModuleMetadata<G>
    ): Data {
        let (module_addr1, _) = encode::type_name_<G>();
        let (module_addr2, _) = encode::decompose_type_name(type_name);
        assert!(module_addr1 == module_addr2, ENOT_CANONICAL_TYPE);

        for_object<G, Data>(id, type_name, metadata)
    }

    // ============== Internal Functions ============== 

    fun into_key<Type>(): Key {
        let (_, struct_name) = encode::type_name_<Type>();
        Key { struct_name }
    }
}