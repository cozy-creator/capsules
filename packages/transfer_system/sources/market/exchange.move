module transfer_system::exchange {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::Balance;
    use sui::coin::{Self, Coin};
    use sui::pay;
    use sui::transfer;

    use transfer_system::royalty;
    // use transfer_system::simple_transfer;

    use ownership::ownership;
    use ownership::tx_authority;

    struct SellOffer<phantom C> has key, store {
        id: UID,
        price: u64,
        item_id: ID,
        seller: address,
    }

    struct BuyOffer<phantom C> has key, store {
        id: UID,
        item_id: ID,
        buyer: address,
        offer: Balance<C>
    }

    struct Witness has drop {}

    const ENotItemOwner: u64 = 0;

    /// Creates a sell offer for an item with royalty
    public fun create_sell_offer<C>(uid: &UID, price: u64, seller: Option<address>, ctx: &mut TxContext): SellOffer<C> {
        let seller = extract_seller(seller, ctx);
        create_sell_offer_(uid, seller, price, ctx)
    }

    public fun create_sell_offer_<C>(uid: &UID, seller: address, price: u64, ctx: &mut TxContext): SellOffer<C> {
        let auth = tx_authority::begin(ctx);
        let item_id = object::uid_to_inner(uid);

        assert!(ownership::is_authorized_by_owner(uid, &auth), ENotItemOwner);

        SellOffer { id: object::new(ctx), item_id, seller, price }
    }

    public fun fill_sell_offer<C>(uid: &mut UID, offer: &SellOffer<C>, coins: vector<Coin<C>>, ctx: &mut TxContext) {
        let coin = merge_coins(coins);
        let sell_coin = coin::split(&mut coin, offer.price, ctx);

        // If object has royalty, collect and transfer the royalty value to the recipient
        if(royalty::has_royalty(uid)) {
            let royalty = royalty::borrow_royalty(uid);
            royalty::collect_from_coin(royalty, &mut sell_coin, ctx);
        };

        // TODO: add marketplace fee collection


        // Transfer the remaining sell coin to the seller
        transfer::transfer(sell_coin, offer.seller);

        // Keep the remainining original coin with the tx sender
        pay::keep(coin, ctx);
    }

    // ========== Helper functions =========

    fun extract_seller(seller: Option<address>, ctx: &TxContext): address {
        if(option::is_some(&seller)) {
            option::extract(&mut seller)
        } else {
            tx_context::sender(ctx)
        }
    }

    fun merge_coins<C>(coins: vector<Coin<C>>): Coin<C> {
        let coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut coin, coins);

        coin
    }
}