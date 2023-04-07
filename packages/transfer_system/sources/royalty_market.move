module transfer_system::royalty_market {
    use std::option::{Self, Option};
    use std::type_name::{Self, TypeName};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use sui::event::emit;
    use sui::transfer;
    use sui::pay;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use ownership::publish_receipt::{Self, PublishReceipt};

    use sui_utils::encode;
    use sui_utils::struct_tag;

    use transfer_system::market_account::{Self, MarketAccount};


    struct Witness has drop {}

    struct Royalty<phantom T> has key, store {
        id: UID,
        config: RoyaltyConfig
    }

    struct RoyaltyConfig has store, copy, drop {
        royalty_bps: u16,
        recipient: address,
        marketplace_fee_bps: u16
    }

    struct Offer<phantom T, phantom C> has store, drop {
        price: u64,
        user: address,
        creator_royalty: u64
    }


    // ========== Dynamic fields key structs ==========

    /// Key used to store a buy or sell offer for an item
    struct Key has store, copy, drop { type: u8, user: Option<address> }


    // ========== Event structs ==========

    struct OfferCreated has copy, drop {
        price: u64,
        user: address,
        item_id: ID,
        coin_type: TypeName,
        item_type: TypeName
    }

    struct OfferCancelled has copy, drop {
        item_id: ID
    }


    // ========== Error constants==========

    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EINVALID_PUBLISH_RECEIPT: u64 = 1;
    const EOFFER_NOT_AVAILABLE: u64 = 2;
    const EOFFER_ALREADY_EXIST: u64 = 3;
    const EINSUFFICIENT_PAYMENT: u64 = 4;
    const EINSUFFICIENT_BALANCE: u64 = 5;
    const EOFFER_ITEM_MISMATCH: u64 = 6;
    const EOFFER_NOT_OPEN: u64 = 7;
    const ENO_ITEM_TYPE: u64 = 8;
    const EITEM_TYPE_MISMATCH: u64 = 9;
    const EOFFER_DOES_NOT_EXIST: u64 = 10;


    // ========== Other contants ==========

    const BPS_BASE: u16 = 10_000;

    const BUY_OFFER_TYPE: u8 = 0;
    const SELL_OFFER_TYPE: u8 = 0;


    // ========== Royalty functions ==========

    public fun create_royalty<T>(
        receipt: &PublishReceipt,
        recipient: address,
        royalty_bps: u16,
        marketplace_fee_bps: u16,
        ctx: &mut TxContext
    ) {
        let royalty = create_royalty_<T>(receipt, recipient, royalty_bps, marketplace_fee_bps, ctx);
        transfer::share_object(royalty)
    }

    public fun create_royalty_<T>(
        receipt: &PublishReceipt,
        recipient: address,
        royalty_bps: u16,
        marketplace_fee_bps: u16,
        ctx: &mut TxContext
    ):  Royalty<T> {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(receipt), EINVALID_PUBLISH_RECEIPT);

         Royalty {
            id: object::new(ctx),
            config: RoyaltyConfig {
                recipient,
                royalty_bps,
                marketplace_fee_bps
            }
        }
    }

    // ========== Offer functions ==========

    public fun create_sell_offer<T, C>(uid: &mut UID, royalty: &Royalty<T>, seller: address, price: u64, auth: &TxAuthority) {
        // Ensures that the item being offered for sale belongs to the seller
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);
        // Ensures the item type is the same as `T`
        assert_valid_item_type<T>(uid);

        let key = Key { user: option::none(), type: SELL_OFFER_TYPE };
        assert!(!dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_ALREADY_EXIST);

        let Royalty { id: _, config } = royalty;
        let creator_royalty = bps_value(price, config.royalty_bps);
        let offer = create_offer<T, C>(seller, price, creator_royalty);

        emit_offer_created(object::uid_to_inner(uid),  &offer);
        dynamic_field::add<Key, Offer<T, C>>(uid, key, offer)
    }

    public fun create_buy_offer<T, C>(
        uid: &mut UID,
        account: &mut MarketAccount,
        royalty: &Royalty<T>,
        buyer: address,
        price: u64,
        auth: &TxAuthority
    ) {        
        // Ensure that the buyer owns the account
        market_account::assert_account_ownership(account, auth);
        // Ensure the item type is valid
        assert_valid_item_type<T>(uid);

        let key = Key { user: option::some(buyer), type: BUY_OFFER_TYPE };
        assert!(!dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_ALREADY_EXIST);

        let Royalty { id: _, config } = royalty;
        let creator_royalty = bps_value(price, config.royalty_bps);
        assert!(market_account::balance<C>(account) >= price + (creator_royalty / 2), EINSUFFICIENT_BALANCE);

        let offer = create_offer<T, C>(buyer, price, creator_royalty);

        emit_offer_created(object::uid_to_inner(uid),  &offer);
        dynamic_field::add<Key, Offer<T, C>>(uid, key, offer)
    }

    public fun fill_sell_offer<T, C>(
        uid: &mut UID,
        buyer: address,
        royalty: &Royalty<T>,
        coin: Coin<C>,
        marketplace: address,
        ctx: &mut TxContext
    ) {
        let key = Key { user: option::none(), type: SELL_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        let offer = dynamic_field::borrow<Key, Offer<T, C>>(uid, key);
        let Royalty { id: _, config } = royalty;   
     
        // ensure that the coin provided is sufficient for the offer price and buyer's royalty payment
        let total_royalty = bps_value(offer.price, config.royalty_bps);
        let payment_value =  offer.price + (total_royalty / 2);
        assert!(coin::value(&coin) >= payment_value, EINSUFFICIENT_PAYMENT);

        let payment = coin::split(&mut coin, payment_value, ctx);

        // keep the extra coin payment or destroy it if empty
        keep_or_destroy_coin(coin, ctx);

        // take and transfer the royalty value to the beneficiary
        collect_from_coin(royalty, offer, &mut payment, ctx);

        // calculate and transfer marketplace fee
        let marketplace_fee = bps_value(offer.price, config.marketplace_fee_bps);
        transfer_coin_value(&mut payment, marketplace_fee, marketplace, ctx);

        // transfer the remaining amount to the seller
        transfer::public_transfer(payment, offer.user);

        // transfer item to the buyer
        transfer_item(uid, vector[buyer], ctx);

        // remove and drop item offer
        dynamic_field::remove<Key, Offer<T, C>>(uid, key);
    }

    public fun fill_buy_offer<T, C>(
        uid: &mut UID,
        account: &mut MarketAccount,
        buyer: address,
        royalty: &Royalty<T>,
        marketplace: address,
        ctx: &mut TxContext
    ) {
        // Ensures that only the asset owner can fill the buy offer
        let auth = tx_authority::begin(ctx);
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENO_OWNER_AUTHORITY);

        let key = Key { user: option::some(buyer), type: BUY_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        let Royalty { id: _, config } = royalty;
        let offer = dynamic_field::borrow<Key, Offer<T, C>>(uid, key);
        let total_royalty = bps_value(offer.price, config.royalty_bps);
        let payment_value = offer.price + (total_royalty / 2);

        assert!(market_account::balance<C>(account) >= payment_value, EINSUFFICIENT_BALANCE);
        let payment = market_account::take<C>(account, payment_value, ctx);

        // take and transfer the royalty value to the beneficiary
        collect_from_coin(royalty, offer, &mut payment, ctx);

        // calculate and transfer marketplace fee
        let marketplace_fee = bps_value(offer.price, config.marketplace_fee_bps);
        transfer_coin_value(&mut payment, marketplace_fee, marketplace, ctx);

        // transfer remaining payment to the seller
        transfer::public_transfer(payment, tx_context::sender(ctx));

        // transfer item to the buyer
        transfer_item(uid, vector[offer.user], ctx);

        // remove and drop item offer
        dynamic_field::remove<Key, Offer<T, C>>(uid, key);
    }
    
    public fun cancel_sell_offer<T, C>(uid: &mut UID, ctx: &TxContext) {
        let auth = tx_authority::begin(ctx);
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENO_OWNER_AUTHORITY);

        let user = tx_context::sender(ctx);
        let key = Key { user: option::some(user), type: SELL_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        emit_offer_cancelled(object::uid_to_inner(uid));
        dynamic_field::remove<Key, Offer<T, C>>(uid, key);
    }

    public fun cancel_buy_offer<T, C>(uid: &mut UID, ctx: &TxContext) {
        let user = tx_context::sender(ctx);
        let key = Key { user: option::some(user), type: BUY_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        emit_offer_cancelled(object::uid_to_inner(uid));
        dynamic_field::remove<Key, Offer<T, C>>(uid, key);
    }


    // ==================== Helper functions ====================

    fun create_offer<T, C>(user: address, price: u64, creator_royalty: u64): Offer<T, C> {
        Offer { 
            user,
            price,
            creator_royalty
        }
    }

    fun transfer_item(uid: &mut UID, new_owner: vector<address>, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        ownership::transfer(uid, new_owner, &auth);
    }

    fun bps_value(value: u64, bps: u16): u64 {
        ((bps as u64) * value) / (BPS_BASE as u64)
    }

    /// Collects royalty value from coin `Coin` of type `C` and transfers it to the royalty recipient
    fun collect_from_coin<T, C>(royalty: &Royalty<T>, offer: &Offer<T, C>, source: &mut Coin<C>, ctx: &mut TxContext) {
        let Royalty { id: _, config } = royalty;
        let royalty_value = bps_value(offer.price, config.royalty_bps);

        transfer_coin_value(source, royalty_value, config.recipient, ctx)
    }

    fun transfer_coin_value<C>(coin: &mut Coin<C>, value: u64, recipient: address, ctx: &mut TxContext) {
        transfer::public_transfer(coin::split(coin, value, ctx), recipient)
    }

    fun keep_or_destroy_coin<C>(coin: Coin<C>, ctx: &TxContext) {
        if(coin::value(&coin) == 0) {
            coin::destroy_zero(coin)
        } else {
            pay::keep(coin, ctx)
        };
    }

    fun assert_valid_item_type<T>(uid: &UID) {
        let type = ownership::get_type(uid);
        assert!(option::is_some(&type), ENO_ITEM_TYPE);
        assert!(option::destroy_some(type) == struct_tag::get<T>(), EITEM_TYPE_MISMATCH);
    }

    // ===== Event helper functions =====

    fun emit_offer_created<T, C>(item_id: ID, offer: &Offer<T, C>) {
        emit(OfferCreated {
            item_id,
            user: offer.user,
            price: offer.price,
            coin_type: type_name::get<C>(),
            item_type: type_name::get<T>(),
        });
    }

    fun emit_offer_cancelled(item_id: ID) {
        emit(OfferCancelled { item_id });
    }
}