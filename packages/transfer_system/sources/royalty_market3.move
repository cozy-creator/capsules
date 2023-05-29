// TO DO: instead of storing sell-offers inside of the object itself, we could store them inside of TradeHistory

module transfer_system::royalty_market3 {

    use transfer_system::royalty_info::{Self, RoyaltyInfo};

    // Prevent users from accidentally overflowing with too many offers
    const MAX_OFFERS: u64 = 16;

    // Error constants
    const ENO_OWNER_PERMISSION: u64 = 0;
    const ETOO_MANY_OFFERS: u64 = 1;
    const EWRONG_ROYALTY_INFO: u64 = 2;

    struct SellOffer has store, drop {
        price: u64,
        pay_to: address
    }

    struct BuyOffer has store, drop {
        price: u64
    }

    struct Key has store, copy, drop { }

    // Package authority witness
    struct Witness has drop { }

    // Permission structs
    struct SELL { }
    struct BUY { }
    struct TRANSFER { }

    // ======== Sell Offers ========

    public fun create_sell_offer<C>(
        uid: &mut UID,
        price: u64,
        pay_to: address,
        royalty_info: &RoyaltyInfo,
        auth: &TxAuthority
    ) {
        assert!(ownership::has_owner_permission<SELL>(uid, auth), ENO_OWNER_PERMISSION);

        let sell_offers = dynamic_field2::borrow_mut_fill(uid, Key {}, vec_map::empty());
        assert!(vec_map::size(sell_offers) < MAX_OFFERS, ETOO_MANY_OFFERS);

        let balance_type = type_name::get<C>();
        vec_map2::set(sell_offers, balance_type, SellOffer { price, pay_to });
    }

    // TO DO: Should we use `balance` instead of `Coin`?
    public fun fill_sell_offer<C>(
        uid: &mut UID,
        buyer: address,
        history: &mut TradeHistory,
        royalty_info: &RoyaltyInfo,
        affiliate: Option<address>,
        coin: &mut Coin<C>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let type = option::destroy_some(ownership::get_type(uid));
        assert!(struct_tag::match(royalty_info::type(royalty_info), type), EWRONG_ROYALTY_INFO);

        // We remove all existing sell-offers as part of the fill process
        let sell_offers = dynamic_field::remove<Key, VecMap<TypeName, SellOffer>>(uid, Key {});

        // Aborts if there isn't an existing sell-offer for Coin<C>
        let (_, SellOffer { price, pay_to }) = vec_map::remove(&mut sell_offers, type_name::get<C>());

        let royalty = royalty_info::pay_royalty(history, royalty_info, affiliate, price, coin, clock, ctx);

        transfer::transfer(coin::split(coin, price - royalty, ctx), pay_to);
        ownership::transfer(uid, option::some(buyer), &tx_authority::begin_with_type(&Witness { }));
    }

    public fun cancel_sell_offer() {

    }

    // ======== Buy Offers ========

    public entry fun create_buy_offer() {}

    public entry fun fill_buy_offer() {}

    public entry fun cancel_buy_offer() {}

    // ======== Transfer Functionality ========

    public entry fun transfer(uid: &mut UID, new_owner: address, claim: vector<u8>, _ctx: &mut TxContext) {
        assert!(dynamic_field::exists_with_type<u8, TransferAuth<RoyaltyM>>(&noot.plugins.id, TRANSFER), ENO_TRANSFER_AUTH);

        reset_auths_internal(noot, new_owner, FULL_PERMISSION);
        
        let claims = dynamic_field::borrow_mut<u8, vector<vector<u8>>>(&mut noot.plugins.id, RECLAIMERS);
        vector::push_back(claims, claim);
    }

    // Remove outstanding claim-marks
    fun remove_claims(noot: &mut Noot) {
        *dynamic_field::borrow_mut<u8, vector<vector<u8>>>(&mut noot.plugins.id, RECLAIMERS) = vector::empty<vector<u8>>();
    }

    // ======== Getter Functionality ========

    public fun into_price(sell_offer: &SellOffer): (u64, String) {
        (sell_offer.price, sell_offer.coin_type)
    }
}