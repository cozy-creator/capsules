module transfer_system::trading {
    use std::option::{Self, Option};

    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use ownership::ownership;
    use ownership::permission::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};

    use transfer_system::transfer_freezer;
    use transfer_system::royalty_market::{Self, Royalty};
    use transfer_system::market_account::{Self, MarketAccount};

    use sui_utils::encode;

    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EOFFER_ALREADY_EXIST: u64 = 1;
    const EOFFER_DOES_NOT_EXIST: u64 = 2;
    const EINSUFFICIENT_BALANCE: u64 = 3;
    const EINSUFFICIENT_PAYMENT: u64 = 4;
    const ENO_ITEM_TYPE: u64 = 5;
    const EITEM_TYPE_MISMATCH: u64 = 6;
    const EROYALTY_ID_MISMATCH: u64 = 7;
    const EEMARKET_ACCOUNT_OWNER_MISMATCH: u64 = 8;

    const BUY_OFFER_TYPE: u8 = 0;
    const SELL_OFFER_TYPE: u8 = 0;

    struct Offer<phantom T, phantom C> has store, drop {
        price: u64,
        user: address,
        royalty_id: ID,
    }

    // ========== Event structs ==========

    struct OfferCreated<phantom T, phantom C> has copy, drop {
        type: u8,
        price: u64,
        item_id: ID,
        user: address
    }

    struct OfferCancelled has copy, drop {
        type: u8,
        item_id: ID
    }

    // ========== Dynamic fields key structs ==========
    struct Key has store, copy, drop { type: u8, user: Option<address> }

    struct Witness has drop { }

    // ========== Offer functions ==========

    public fun create_sell_offer<T, C>(
        uid: &mut UID,
        royalty: &Royalty,
        seller: address,
        price: u64,
        auth: &TxAuthority
    ) {
        royalty_market::assert_valid_item_type<T>(uid);
        royalty_market::assert_royalty_type<T>(royalty);
        assert!(ownership::has_owner_permission<ADMIN>(uid, auth), ENO_OWNER_AUTHORITY);

        // Because only the owner can create a sell offer, we set the user field to none
        let key = Key { user: option::none(), type: SELL_OFFER_TYPE };
        assert!(!dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_ALREADY_EXIST);

        let royalty_id = object::id(royalty);
        let offer = create_offer<T, C>(seller, price, royalty_id);

        transfer_freezer::freeze_transfer(uid, encode::type_into_address<Witness>(), auth);

        emit_offer_created(object::uid_to_inner(uid), SELL_OFFER_TYPE, &offer);
        dynamic_field::add<Key, Offer<T, C>>(uid, key, offer)
    }

    public fun create_buy_offer<T, C>(
        uid: &mut UID,
        account: &mut MarketAccount,
        royalty: &Royalty,
        buyer: address,
        price: u64,
        auth: &TxAuthority
    ) {        
        royalty_market::assert_valid_item_type<T>(uid);
        royalty_market::assert_royalty_type<T>(royalty);
        market_account::assert_account_ownership(account, auth);

        let key = Key { user: option::some(buyer), type: BUY_OFFER_TYPE };
        assert!(!dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_ALREADY_EXIST);

        let royalty_value = royalty_market::calculate_royalty(royalty, price);
        assert!(market_account::balance<C>(account) >= price + (royalty_value / 2), EINSUFFICIENT_BALANCE);

        let offer = create_offer<T, C>(buyer, price, object::id(royalty));

        emit_offer_created(object::uid_to_inner(uid), BUY_OFFER_TYPE, &offer);
        dynamic_field::add<Key, Offer<T, C>>(uid, key, offer)
    }

    public fun fill_sell_offer<T: key + store, C>(
        uid: &mut UID,
        royalty: &Royalty,
        coin: Coin<C>,
        buyer: address,
        ctx: &mut TxContext
    ) {
        let key = Key { user: option::none(), type: SELL_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        let offer = dynamic_field::remove<Key, Offer<T, C>>(uid, key);
        assert!(object::id(royalty) == offer.royalty_id, EROYALTY_ID_MISMATCH);
     
        let royalty_payment = royalty_market::create_payment<T>(uid, royalty, offer.price);
        let royalty_value = royalty_market::payment_value(&royalty_payment);

        let buyer_payment =  offer.price + (royalty_value / 2);
        assert!(coin::value(&coin) >= buyer_payment, EINSUFFICIENT_PAYMENT);

        let sale_coin = coin::split(&mut coin, buyer_payment, ctx);
        let royalty_coin = coin::split(&mut sale_coin, royalty_value, ctx);

        // transfer item to the buyer
        transfer_freezer::unfreeze_transfer(uid, &tx_authority::begin_with_type(&Witness {}));
        royalty_market::transfer<T, C>(uid, royalty_payment, royalty_coin, option::some(buyer));
        // transfer the sale amount to the seller
        transfer::public_transfer(sale_coin, offer.user);

        // transfer the remaining coin to the buyer, if not zero
        if(coin::value(&coin) != 0) {
            transfer::public_transfer(coin, buyer)
        } else {
            coin::destroy_zero(coin)
        }
    }

    public fun fill_buy_offer<T: key + store, C>(
        uid: &mut UID,
        account: &mut MarketAccount,
        royalty: &Royalty,
        buyer: address,
        ctx: &mut TxContext
    ) {
        assert!(ownership::has_owner_permission<ADMIN>(uid, &tx_authority::begin(ctx)), ENO_OWNER_AUTHORITY);

        let key = Key { user: option::some(buyer), type: BUY_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        let offer = dynamic_field::remove<Key, Offer<T, C>>(uid, key);
        assert!(object::id(royalty) == offer.royalty_id, EROYALTY_ID_MISMATCH);
        
        let royalty_payment = royalty_market::create_payment<T>(uid, royalty, offer.price);
        let total_royalty = royalty_market::payment_value(&royalty_payment);
        let buyer_payment = offer.price + (total_royalty / 2);

        assert!(market_account::owner(account) == offer.user, EEMARKET_ACCOUNT_OWNER_MISMATCH);
        assert!(market_account::balance<C>(account) >= buyer_payment, EINSUFFICIENT_BALANCE);

        let sale_coin = market_account::withdraw<C>(account, buyer_payment, ctx);
        let royalty_coin = coin::split(&mut sale_coin, total_royalty, ctx);

        // transfer item to the buyer
        royalty_market::transfer<T, C>(uid, royalty_payment, royalty_coin, option::some(buyer));
        // transfer sale coin to the seller
        transfer::public_transfer(sale_coin, tx_context::sender(ctx))
    }
    
    public fun cancel_sell_offer<T, C>(uid: &mut UID, ctx: &TxContext) {
        assert!(ownership::has_owner_permission<ADMIN>(uid, &tx_authority::begin(ctx)), ENO_OWNER_AUTHORITY);

        let key = Key { user: option::none(), type: SELL_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        dynamic_field::remove<Key, Offer<T, C>>(uid, key);
        transfer_freezer::unfreeze_transfer(uid, &tx_authority::begin_with_type(&Witness {}));
        emit_offer_cancelled(object::uid_to_inner(uid), SELL_OFFER_TYPE)
    }

    public fun cancel_buy_offer<T, C>(uid: &mut UID, ctx: &TxContext) {
        let key = Key { user: option::some(tx_context::sender(ctx)), type: BUY_OFFER_TYPE };
        assert!(dynamic_field::exists_with_type<Key, Offer<T, C>>(uid, key), EOFFER_DOES_NOT_EXIST);

        dynamic_field::remove<Key, Offer<T, C>>(uid, key);
        emit_offer_cancelled(object::uid_to_inner(uid), BUY_OFFER_TYPE)
    }


    // ==================== Helper functions ====================

    fun create_offer<T, C>(user: address, price: u64, royalty_id: ID): Offer<T, C> {
        Offer { 
            user,
            price,
            royalty_id
        }
    }

    // ===== Event helper functions =====

    fun emit_offer_created<T, C>(item_id: ID, type: u8, offer: &Offer<T, C>) {
        event::emit(OfferCreated<T, C> {
            type,
            item_id,
            user: offer.user,
            price: offer.price,
        });
    }

    fun emit_offer_cancelled(item_id: ID, type: u8) {
        event::emit(OfferCancelled { 
            type,
            item_id
        });
    }
}