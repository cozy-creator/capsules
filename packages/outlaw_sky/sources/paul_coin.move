module outlaw_sky::paul_coin {
    use sui::coin;
    use sui::tx_context::{Self, TxContext};

    struct PAUL_COIN has drop {}

    struct TreasuryCapHolder has key {
        id: UID,
        cap: coin::TreasuryCap<PAUL_COIN>
    }

    public entry fun mint(cap_holder: &mut TreasuryCapHolder, amount: u64, ctx: &mut TxContext) {
        let coin = coin::mint(&mut cap_holder.cap, amount, ctx);
        let uid = coin::extend(&mut coin);

        metadata::add(uid, attributes)

        transfer::transfer(coin, tx_context::sender(ctx));
    }

    fun init(genesis: PAUL_COIN, ctx: &mut TxContext) {
        let (cap, metadata) = coin::create_currency(
            genesis, 2, b"Paul", b"PaulCoin", b"to the moooooon!", option::none(), ctx);

        transfer::share_object(TreasuryCapHolder {
            id: object::new(ctx),
            cap
        });

        transfer::transfer(metadata, tx_context::sender(ctx));
    }
}