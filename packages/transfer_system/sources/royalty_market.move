module transfer_system::royalty_market {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::pay;
    use sui::dynamic_object_field as dof;

    use ownership::ownership;
    use ownership::tx_authority;

    struct Royalty has key, store {
        id: UID,
        /// The royalty basis point
        royalty_bps: u16,
        /// The address where the royalty value should be sent to
        recipient: address
    }

    struct RoyaltyCap has key, store {
        id: UID,
        /// The ID of the royalty that this capability belongs to
        royalty_id: ID
    }

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

    struct Key has store, copy, drop {}

    struct Witness has drop {}


    // ========== Error constants==========

    const ENotItemOwner: u64 = 0;
    const ERoyaltyCapMismatch: u64 = 1;
    const ERoyaltyNotFound: u64 = 2;
    const EItemRoyaltyMismatch: u64 = 3;
    const EItemIdMismatch: u64 = 1;

    // ========== Other contants ==========

    const BASE_BPS: u16 = 10_000;


    /// Attaches the royalty (`Royalty`) to an object which uid (`UID`) is passed as a mutable reference.
    /// 
    /// - Aborts
    /// If a the object is not owned by the transaction sender.
    public fun attach(uid: &mut UID, royalty: Royalty, ctx: &mut TxContext) {
        let auth = tx_authority::begin(ctx);
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENotItemOwner);

        dof::add(uid, Key { }, royalty);
    }

    /// Detaches royalty that is attached to an object which uid (`UID`) is passed as a mutable reference.
    /// 
    /// - Aborts
    /// If royalty is not attached before.
    /// If royalty cap and the royalty do not matching IDs
    public fun detach(uid: &mut UID, royalty_cap: &RoyaltyCap): Royalty {
        assert!(owns_royalty(uid, royalty_cap.royalty_id), EItemRoyaltyMismatch);

        let royalty = dof::remove<Key, Royalty>(uid, Key { });
        assert!(royalty_cap.royalty_id == object::id(&royalty), ERoyaltyCapMismatch);

        royalty
    }

    /// Destroys a royalty object and it's royalty cap
    /// 
    /// - Aborts
    /// If royalty cap and the royalty do not matching IDs
    public fun destroy(royalty_cap: RoyaltyCap, royalty: Royalty) {
        assert!(royalty_cap.royalty_id == object::id(&royalty), ERoyaltyCapMismatch);

        let Royalty { id: royalty_id, royalty_bps: _, recipient: _ } = royalty;
        object::delete(royalty_id);

        // The `RoyaltyCap` should be deleted, since the `Royalty` it belongs to have been deleted
        let RoyaltyCap { id: cap_id, royalty_id: _ } = royalty_cap;
        object::delete(cap_id);
    }

    /// Creates a new royalty (`Royalty`) object and a royalty cap (`RoyaltyCap`) object
    public fun create_royalty_and_cap(royalty_bps: u16, recipient: address, ctx: &mut TxContext):  (Royalty, RoyaltyCap) {
         let royalty = create_royalty(royalty_bps, recipient, ctx);
         let royalty_cap = create_royalty_cap(&royalty, ctx);

         (royalty, royalty_cap)
    }


    /// Creates a new royalty (`Royalty`) object
    public fun create_royalty(royalty_bps: u16, recipient: address, ctx: &mut TxContext):  Royalty {
         Royalty {
            id: object::new(ctx),
            royalty_bps,
            recipient
        }
    }

    /// Creates a new royalty cap (`RoyaltyCap`) object
    public fun create_royalty_cap(royalty: &Royalty, ctx: &mut TxContext): RoyaltyCap {
        RoyaltyCap {
            id: object::new(ctx),
            royalty_id: object::id(royalty)
        }
    }

    /// Collects royalty value from balance `Balance` of type `C`
    /// It then converts it to a coin `Coin` of type `C` and transfers it to the royalty recipient
    public fun collect_from_balance<C>(royalty: &Royalty, source: &mut Balance<C>, ctx: &mut TxContext) {
        let value = balance::value(source);
        let royalty_value = calculate_royalty_value(royalty, value);
        let royalty_coin = coin::from_balance(balance::split(source, royalty_value), ctx);

        transfer::transfer(royalty_coin, royalty.recipient)
    }

    /// Collects royalty value from coin `Coin` of type `C` and transfers it to the royalty recipient
    public fun collect_from_coin<C>(royalty: &Royalty, source: &mut Coin<C>, ctx: &mut TxContext) {
        let value = coin::value(source);
        let royalty_value = calculate_royalty_value(royalty, value);
        let royalty_coin = coin::split(source, royalty_value, ctx);

        transfer::transfer(royalty_coin, royalty.recipient)
    }

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
        if(has_royalty(uid)) {
            let royalty = borrow_royalty(uid);
            collect_from_coin(royalty, &mut sell_coin, ctx);
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
        if(has_royalty(uid)) {
            let royalty = borrow_royalty(uid);
            collect_from_coin(royalty, &mut buy_coin, ctx);
        };

        // TODO: add marketplace fee collection


        // Transfer the remaining buy coin to the seller (tx sender)
        pay::keep(buy_coin, ctx);

        // TODO: transfer asset to buyer (offer.buyer)
    }


    // ==================== Getter function =====================

    public fun royalty_id(royalty: &Royalty): ID {
        object::id(royalty)
    }

    /// Returns whether an object which uid `UID` reference is passed owns the royalty whose id `ID` is passed
    public fun owns_royalty(uid: &UID, royalty_id: ID): bool {
        assert!(dof::exists_(uid, Key { }), ERoyaltyNotFound);

        let royalty = dof::borrow<Key, Royalty>(uid, Key { });
        object::id(royalty) == royalty_id
    }

    /// Returns whether an has royalty attached to it
    public fun has_royalty(uid: &UID): bool {
        dof::exists_(uid, Key { })
    }

    public fun borrow_royalty(uid: &UID): &Royalty {
        assert!(dof::exists_(uid, Key { }), ERoyaltyNotFound);
        dof::borrow<Key, Royalty>(uid, Key { })
    }

    // ==================== Helper functions ====================

    fun calculate_royalty_value(royalty: &Royalty, value: u64): u64 {
        let share = royalty.royalty_bps / BASE_BPS;
        value * (share as u64)
    }

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