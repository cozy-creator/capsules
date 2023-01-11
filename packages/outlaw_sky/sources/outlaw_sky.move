module outlaw_sky::outlaw_sky {
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use capsule::capsule;
    use capsule::royalty_market::Royalty_Market;
    use metadata::boss_cap;
    use metadata::metadata;

    // Error constants
    const ENOT_OWNER: u64 = 0;

    // Genesis-witness and witness
    struct OUTLAW_SKY has drop {}
    struct Outlaw_Sky has drop {}

    struct Outlaw has key, store {
        id: UID,
        // <metadata> -> image
        // name -> owner can change arbitrarily using a custom-API (creator: witness)
        // level -> owner consent not needed (creator: object-ID, object-Type, shared-admin-list + address)
        // 
    }

    // Requires the 'creator' shared object
    public entry fun create(creator: &Creator, schema: &Schema, data: vector<vector<u8>>, ctx: &mut Txcontext) {
        let outlaw = Outlaw { id: object::new(ctx) };
        let owner = tx_context::sender(ctx);
        let auth = tx_authority::add_type(&Outlaw_Sky {}, &tx_authority::begin(ctx));

        ownership::initialize(&mut outlaw.id, &outlaw, Outlaw_Sky {});
        metadata::define(&mut outlaw.id, schema, data, &auth); // who gets to edit it though?
        ownership::bind_transfer_authority_to_type<Royalty_Market>(&mut outlaw.id, &auth);

        // This doesn't need auth, because there is no metadata-editor or owner yet
        permissions::set_metadata_editor(&mut outlaw.id, &auth);

        ownership::bind_creator(&mut outlaw.id, &outlaw, creator);
        ownership::bind_transfer_authority_to_type<Royalty_Market>(&mut outlaw.id, &auth);
        metadata::define(&mut outlaw.id, schema, data, &auth);
        ownership::bind_owner(&mut outlaw.id, owner, &auth);

        transfer::share_object(outlaw);
    }

    (uid: &mut UID, owner: address, auth: &TxAuthority)

    public fun craft_outlaw(attribute_stack: &mut vector<vector<vector<u8>>>, schema: &Schema, ctx: &mut TxContext) {
        let outlaw = Outlaw { id: object::new(ctx) };
        let owner = tx_context::sender(ctx);
        let attributes = vector::pop_back(attribute_stack);

        capsule::create_<Outlaw_Sky, Royalty_Market, Outlaw>(Outlaw_Sky {}, outlaw, attributes, owner, ctx);
    }

    public fun load_dispenser() {
        
    }

    // Public extend
    public fun extend<T: store>(outlaw: &mut Outlaw, ctx: &TxContext): (&mut UID) {
        assert!(ownership::is_valid(outlaw, ctx), ENOT_OWNER);

        &mut outlaw.id
    }

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let (receipt, genesis) = publish_receipt::claim(genesis, ctx);
        transfer::transfer(receipt, tx_context::sender(ctx));
    }
}