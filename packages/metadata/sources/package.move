module metadata::package {
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;

    use metadata::publish_receipt::PublishReceipt;
    use metadata::metadata;
    use metadata::schema::Schema;
    use metadata::creator::{Self, Creator};
    
    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::simple_transfer::Witness as SimpleTransferWitness;

    // Error enums
    const EBAD_WITNESS: u64 = 0;
    const ESENDER_UNAUTHORIZED: u64 = 1;

    struct Package has key, store {
        id: UID,
        receipt_id: ID
    }

    struct Witness has drop {}

    public entry fun create(creator: &mut Creator, receipt: &mut PublishReceipt, schema: &Schema, data: vector<vector<u8>>, ctx: &mut TxContext) {
        let package = Package { 
            id: object::new(ctx),
            receipt_id: object::id(receipt)
        };

        setup_ownership_and_metadata(&mut package, schema, data, ctx);
        creator::link_package(creator, receipt, ctx);

        transfer::share_object(package);
    }

    fun setup_ownership_and_metadata(package: &mut Package, schema: &Schema, data: vector<vector<u8>>, ctx: &mut TxContext) {
        let proof = ownership::setup(package);
        let auth = tx_authority::add_capability_type(&Witness { }, &tx_authority::begin(ctx));

        ownership::initialize(&mut package.id, proof, &auth);
        metadata::define(&mut package.id, schema, data, &auth);
        ownership::initialize_owner_and_transfer_authority<SimpleTransferWitness>(&mut package.id, tx_context::sender(ctx), &auth);
    }

    public fun extend(package: &mut Package, ctx: &mut TxContext): &mut UID {
        assert!(ownership::is_authorized_by_owner(&package.id, &tx_authority::begin(ctx)), ESENDER_UNAUTHORIZED);

        &mut package.id
    }
}