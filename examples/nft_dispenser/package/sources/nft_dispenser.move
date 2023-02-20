module nft_dispenser::nft_dispenser {
    use std::option;

    use sui::devnet_nft;
    use sui::tx_context::TxContext;
    use sui::sui::SUI;
    use sui::address;
    use sui::bcs;
    use sui::coin::{Coin};

    use dispenser::dispenser::{Self, AdminCap, Dispenser};

    struct NFT_DISPENSER has drop {}

    fun init(w: NFT_DISPENSER, ctx: &mut TxContext) {
        // Our NFT schema - name: string, description: string, url: string
        let schema: vector<vector<u8>> = vector[b"String", b"String", b"String"];
        let admin = address::from_bytes(x"ed2c39b73e055240323cf806a7d8fe46ced1cabb");

        let dispenser = dispenser::initialize<NFT_DISPENSER>(w, option::some(admin), 1000, 5, true, option::some(schema), ctx);
        dispenser::publish(dispenser);
    }

    public entry fun load(dispenser: &mut Dispenser, admin_cap: &AdminCap, data: vector<vector<u8>>, ctx: &mut TxContext) {
        dispenser::load_data(dispenser, admin_cap, data, ctx);
    }

    public entry fun dispense(dispenser: &mut Dispenser, coins: vector<Coin<SUI>>, ctx: &mut TxContext) {
        let data = dispenser::dispense(dispenser, coins, ctx);
        let bcs = bcs::new(data);

        let name = bcs::peel_vec_u8(&mut bcs);
        let description = bcs::peel_vec_u8(&mut bcs);
        let url = bcs::peel_vec_u8(&mut bcs);

        devnet_nft::mint(name, description, url, ctx);
    }
}