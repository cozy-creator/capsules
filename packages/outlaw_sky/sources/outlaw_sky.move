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

    public fun craft_outlaw(attribute_stack: &mut vector<vector<vector<u8>>>, schema: &Schema, ctx: &mut TxContext) {
        let outlaw = Outlaw { id: object::new(ctx) };
        let owner = tx_context::sender(ctx);
        let attributes = vector::pop_back(attribute_stack);

        capsule::create_<Outlaw_Sky, Royalty_Market, Outlaw>(Outlaw_Sky {}, outlaw, attributes, owner, ctx);
    }

    public fun extend<T: store>(outlaw: &mut Outlaw): (&mut UID) {
        &mut outlaw.id
    }

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let boss_cap = boss_cap::create(&genesis, ctx);
        transfer::transfer(boss_cap, tx_context::sender(ctx));
    }
}