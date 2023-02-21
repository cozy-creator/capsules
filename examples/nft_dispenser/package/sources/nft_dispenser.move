module nft_dispenser::nft_dispenser {
    use std::option;

    use sui::devnet_nft;
    use sui::tx_context::TxContext;
    use sui::sui::SUI;
    use sui::address;
    use sui::bcs;
    use sui::randomness::{Randomness};
    use sui::coin::{Coin};

    use dispenser::data_dispenser::{Self as dispenser, RANDOMNESS_WITNESS, DataDispenser};

    fun init(ctx: &mut TxContext) {
        // Our NFT schema - name: string, description: string, url: string
        let schema: vector<vector<u8>> = vector[b"String", b"String", b"String"];
        let admin = address::from_bytes(x"ed2c39b73e055240323cf806a7d8fe46ced1cabb");

        let dispenser = dispenser::initialize(option::some(admin), 1000, 5, false, option::some(schema), ctx);
        dispenser::publish(dispenser);
    }

    public entry fun load(dispenser: &mut DataDispenser, data: vector<vector<u8>>, ctx: &mut TxContext) {
        dispenser::load(dispenser, data, ctx);
    }

    public entry fun dispense(dispenser: &mut DataDispenser, randomness: &mut Randomness<RANDOMNESS_WITNESS>, coins: vector<Coin<SUI>>, signature: vector<u8>, ctx: &mut TxContext) {
        let data = dispenser::random_dispense(dispenser, randomness, coins, signature, ctx);
        let bcs = bcs::new(data);

        let name = bcs::peel_vec_u8(&mut bcs);
        let description = bcs::peel_vec_u8(&mut bcs);
        let url = bcs::peel_vec_u8(&mut bcs);

        devnet_nft::mint(name, description, url, ctx);
    }
}