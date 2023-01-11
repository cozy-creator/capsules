module metadata::creator {
    use std::string::String;
    use sui::object::UID;
    use sui_utils::df_set;
    use ownership::ownership;
    use transfer_systems::self::Self;
    use metadata::publish_receipt;

    // error constants
    const EPACKAGE_ALREADY_REGISTERED: u64 = 0;

    // Shared object. Used as an index for easy lookup of creator objects given a package-id, and to prevent duplicate creators
    struct Registry has key {
        id: UID,
        // <ID> : ID <- maps a package-ID to the corresponding creator-object ID
    }

    // shared object
    struct Creator has key {
        id: UID,
        packages: vector<ID>,
        authorities: vector<address>,
        // <ownership::Key { OWNER }> : address <- ID of a CreatorCap with ownership rights
        // <ownership::Key { TRANSFER }> : address <- hashed witness type of Self-transfer module
        // <ownership::Key { CREATOR_ID }> : @0x0
        // <metadata::SchemaVersion { }> : ID
        // <metadata::Key { slot: ascii::String }> : <T: store> <- T must conform to schema_version
    }

    // Authority object, grants edit access to the corresponding creator object. Store safely in a multi-sig wallet
    struct CreatorCap has key, store {
        id: UID
    }

    // Create a new Creator object with a new publisher-receipt
    public entry fun create(publisher: &PublishReceipt, registry: &mut Registry, ctx: &mut TxContext) {
        let creator_cap = create_(publisher, registry, ctx);
        transfer::transfer(creator_cap, tx_context::sender(ctx));
    }
    
    public fun create_(publisher: &PublishReceipt, registry: &mut Registry, ctx: &mut TxContext): CreatorCap {
        let package = publisher::package(publisher);
        assert!(!dynamic_field::exists_(&registry.id, package), EPACKAGE_ALREADY_REGISTERED);

        let creator_cap = CreatorCap {
            id: object::new(ctx),
        };

        let creator = Creator {
            id: object::new(ctx),
            packages: vector[package]
        };
        dynamic_field::add(&mut registry.id, package, object::id(&creator));

        let id_bytes = object::id_bytes(&creator_cap);

        ownership::bind_creator_(&mut creator.id, id_bytes);
        ownership::bind_transfer_witness<Self>(&mut creator.id, id_bytes);
        ownership::bind_owner_(&mut creator.id, id_bytes, &creator_cap);

        transfer::share_object(creator);
        creator_cap
    }

    // Add to an existing Creator object with a new publisher-receipt
    public entry fun add_package(cap: &CreatorCap, creator: &mut Creator, publisher: &PublishReceipt, registry: &mut Registry) {
        let package = publisher::package(publisher);
        assert!(!dynamic_field::exists_(&registry.id, package), EPACKAGE_ALREADY_REGISTERED);
        assert!(ownership::is_valid_(&creator.id, cap), ENO_OWNERSHIP_AUTHORITY);

        add_package_internal(creator, publisher::into_package_id(publisher), registry);
    }

    // Merge two existing Creator objects together. Creator2 will be destroyed and subsumed by Creator1
    // This will work once Sui enables destructing shared objects (creator2)
    public entry fun join(cap1: &mut CreatorCap, creator1: &mut Creator, cap2: CreatorCap, creator2: Creator, registry: &mut Registry) {
        assert!(ownership::is_valid_(&creator1.id, cap1), ENO_OWNERSHIP_AUTHORITY);
        assert!(ownership::is_valid_(&creator2.id, &cap2), ENO_OWNERSHIP_AUTHORITY);

        let CreatorCap { id } = cap2;
        object::delete(id);

        let Creator { id, packages } = creator2;
        object::delete(id);

        let creator1_id = object::id(creator1);

        let i = 0;
        while (i < vector::length(&packages)) {
            add_package_internal(creator1, *vector::borrow(&packages, i), registry);
            i = i + 1;
        };
    }

    // Helper function
    fun add_package_internal(creator: &mut Creator, package_id: ID, registry: &mut Registry) {
        // It shouldn't be possible to have overlapping package-ids, but we check just in case
        if (!has_package(creator, package_id)) {
            vector::push_back(&mut creator.packages, package_id);
        };

        df_set::set(&mut registry.id, package_id, object::id(creator));
    }

    public fun extend(creator: &mut Creator, cap: &CreatorCap): &mut ID {
        let auth = tx_authority::add_object(cap, tx_authority::begin_());
        assert!(ownership::is_authorized_by_owner(&creator.id, auth), ENO_OWNERSHIP_AUTHORITY);

        &mut creator.id
    }

    public fun owner(creator: &Creator): address {
        ownership::owner(&creator.id)
    }
    
    public fun authorities(creator: &Creator): vector<address> {
        *&creator.authorities
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

    // ========== Validity Checker ========== 

    public fun has_package(creator: &Creator, package_id: ID): bool {
        vector::contains(&creator.packages, &package_id)
    }

    // Create the registry on deploy
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Registry { id: object::new(ctx) });
    }
}