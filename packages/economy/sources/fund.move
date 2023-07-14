// NAV (Net Asset Value) = net_assets / total_shares. This is the value of 1 share priced in `A`

// - Users purchase shares from a Fund; they exchange their asset `A` for shares `S`
// - Users can redeem assets from the fund using shares; the exchange shares `S` for asset `A`
// - The asset <-> share exchange rate is determined by the fund's NAV (Net Asset Value)

// - Fund managers can set the rules of the fund. Allowing for public purchases and redemptions,
// or keep them closed forever, or restrict them to certain parties.
// - Fund managers can optionally allow for instant purcahses and redemptions, or require a queue
// and process orders on their own schedule.
// - Fund managers set the net_assets of the fund, and make funds available for buying back shares

// - Shares act like any other Balance<T>; they can be bought and sold an orderbook.
// - Shares may trade at a premium or discount versus the fund's NAV

// Compared to TradeFi:
// - Mutual funds: anyone can purchase or redeem shares. Orders fulfilled at end of trading day
// - Open-ended ETFs: only authorized participants (APs) can purchase or redeem. APs acquire or sell
// shares on an open-market. Deposits and withdrawals occur at end of trading day.
// - Close-ended ETFs: after the initial IPO (purchases) no one can purchase or redeem. Shares are not
// issued or destroyed. In the future, at the manager's discretion, they may do a secondary offering
// to raise more funds, or buy-back shares if their ETF is trading at a discount.

// Decisions:
// - Should fund-creators be allowed to use their own Supply<S>? This would be more flexible, but would open
// up the risk of them tying Supply<S> to some nonsense currency with multiple Supply<S> that they create.
// This is flexible, like Pool<CoinA, CoinB>, but also a potential abuse-vector.
// Answer: no
//
// - Should fund-managers be allowed to process deposits, but not withdrawals? This gives them more
// flexibility, but also opens up to potential abuse by fund-managers (again).
// Answer: no

// TO DO Thoughts:
// What happens if the net_asset calculation is wrong? Over or under estimate?
// Can someone else arbitrage it into the right number?
// We don't want someone to drain it to 0 exploiting a miscalculation

module economy::fund {
    use std::option::Option;

    use sui::balance::{Self, Balance, Supply};
    use sui::coin::{Self, CoinMetadata};
    use sui::object::{Self, UID};
    use sui::url::Url;
    use sui::transfer;
    use sui::tx_context::TxContext;

    use sui_utils::typed_id;
    use sui_utils::immutable;

    use ownership::action::ADMIN;
    use ownership::ownership::{Self, INITIALIZE};
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::org_transfer::OrgTransfer;

    use economy::coin23::WITHDRAW;
    use economy::queue::{Self, Queue};

    // Error constants
    const ENO_PURCHASE_AUTHORITY: u64 = 0;
    const ENO_REDEEM_AUTHORITY: u64 = 1;
    const ENO_WITHDRAW_AUTHORITY: u64 = 2;
    const EINSTANT_PURCHASE_DISABLED: u64 = 3;
    const EINSTANT_REDEEM_DISABLED: u64 = 4;
    const ENOT_FUND_OWNER: u64 = 5;
    const ENOT_MANAGE_FUND: u64 = 6;

    // `S` is the share-type of the fund, and `T` is the type of currency it is priced in
    // For example 'BITO' might be the fund, and 'USDC' is the currency.
    // In this case, you would deposit Balance<USDC> to receive Balance<BITO>.
    // You could also redeem Balance<BITO> to receive Balance<USDC>.
    // The Fund keeps track of the total value of its assets, pricing in USDC,
    // versus the number of shares outstanding, Balance<BITO>.
    //
    // Sometimes deposits can be accepted right away, othertimes not
    //
    // Root-level, shared object or stored object
    struct Fund<phantom S, phantom A> has key, store {
        id: UID,
        total_shares: Supply<S>, // also used to issue and redeem shares
        net_assets: u64, // denominated in `T`
        share_queue: Queue<S>,
        asset_queue: Queue<A>,
        config: Config
    }

    // Configurations for the fund. Can be changed anytime by the fund-owner
    struct Config has store, copy, drop {
        public_purchase: bool,
        public_redeems: bool,
        instant_purchase: bool,
        instant_redeem: bool
    }

    // Package authority
    struct Witness has drop { }

    // Action types.
    // When Fund<S, A> is a shared object, an owner is set. This owner is the principal,
    // and delegates actions to agents.
    struct PURCHASE {} // allows buying into a fund; exchanging assets for shares
    struct REDEEM {} // allows buying out of a fund; exchanging shares for assets
    struct MANAGE_FUND {} // allows setting the net_assets, changing config, 

    // ============= Purchase Shares =============

    public fun queue_purchase<S, A>(
        fund: &mut Fund<S, A>,
        addr: address,
        asset: Balance<A>,
        auth: &TxAuthority
    ) {
        if (!fund.config.public_purchase) {
            assert!(ownership::can_act_as_owner<PURCHASE>(&fund.id, auth), ENO_PURCHASE_AUTHORITY);
        };

        queue::deposit(&mut fund.asset_queue, addr, asset);
    }

    public fun cancel_purchase<S, A>(
        fund: &mut Fund<S, A>,
        addr: address,
        auth: &TxAuthority
    ): Balance<A> {
        assert!(tx_authority::can_act_as_address<WITHDRAW>(addr, auth), ENO_WITHDRAW_AUTHORITY);

        queue::cancel_deposit(&mut fund.asset_queue, addr)
    }

    public fun instant_purchase<S, A>(
        fund: &mut Fund<S, A>,
        asset: Balance<A>,
        auth: &TxAuthority
    ): Balance<S> {
        if (!fund.config.public_purchase) {
            assert!(ownership::can_act_as_owner<PURCHASE>(&fund.id, auth), ENO_PURCHASE_AUTHORITY);
        };
        assert!(fund.config.instant_purchase, EINSTANT_PURCHASE_DISABLED);

        let shares = asset_to_shares(fund, balance::value(&asset));
        queue::direct_deposit(&mut fund.asset_queue, asset);
        balance::increase_supply(&mut fund.total_shares, shares)
    }

    // ============= Redeem Shares =============

    public fun queue_redeem<S, A>(
        fund: &mut Fund<S, A>,
        addr: address,
        shares: Balance<S>,
        auth: &TxAuthority
    ) { 
        if (!fund.config.public_redeems) {
            assert!(ownership::can_act_as_owner<REDEEM>(&fund.id, auth), ENO_REDEEM_AUTHORITY);
        };

        queue::deposit(&mut fund.share_queue, addr, shares);
    }

    public fun cancel_redeem<S, A>(
        fund: &mut Fund<S, A>,
        addr: address,
        auth: &TxAuthority
    ): Balance<A> {
        if (!fund.config.public_redeems) {
            assert!(ownership::can_act_as_owner<WITHDRAW>(&fund.id, auth), ENO_WITHDRAW_AUTHORITY);
        };

        queue::cancel_deposit(&mut fund.asset_queue, addr)
    }

    // Aborts if funds are insufficient to redeem the shares
    public fun instant_redeem<S, A>(
        fund: &mut Fund<S, A>,
        shares: Balance<S>,
        auth: &TxAuthority
    ): Balance<A> {
        if (!fund.config.public_redeems) {
            assert!(ownership::can_act_as_owner<REDEEM>(&fund.id, auth), ENO_REDEEM_AUTHORITY);
        };
        assert!(fund.config.instant_redeem, EINSTANT_REDEEM_DISABLED);

        let asset = shares_to_asset(fund, balance::value(&shares));
        balance::decrease_supply(&mut fund.total_shares, shares);
        queue::direct_withdraw(&mut fund.asset_queue, asset)
    }

    // ============= Fund Manager Interface =============
    
    // Can only be called by a package's init function on publish because otw is a one-time-witness
    public fun create<S: drop, A>(
        otw: S,
        decimals: u8,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: Option<Url>,
        ctx: &mut TxContext
    ): (Fund<S, A>, CoinMetadata<S>) {
        let (treasury_cap, metadata) = 
            coin::create_currency(otw, decimals, symbol, name, description, icon_url, ctx);
        let supply = coin::treasury_into_supply(treasury_cap);

        let fund = Fund {
            id: object::new(ctx),
            net_assets: 0,
            total_shares: supply,
            share_queue: queue::new(ctx),
            asset_queue: queue::new(ctx),
            config: Config {
                public_purchase: false,
                public_redeems: false,
                instant_purchase: false,
                instant_redeem: false
            }
        };

        (fund, metadata)
    }

    // Can be called sometime after publish. Funds created with this function cannot be
    // guaranteed to be unique on `S`; a module can create several Supply<S> and hence
    // create several funds.
    // public fun create_with_supply<S, A>(supply: Supply<S>): Fund<S, A> {
    //
    // }

    // Adds an owner and shares the fund. Upon creation, a fund-object can either be a root-level
    // shared object, or it can be a single-writer object, either stored root-level or wrapped
    // inside of another object. In this case, it reverts to referential authority, meaning anyone
    // with access to the fund can do whatever they want to it.
    public fun return_and_share<S, A>(fund: Fund<S, A>, owner: address) {
        let auth = tx_authority::begin_with_package_witness<Witness, INITIALIZE>(Witness { });
        let typed_id = typed_id::new(&fund);
        ownership::as_shared_object<Fund<S, A>, OrgTransfer>(&mut fund.id, typed_id, owner, &auth);
        transfer::share_object(fund);
    }

    public fun destroy<S, A>(fund: Fund<S, A>,auth: &TxAuthority, ctx: &mut TxContext): Balance<A> {
        assert!(ownership::can_act_as_owner<ADMIN>(&fund.id, auth), ENOT_FUND_OWNER);

        let Fund { id, total_shares, net_assets: _, share_queue, asset_queue, config: _ } = fund;
        object::delete(id);
        let share_balance = queue::destroy(share_queue);
        balance::decrease_supply(&mut total_shares, share_balance);

        // We cannot destroy Supply for now. Instead, we will discard it inside of an immutable wrapper.
        // This way, Supply<T> still exists on-chain, but can never be modified again.
        // balance::destroy_supply(total_shares);
        immutable::freeze_(total_shares, true, ctx);

        queue::destroy(asset_queue)
    }

    // This adds funds, to meet withdrawal requests
    public fun deposit_as_manager<S, A>(fund: &mut Fund<S, A>, balance: Balance<A>, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<MANAGE_FUND>(&fund.id, auth), ENOT_MANAGE_FUND);

        queue::direct_deposit(&mut fund.asset_queue, balance);
    }

    // This removes funds, so that the fund-manager can deploy them
    public fun withdraw_as_manager<S, A>(fund: &mut Fund<S, A>, amount: u64, auth: &TxAuthority): Balance<A> { 
        assert!(ownership::can_act_as_owner<MANAGE_FUND>(&fund.id, auth), ENOT_MANAGE_FUND);

        queue::direct_withdraw(&mut fund.asset_queue, amount)
    }

    public fun process_orders<S, A>(fund: &mut Fund<S, A>, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<MANAGE_FUND>(&fund.id, auth), ENOT_MANAGE_FUND);

        let total_inflows = queue::deposit_input_mint_output(
            &mut fund.asset_queue,
            &mut fund.share_queue,
            fund.net_assets,
            balance::supply_value(&fund.total_shares),
            &mut fund.total_shares);
        
        fund.net_assets = fund.net_assets + total_inflows;

        let (_, total_outflows) = queue::burn_input_withdraw_output(
            &mut fund.asset_queue,
            &mut fund.share_queue,
            fund.net_assets,
            balance::supply_value(&fund.total_shares),
            &mut fund.total_shares);
        
        fund.net_assets = fund.net_assets - total_outflows;
    }

    // The total value of net-assets should be updated regularly.
    // Net-assets can sometimes be calculated on-chain, but often they'll involve lots of off-chain state.
    // As such, it is not guaranteed that a fund's net-assets will be correct, or that the fund manager is
    // honest.
    //
    // - If net_assets is underestimated, then fund-holders redeeming shares will be underpaid, and
    // people will be able to buy in at a discount.
    // - If net_assets is overestimated, then fund-holders redeeming shares will be overpaid, and people
    // will be able to buy in at a premium.
    public fun update_net_assets<S, T>(fund: &mut Fund<S, T>, net_assets: u64, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<MANAGE_FUND>(&fund.id, auth), ENOT_MANAGE_FUND);

        fund.net_assets = net_assets;
    }

    public fun update_config<S, A>(
        fund: &mut Fund<S, A>,
        public_purchase: bool,
        public_redeems: bool,
        instant_purchase: bool,
        instant_redeem: bool,
        auth: &TxAuthority
    ) {
        assert!(ownership::can_act_as_owner<MANAGE_FUND>(&fund.id, auth), ENOT_MANAGE_FUND);

        fund.config = Config {
            public_purchase,
            public_redeems,
            instant_purchase,
            instant_redeem
        };
    }

    // ============= Getters =============

    // The amount of asset `A` available in the fund's reserve currently
    public fun reserves_available<S, A>(fund: &Fund<S, A>): u64 {
        queue::reserves_available(&fund.asset_queue)
    }

    // Amount of `S` you will get in exchange for amount of asset `A`
    // This is useful for on-chain logic looking to avoid aborting
    public fun instant_purchase_result<S, A>(fund: &Fund<S, A>, asset: u64): (bool, u64) {
        if (!fund.config.instant_purchase) { return (false, 0) };

        (true, asset_to_shares(fund, asset))
    }

    // Amount of `A` you will get for `amount` of `S`
    // Returns '(false, 0)' if instant redeem is not allowed, or if sufficient `A` is unavailable
    // in the fund's reserve to meet the redemption.
    public fun instant_redeem_result<S, A>(fund: &Fund<S, A>, shares: u64): (bool, u64) {
        if (!fund.config.instant_redeem) { return (false, 0) };

        let asset = shares_to_asset(fund, shares);
        if (asset <= reserves_available(fund)) return (true, asset)
        else return (false, 0)
    }

    // Calculates the value of a share, priced in `A`.
    public fun shares_to_asset<S, A>(fund: &Fund<S, A>, shares: u64): u64 {
        queue::ratio_conversion(shares, fund.net_assets, balance::supply_value(&fund.total_shares))
    }

    // Calculates the number of shares that can be purchased with `asset`
    public fun asset_to_shares<S, A>(fund: &Fund<S, A>, asset: u64): u64 { 
        queue::ratio_conversion(asset, balance::supply_value(&fund.total_shares), fund.net_assets)
    }
}

// ============= Helper Module =============
// This makes it easier for end-users to work with a fund.

module economy::fund_helper {

    // purchase from account
    // purchase with coin
    // redeem to account
    // redeem to coin

    // Get exact amount out (purchase and redeem)

}

// Stake Pool object: {
// sui_balance: principal + rewards, total sui (u64)
// share_balance: total shares issued (u64)
// 
// has an 'exchange rate' which is a map epoch-number -> { sui_balance, share_balance}
// It uses this instead of a simple 
// Has a queue system for deposits and withdrawals
//
// create pool, deactivate pool
// add stake, withdraw stake, 
// epoch crank
// 
// Time 1 - sui: 100, shares: 100
// Time 2 - sui: 110, shares: 100. Owner entitled to 110 sui
// Time 3 - sui: 210, shares: 190. owner-1 has 110 sui, owner-2 has 99 sui (1 lost due to rounding)
// Time 4 = sui: 220, shares: 190. owner-2's stake did not activate yet
