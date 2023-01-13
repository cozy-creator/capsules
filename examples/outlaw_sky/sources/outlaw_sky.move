module outlaw_sky::outlaw_sky {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use metadata::metadata;
    use metadata::schema::Schema;
    use metadata::publish_receipt;
    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    // Error constants
    const ENOT_OWNER: u64 = 0;

    // Genesis-witness and witness
    struct OUTLAW_SKY has drop {}
    struct Witness has drop { }

    struct Outlaw has key, store {
        id: UID,
        // <metadata> -> image
        // name -> owner can change arbitrarily using a custom-API
        //    (module_authority: witness)
        // level -> owner consent not needed, module can alter it arbitrarily
        //    (module_authority: object-ID, object-Type, shared-admin-list + address)
        // 
    }

    public fun create(schema: &Schema, data: vector<vector<u8>>, ctx: &mut TxContext) {
        let outlaw = Outlaw { id: object::new(ctx) };
        let owner = tx_context::sender(ctx);
        let auth = tx_authority::add_capability_type(&Witness {}, &tx_authority::begin(ctx));
        let proof = ownership::setup(&outlaw);

        ownership::initialize(&mut outlaw.id, proof, &auth);
        metadata::define(&mut outlaw.id, schema, data, &auth);
        ownership::initialize_owner_and_transfer_authority<SimpleTransfer>(&mut outlaw.id, owner, &auth);
        transfer::share_object(outlaw);
    }

    public fun load_dispenser() {
        
    }

    // Public extend
    public fun extend<T: store>(outlaw: &mut Outlaw, auth: &TxAuthority): (&mut UID) {
        assert!(ownership::is_authorized_by_owner(&outlaw.id, auth), ENOT_OWNER);

        &mut outlaw.id
    }

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&genesis, ctx);
        transfer::transfer(receipt, tx_context::sender(ctx));
    }
}