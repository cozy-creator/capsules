module package::nft {
    use std::string::{Self, String};

    use sui::bcs;
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    struct NFT has key {
        id: UID,
        url: Url,
        name: String,
        description: String
    }

    public entry fun mint(
        // _idx: u64,
        item: vector<u8>,
        description: String,
        ctx: &mut TxContext
    ) {
        let bcs = bcs::new(item);
        let name = bcs::peel_vec_u8(&mut bcs);
        let url = bcs::peel_vec_u8(&mut bcs);

        let nft = NFT {
            id: object::new(ctx),
            name: string::utf8(name),
            url: url::new_unsafe_from_bytes(url),
            description,
        };

        transfer::transfer(nft, tx_context::sender(ctx))
    }
}