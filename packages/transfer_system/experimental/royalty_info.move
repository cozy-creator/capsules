// This is an ancillary module that helps with tracking royalty payments
//
// - In the royalty-market, it's not possible to conduct a trade without a RoyaltyInfo object,
// so restricting access to that object to only certain parties can restrict selling.
// - One RoyaltyInfo object must be created per currency Coin<C> that the organization wants to support
// rading in; this is because currencies can have wildly different scales (decimal place values)
// - RoyaltyInfo is not necessarily a singleton per StructTag / Coin<C> pair; there may be
// many different RoyalytInfo objects. It's up to the Organization managing this to maintain
// access to multiple RoyaltyInfo objects.

// TO DO: we could store RoyaltyInfo inside of the Organization object itself if we wanted?

module transfer_system::royalty_info {
    use std::option::{Self, Option};

    use sui::clock::Clock;
    use sui::coin::{Self, Coin};
    use sui::math;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;

    use sui_utils::struct_tag::{Self, StructTag};
    
    use ownership::tx_authority::{Self, TxAuthority};

    use transfer_system::market_account::MarketAccount;
    use transfer_system::trade_history::{Self, PairVolume};

    // Error Constants
    const ENO_PACKAGE_PERMISSION: u64 = 0;
    const EINVALID_ROYALTY_ARGS: u64 = 1;

    // Constants
    const MAX_ROYALTY: u128 = 10_000; // 100% royalty
    const TRILLION: u128 = 1_000_000_000_000;

    // ====== Royalty Info ======

    // C is the Coin<C> currency type used
    // Root-level shared or stored object, created by the organization
    struct RoyaltyInfo<phantom C> has key, store {
        id: UID,
        type: StructTag, // Type this royalty corresponds to
        max_bps: u64, // percentage in basis-points; 100 = 1%
        slope: u64, // bps reduction per trillion units of volume
        min_bps: u64,
        affiliate_bps: u64, // 10_000 = 100% of royalty goes to affiliate
        pay_to: address
    }

    // Permission struct
    struct ROYALTY {}

    // Convenience function
    public fun create<T, C>(
        max_bps: u64,
        slope: u64,
        min_bps: u64,
        pay_to: address,
        affiliate_bps: u64,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        let type = struct_tag::get<T>();
        let royalty_info = create_<C>(type, max_bps, slope, min_bps, affiliate_bps, pay_to, auth, ctx);
        transfer::share_object(royalty_info);
    }

    public fun create_<C>(
        type: StructTag,
        max_bps: u64,
        slope: u64,
        min_bps: u64,
        affiliate_bps: u64,
        pay_to: address,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): RoyaltyInfo<C> {
        let package_id = struct_tag::package_id(&type);
        assert!(tx_authority::has_package_permission_<ROYALTY>(package_id, auth), ENO_PACKAGE_PERMISSION);

        // Input validation
        assert!(min_bps <= max_bps, EINVALID_ROYALTY_ARGS);
        assert!(max_bps <= (MAX_ROYALTY as u64), EINVALID_ROYALTY_ARGS);
        assert!(affiliate_bps <= (MAX_ROYALTY as u64), EINVALID_ROYALTY_ARGS);

        RoyaltyInfo<C> { id: object::new(ctx), type, max_bps, slope, min_bps, affiliate_bps, pay_to }
    }

    // Unspecified parameters will remain unchanged
    public fun modify<C>(
        royalty: &mut RoyaltyInfo<C>,
        max_bps: Option<u64>,
        slope: Option<u64>,
        min_bps: Option<u64>,
        affiliate_bps: Option<u64>,
        pay_to: Option<address>,
        auth: &TxAuthority
    ) {
        let package_id = struct_tag::package_id(&royalty.type);
        assert!(tx_authority::has_package_permission_<ROYALTY>(package_id, auth), ENO_PACKAGE_PERMISSION);

        if (option::is_some(&max_bps)) { royalty.max_bps = option::destroy_some(max_bps); };
        if (option::is_some(&slope)) { royalty.slope = option::destroy_some(slope); };
        if (option::is_some(&min_bps)) { royalty.min_bps = option::destroy_some(min_bps); };
        if (option::is_some(&affiliate_bps)) { royalty.affiliate_bps = option::destroy_some(affiliate_bps); };
        if (option::is_some(&pay_to)) { royalty.pay_to = option::destroy_some(pay_to); };
    }

    // Doesn't work until Sui supports destroying shared objects
    public fun destroy<C>(royalty: RoyaltyInfo<C>, auth: &TxAuthority) {
        let package_id = struct_tag::package_id(&royalty.type);
        assert!(tx_authority::has_package_permission_<ROYALTY>(package_id, auth), ENO_PACKAGE_PERMISSION);

        let RoyaltyInfo { id, type: _, max_bps: _, slope: _, min_bps: _, affiliate_bps: _, pay_to: _} = royalty;
        object::delete(id);
    }

    // ====== For Royalty Markets ======

    // Example: volume = 1,000 SUI (1,000 * 10^9)
    // max_bps = 1_000 (10%), min_bps = 25 (0.25%), slope = 400
    // calculated fee bps = 1,000 - 400 = 600
    // In order for this to be meaningful, this caller must make sure that `pair.type` and royalty_info.type match
    public fun calculate_fee_bps<C>(pair: &PairVolume<C>, royalty_info: &RoyaltyInfo<C>): u64 {
        let volume = (trade_history::volume(pair) as u128);
        let computed = ((volume * (royalty_info.slope as u128) / TRILLION) as u64);
        if (computed >= royalty_info.max_bps) {
            royalty_info.min_bps
        } else {
            math::max(royalty_info.max_bps - computed, royalty_info.min_bps)
        }
    }

    // Returns the amount of Coin<C> that was paid (the total royalty)
    public fun pay_royalty<C>(
        seller_account: &mut MarketAccount,
        buyer_account: &mut MarketAccount,
        royalty_info: &RoyaltyInfo<C>,
        affiliate: Option<address>,
        price: u64,
        coin: &mut Coin<C>,
        clock: &Clock,
        ctx: &mut TxContext
    ): u64 {
        let buyer_pair = trade_history::borrow_mut_<C>(buyer_account, royalty_info.type);
        let seller_pair = trade_history::borrow_mut_<C>(seller_account, royalty_info.type);

        trade_history::decay(buyer_pair, clock);
        trade_history::decay(seller_pair, clock);

        let royalty_bps = calculate_fee_bps(buyer_pair, royalty_info);
        let royalty = ((price as u128) * (royalty_bps as u128) / MAX_ROYALTY as u64);

        trade_history::record_trade(price, buyer_pair, clock);
        trade_history::record_trade(royalty, seller_pair, clock);

        if (option::is_some(&affiliate)) {
            let affiliate_bonus = (((royalty as u128) * (royalty_info.affiliate_bps as u128) / MAX_ROYALTY) as u64);
            transfer::public_transfer(coin::split(coin, affiliate_bonus, ctx), option::destroy_some(affiliate));
            transfer::public_transfer(coin::split(coin, royalty - affiliate_bonus, ctx), royalty_info.pay_to);
        } else {
            transfer::public_transfer(coin::split(coin, royalty, ctx), royalty_info.pay_to);
        };

        royalty
    }

    // ====== Getter Functions ======

    public fun type<C>(royalty_info: &RoyaltyInfo<C>): &StructTag {
        &royalty_info.type
    }
}