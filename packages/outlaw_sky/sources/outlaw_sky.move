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
        id: UID
    }

    // Requires the 'creator' shared object
    public entry fun create(creator: &Creator, ctx: &mut Txcontext) {
        let outlaw = Outlaw { id: object::new(ctx) };
        let owner = tx_context::sender(ctx);
        let auth = tx_authority::add_type(&Outlaw_Sky {}, &tx_authority::begin(ctx));

        ownership::bind_creator(&mut outlaw.id, &outlaw, creator);
        ownership::bind_transfer_authority_to_type<Royalty_Market>(&mut outlaw.id, creator, &auth);
        metadata::add_attributes(&mut outlaw.id, attributes, creator, auth);
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
    public fun extend<T: store>(outlaw: &mut Outlaw): (&mut UID) {
        &mut outlaw.id
    }

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let (receipt, genesis) = publisher_receipt::claim(genesis, ctx);
        transfer::transfer(receipt, tx_context::sender(ctx));
    }
}