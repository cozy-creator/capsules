// TO DO: instead of storing sell-offers inside of the object itself, we could store them inside of TradeHistory

module transfer_system::royalty_market3 {
    use std::vector;
    use std::option::{Self, Option};
    use std::type_name::{Self, TypeName};

    use sui::clock::Clock;
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use sui::object::{uid_to_inner, UID, ID};
    use sui::transfer;
    use sui::tx_context::{TxContext};
    use sui::vec_map::{Self, VecMap};

    use sui_utils::dynamic_field2;
    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::vec_map2;

    use ownership::ownership::{Self, TRANSFER, MIGRATE};
    use ownership::tx_authority::{Self, TxAuthority};

    use transfer_system::reclaimer;
    use transfer_system::royalty_info::{Self, RoyaltyInfo};
    use transfer_system::market_account::{Self, MarketAccount};

    // Prevent users from accidentally overflowing with too many offers
    const MAX_OFFERS: u64 = 16;

    // Error constants
    const ENO_OWNER_PERMISSION: u64 = 0;
    const ETOO_MANY_OFFERS: u64 = 1;
    const EWRONG_ROYALTY_INFO: u64 = 2;
    const EINVALID_REVEAL: u64 = 3;

    struct SellOffer has store, copy, drop {
        price: u64,
        pay_to: address
    }

    struct BuyOffer has store, copy, drop {
        price: u64,
        for_type: Option<StructTag>,
        for_id: Option<ID>
    }

    struct Key has store, copy, drop { }
    struct BuyKey has store, copy, drop { type: StructTag }

    // Package authority witness
    struct Witness has drop { }

    // Permission structs
    struct BUY { }
    struct SELL { }

    // ======== Sell Offers ========

    public fun create_sell_offer<C>(
        uid: &mut UID,
        price: u64,
        pay_to: address,
        auth: &TxAuthority
    ) {
        assert!(ownership::has_owner_permission<SELL>(uid, auth), ENO_OWNER_PERMISSION);

        let sell_offers = dynamic_field2::borrow_mut_fill(uid, Key {}, vec_map::empty<TypeName, SellOffer>());
        assert!(vec_map::size(sell_offers) < MAX_OFFERS, ETOO_MANY_OFFERS);

        vec_map2::set(sell_offers, &type_name::get<C>(), SellOffer { price, pay_to });
    }

    // TO DO: Should we use `balance` instead of `Coin`?
    public fun fill_sell_offer<C>(
        uid: &mut UID,
        seller_account: &mut MarketAccount,
        buyer_account: &mut MarketAccount,
        royalty_info: &RoyaltyInfo<C>,
        buyer: address,
        affiliate: Option<address>,
        coin: &mut Coin<C>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let type = option::destroy_some(ownership::get_type(uid));
        assert!(struct_tag::match(royalty_info::type(royalty_info), &type), EWRONG_ROYALTY_INFO);

        // We remove all existing sell-offers as part of the fill process
        let sell_offers = dynamic_field::remove<Key, VecMap<TypeName, SellOffer>>(uid, Key {});

        // Aborts if there isn't an existing sell-offer for Coin<C>
        let (_, SellOffer { price, pay_to }) = vec_map::remove(&mut sell_offers, &type_name::get<C>());

        let royalty = royalty_info::pay_royalty(seller_account, buyer_account, royalty_info, affiliate, price, coin, clock, ctx);

        transfer::public_transfer(coin::split(coin, price - royalty, ctx), pay_to);
        ownership::transfer(uid, option::some(buyer), &tx_authority::begin_with_type(&Witness { }));
    }

    public fun cancel_sell_offer<C>(uid: &mut UID, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<SELL>(uid, auth), ENO_OWNER_PERMISSION);

        let sell_offers = dynamic_field::remove<Key, VecMap<TypeName, SellOffer>>(uid, Key {});
        vec_map::remove(&mut sell_offers, &type_name::get<C>());
    }

    // ======== Buy Offers ========

    public fun create_buy_offer<C>(
        uid: &UID,
        account: &mut MarketAccount,
        price: u64,
        auth: &TxAuthority
    ) {
        let account_uid = market_account::extend(account);
        assert!(ownership::has_owner_permission<BUY>(account_uid, auth), ENO_OWNER_PERMISSION);

        let for_type = ownership::get_type(uid);
        let buy_offers = dynamic_field2::borrow_mut_fill(account_uid, BuyKey { type: *option::borrow(&for_type) }, vec_map::empty());
        let inner_offers = vec_map2::borrow_mut_fill(buy_offers, &type_name::get<C>(), vector::empty());

        vector::push_back(inner_offers, BuyOffer {
            price,
            for_type,
            for_id: option::some(uid_to_inner(uid))
        });
    }

    public fun fill_buy_offer<C>(
        uid: &mut UID,
        seller_account: &mut MarketAccount,
        buyer_account: &mut MarketAccount,
        royalty_info: &RoyaltyInfo<C>,
        seller: address,
        affiliate: Option<address>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let buyer_account_uid = market_account::extend(buyer_account);
        let type = option::destroy_some(ownership::get_type(uid));
        assert!(struct_tag::match(royalty_info::type(royalty_info), &type), EWRONG_ROYALTY_INFO);

        let buy_offers = dynamic_field::borrow_mut<BuyKey, VecMap<TypeName, vector<BuyOffer>>>(buyer_account_uid, BuyKey { type });
        let inner_offers = vec_map::get_mut(buy_offers, &type_name::get<C>());
        let offer = remove_buy_offer(uid_to_inner(uid), inner_offers);

        // How much coin should be withdrawn from buyer's account?
        let coin = market_account::withdraw<C>(buyer_account, offer.price, ctx);
        royalty_info::pay_royalty(seller_account, buyer_account, royalty_info, affiliate, offer.price, &mut coin, clock, ctx);

        transfer::public_transfer(coin, seller);
        ownership::transfer(uid, option::some(seller), &tx_authority::begin_with_type(&Witness { }));
    }

    public fun cancel_buy_offer<C>(
        uid: &UID,
        account: &mut MarketAccount,
        auth: &TxAuthority
    ) {
        let account_uid = market_account::extend(account);
        let type = option::destroy_some(ownership::get_type(uid));
        assert!(ownership::has_owner_permission<BUY>(account_uid, auth), ENO_OWNER_PERMISSION);

        let buy_offers = dynamic_field::borrow_mut<BuyKey, VecMap<TypeName, vector<BuyOffer>>>(account_uid, BuyKey { type });
        let inner_offers = vec_map::get_mut(buy_offers, &type_name::get<C>());
        remove_buy_offer(uid_to_inner(uid), inner_offers);
    }

    // ======== Transfer Functionality ========

    // This aborts if the current `owner` is undefined
    public fun transfer(uid: &mut UID, new_owner: address, claim: vector<u8>, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<TRANSFER>(uid, auth), ENO_OWNER_PERMISSION);

        let auth2 = tx_authority::begin_with_type(&Witness { });
        let owner = option::destroy_some(ownership::get_owner(uid));
        reclaimer::add_claim(uid, owner, claim, &auth2);

        drop_offers(uid);
        ownership::transfer(uid, option::some(new_owner), &auth2);
    }

    public fun reclaim(uid: &mut UID, true_owner: address, reveal: vector<u8>) {
        assert!(reclaimer::is_valid_claim(true_owner, reveal), EINVALID_REVEAL);

        drop_offers(uid);
        ownership::transfer(uid, option::some(true_owner), &tx_authority::begin_with_type(&Witness { }));
    }

    // ======== Internal Helpers ========

    fun drop_offers(uid: &mut UID) {
        if (dynamic_field::exists_(uid, Key {})) {
            dynamic_field::remove<Key, VecMap<TypeName, SellOffer>>(uid, Key {});
        };
    }

    fun remove_buy_offer(id: ID, offers: &mut vector<BuyOffer>): BuyOffer {
        let (i, length) = (0, vector::length(offers));
        while(i < length) {
            let offer = vector::borrow(offers, i);
            if(offer.for_id == option::some(id)) {
                // or use swap remove?
                return vector::remove(offers, i)
            };

            i = i + 1
        };

        abort 0
    }

    // ======== Getters ========

    public fun get_sell_offers(uid: &UID): VecMap<TypeName, SellOffer> {
        dynamic_field2::get_with_default(uid, Key { }, vec_map::empty())
    }

    public fun get_sell_offer<C>(uid: &UID): Option<SellOffer> {
        if (dynamic_field::exists_(uid, Key {})) {
            let sell_offers = dynamic_field::borrow<Key, VecMap<TypeName, SellOffer>>(uid, Key {});
            vec_map2::get_maybe(sell_offers, &type_name::get<C>())
        } else {
            option::none()
        }
    }

    public fun into_price(sell_offer: &SellOffer): (u64, address) {
        (sell_offer.price, sell_offer.pay_to)
    }

    // ======== Eject ========
    // This is used to migrate between transfer-modules. We do not require package permission here;
    // only owner permission.
    // Note that ejection _does not_ remove claims. The new transfer-module should remove any outstanding
    // claims.

    public fun eject(uid: &mut UID, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<MIGRATE>(uid, auth), ENO_OWNER_PERMISSION);

        drop_offers(uid);
        ownership::eject_transfer_auth(uid, &tx_authority::begin_with_type(&Witness {}));
    }
}