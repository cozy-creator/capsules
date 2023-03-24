module transfer_system::exchange {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::pay;
    use sui::transfer;

    use transfer_system::royalty;
    // use transfer_system::simple_transfer;

    use ownership::ownership;
    use ownership::tx_authority;

    struct SellOffer<phantom T, phantom C> has key, store {
        id: UID,
        price: u64,
        item_id: ID,
        seller: address,
    }

    struct BuyOffer<phantom T, phantom C> has key, store {
        id: UID,
        buyer: address,
        offer: Balance<C>,
        item_id: Option<ID>,
    }

    struct Witness has drop {}

    const ENotItemOwner: u64 = 0;
    const EItemIdMismatch: u64 = 1;

    /// Creates a sell offer for an item of type `T`
    public fun create_sell_offer<T, C>(uid: &UID, price: u64, seller: Option<address>, ctx: &mut TxContext): SellOffer<T, C> {
        let seller = extract_sender(seller, ctx);
        create_sell_offer_(uid, seller, price, ctx)
    }

    public fun create_sell_offer_<T, C>(uid: &UID, seller: address, price: u64, ctx: &mut TxContext): SellOffer<T, C> {
        let auth = tx_authority::begin(ctx);
        let item_id = object::uid_to_inner(uid);

        assert!(ownership::is_authorized_by_owner(uid, &auth), ENotItemOwner);

        SellOffer { id: object::new(ctx), item_id, seller, price }
    }

    public fun fill_sell_offer<T, C>(uid: &mut UID, offer: &SellOffer<T, C>, coins: vector<Coin<C>>, ctx: &mut TxContext) {
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

        // TODO: transfer asset to buyer (tx sender)
    }

    /// Creates a buy offer for an item of type `T`
    public fun create_buy_offer<T, C>(
        item_id: Option<ID>, 
        price: u64, 
        buyer: Option<address>,
        coins: vector<Coin<C>>,
        ctx: &mut TxContext
    ): BuyOffer<T, C> {
        let buyer = extract_sender(buyer, ctx);
        create_buy_offer_(item_id, buyer, price, coins, ctx)
    }

    public fun create_buy_offer_<T, C>(
        item_id: Option<ID>, 
        buyer: address, 
        price: u64, 
        coins: vector<Coin<C>>, 
        ctx: &mut TxContext
    ): BuyOffer<T, C> {
        let coin = merge_coins(coins);
        let offer = coin::into_balance(coin::split(&mut coin, price, ctx));

        pay::keep(coin, ctx);

        BuyOffer { id: object::new(ctx), item_id, buyer, offer }
    }

    public fun fill_buy_offer<T, C>(uid: &mut UID, offer: &mut BuyOffer<T, C>, ctx: &mut TxContext) {
        let auth = tx_authority::begin(ctx);
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENotItemOwner);

        if(option::is_some(&offer.item_id)) {
            assert!(object::uid_as_inner(uid) == option::borrow(&offer.item_id), EItemIdMismatch)
        };

        let offer_value = balance::value(&offer.offer);
        let buy_coin = coin::from_balance(balance::split(&mut offer.offer, offer_value), ctx);

        // If object has royalty, collect and transfer the royalty value to the recipient
        if(royalty::has_royalty(uid)) {
            let royalty = royalty::borrow_royalty(uid);
            royalty::collect_from_coin(royalty, &mut buy_coin, ctx);
        };

        // TODO: add marketplace fee collection


        // Transfer the remaining buy coin to the seller (tx sender)
        pay::keep(buy_coin, ctx);

        // TODO: transfer asset to buyer (offer.buyer)
    }

    // ========== Helper functions =========

    fun extract_sender(seller: Option<address>, ctx: &TxContext): address {
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