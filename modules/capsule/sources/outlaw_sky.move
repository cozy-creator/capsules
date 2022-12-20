module cartridge::outlaw_sky {
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use cartridge::capsule;
    use cartridge::royalty_market::Royalty_Market;

    // Error constants
    const ENOT_OWNER: u64 = 0;

    // Genesis-witness and witness
    struct OUTLAW_SKY has drop {}
    struct Outlaw_Sky has drop {}

    struct Outlaw has key, store {
        id: UID
    }

    struct Metadata has store, drop {
        slot: String,
        value: vector<u8>
    }

    public fun craft_outlaw(ctx: &mut TxContext, metadata_list: &mut vector<Metadata>) {
        let outlaw = Outlaw { id: object::new(ctx) };
        let owner = tx_context::sender(ctx);

        let metadata = vector::pop_back(metadata_list);

        capsule::create_<Outlaw_Sky, Royalty_Market, Outlaw>(Outlaw_Sky {}, outlaw, metadata, owner, ctx);
    }

    public fun extend<T: store>(outlaw: &mut Outlaw): (&mut UID) {
        &mut outlaw.id
    }

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let metadata_cap = metadata::define_module(&genesis, ctx);

        transfer::transfer(metadata_cap, tx_context::sender(ctx));
    }
}