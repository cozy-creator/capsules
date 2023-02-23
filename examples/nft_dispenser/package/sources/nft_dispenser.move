module nft_dispenser::nft_dispenser {
    use std::option;

    use sui::devnet_nft;
    use sui::tx_context::TxContext;
    use sui::address;
    use sui::bcs;
    use sui::sui::SUI;
    use sui::coin::Coin;
    use sui::randomness::{Randomness};

    use guard::guard::{Self, Guard};
    use guard::payment as payment_guard;

    use dispenser::dispenser::{Self as dispenser, RANDOMNESS_WITNESS, Dispenser};
    
    struct Witness has drop {}

    fun init(ctx: &mut TxContext) {
        // Our NFT schema - name: string, description: string, url: string
        let schema: vector<vector<u8>> = vector[b"String", b"String", b"String"];
        let admin = address::from_bytes(x"ed2c39b73e055240323cf806a7d8fe46ced1cabb");

        let dispenser = dispenser::initialize(option::some(admin), 5, false, option::some(schema), ctx);
        
        // initialize the guard
        let guard = guard::initialize(&Witness {}, ctx);

        // create the payment guard, amount: 10000 and the taker is the same as the admin
        payment_guard::create<Witness, SUI>(&mut guard, 10000, admin);
        guard::share_object(guard);
        dispenser::publish(dispenser);
    }

    public entry fun load(dispenser: &mut Dispenser, data: vector<vector<u8>>, ctx: &mut TxContext) {
        dispenser::load(dispenser, data, ctx);
    }

    public entry fun dispense(dispenser: &mut Dispenser, guard: &mut Guard<Witness>, coins: vector<Coin<SUI>>, randomness: &mut Randomness<RANDOMNESS_WITNESS>, signature: vector<u8>, ctx: &mut TxContext) {
        // validates the the incoming spayment
        payment_guard::validate<Witness, SUI>(guard, &coins);

        let data = dispenser::random_dispense(dispenser, randomness, signature, ctx);
        let bcs = bcs::new(data);

        let name = bcs::peel_vec_u8(&mut bcs);
        let description = bcs::peel_vec_u8(&mut bcs);
        let url = bcs::peel_vec_u8(&mut bcs);

        // collects the the incoming spayment
        payment_guard::collect<Witness, SUI>(guard, coins, ctx);
        devnet_nft::mint(name, description, url, ctx);
    }

    /// withdraws a specified amount from the collected payment
    public entry fun withdraw(guard: &mut Guard<Witness>, amount: u64, ctx: &mut TxContext) {
        // the payment guard already validates that the transaction sender is the same as the taker,
        // so we do not need to validate the sender here. 
        // However, in some other case we might want to do some other validation before proceeding.
        payment_guard::take<Witness, SUI>(guard, amount, ctx)
    }
}