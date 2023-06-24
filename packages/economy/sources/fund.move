// Example: I deposit $100 into a pool with $900, now $1,000. I get 10% of the pool's share,
// that is share = 100.
// The pool's value increases to $2,000. If I redeem my share, I get $200.

// What happens if the net_asset calculation is wrong? Over or under estimate?
// Can someone else arbitrage it into the right number?
// We don't want someone to drain it to 0 exploiting a miscalculation

// NAV (Net Asset Value) = net_assets / total_shares. This is the redemption value of 1 share,
// price in `A`

// TO DO: restrict who can deposit into a fund
// Users deposit currency into a Fund, and receive shares in return
// Shares can be bought and sold on an orderbook.
// Shares may trade at a premium or discount versus the fund's NAV
// Shares can be redeemed for the underlying currency at the fund's current NAV
// Fund-managers can restrict deposits or withdrawals
// They may restrict deposits + withdrawals to just certain parties, or they may restrict them
// altogether.
//
// Compared to TradeFi:
// - Mutual funds: anyone can deposit, anyone can withdraw. Occurs at end of trading day
// - Open-ended ETFs: only authorized participants (APs) can deposit or withdraw. APs acquire or sell
// shares on an open-market. Deposits and withdrawals occur at end of trading day.
// - Close-ended ETFs: after the initial IPO (deposits) no one can deposit or withdraw. Shares are not
// issued or destroyed. In the future, at the manager's discretion, they may do a secondary offering
// or buy-back shares if they are trading at a discount.

// Decisions:
// - Should fund-creators be allowed to use their own Supply<S>? This would be more flexible, but would open
// up the risk of them tying Supply<S> to some nonsense currency with multiple Supply<S> that they create.
// This is flexible, like Pool<CoinA, CoinB>, but also a potential abuse-vector.
// Answer: no
//
// - Should fund-managers be allowed to process deposits, but not withdrawals? This gives them more
// flexibility, but also opens up to potential abuse by fund-managers (again).
// Answer: no

module economy::fund {
    use sui::balance::{Self, Balance, Supply};
    use sui::coin::{Self, CoinMetadata};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::org_transfer::Witness as OrgTransfer;

    use economy::account::{Self, Account, WITHDRAW};
    use economy::queue::{Self, Queue};

    // Error constants
    const ENO_PURCHASE_AUTHORITY: u64 = 0;
    const ENO_REDEEM_AUTHORITY: u64 = 1;
    const ENO_WITHDRAW_AUTHORITY: u64 = 2;
    const EINSTANT_PURCHASE_DISABLED: u64 = 3;
    const EINSTANT_REDEEM_DISABLED: u64 = 4;
    const ENOT_FUND_OWNER: u64 = 5;
    const ENOT_FUND_MANAGER: u64 = 6;

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

    // Action types
    struct PURCHASE {} // Share-package grants to users to deposit to non-public funds
    struct REDEEM {} // granted to users who are allowed to withdraw from non-public funds
    struct MANAGE_FUND {}

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
        queue::deposit_directly(&mut fund.asset_queue, asset);
        balance::increase_supply(&mut fund.total_shares, shares)
    }

    // ============= Redeem Shares =============

    public fun queue_redeem(
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
    ): Balance<S> {
        if (!fund.config.public_redeems) {
            assert!(ownership::can_act_as_owner<WITHDRAW>(&fund.id, auth), ENO_WITHDRAW_AUTHORITY);
        };

        queue::cancel_deposit(&mut fund.asset_queue, addr)
    }

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
        queue::withdraw_directly(&mut fund.asset_queue, asset)
    }

    // ============= Helpers =============
    // Makes it easier to work with the fund

    // purchase from account
    // purchase with coin
    // redeem to account
    // redeem to coin

    // ============= Getters =============

    // Calculates the value of a share, priced in `T`.
    public fun shares_to_asset<S, T>(fund: &Fund<S, T>, shares: u64): u64 {
        queue::ratio_conversion(shares, fund.net_assets, balance::supply_value(&fund.total_shares))
     }

    public fun asset_to_shares<S, T>(fund: &Fund<S, T>, asset: u64): u64 { 
        queue::ratio_conversion(asset, balance::supply_value(&fund.total_shares, fund.net_assets))
    }

    // ============= Fund Manager Interface =============
    
    // Can only be called by a package's init function on publish because otw is a one-time-witness
    public fun create<S: drop>(
        otw: S,
        decimals: u8,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: Option<Url>,
        ctx: &mut TxContext
    ): (Fund<S>, CoinMetadata<S>) {
        let (treasury_cap, metadata) = 
            coin::create_currency(otw, decimals, symbol, name, description, icon_url, ctx);
        let supply = coin::treasury_into_supply(treasury_cap);

        let fund = Fund {
            id: object::new(ctx),
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
    // public fun create_with_supply() {
    // }

    // Adds an owner and shares the fund. Upon creation, a fund-object can either be a root-level
    // shared object, or it can be a single-writer object, either stored root-level or wrapped
    // inside of another object. In this case, it reverts to referential authority, meaning anyone
    // with access to the fund can do whatever they want to it.
    public fun return_and_share<S, A>(fund: Fund<S, A>, owner: address) {
        let auth = tx_authority::begin_with_package_witness(&Witness {});
        let typed_id = typed_id::new(&fund);
        ownership::as_shared_object<Fund, OrgTransfer>(&mut fund.id, typed_id, owner, &auth);
        transfer::share_object(fund);
    }

    public fun destroy(fund: Fund<S, A>, auth: &TxAuthority): Balance<A> {
        assert!(ownership::can_act_as_owner<ADMIN>(&fund.id, auth), ENOT_FUND_OWNER);

        let Fund { id, total_shares, net_assets: _, share_queue, asset_queue, config: _ } = fund;
        object::delete(id);
        let share_balance = queue::destroy(share_queue);
        balance::decrease_supply(&mut total_shares, share_balance);
        balance::destroy_supply(total_shares);
        queue::destroy(asset_queue)
    }

    // This adds funds, to meet withdrawal requests
    public fun deposit_assets_as_manager<S, A>(fund: &mut Fund<S, A>, balance: Balance<A>, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        queue::deposit_directly(&mut fund.asset_queue, balance);
    }

    // This removes funds, so that the fund-manager can deploy them
    public fun withdraw_assets_as_manager(fund: &mut Fund<S, A>, amount: u64): Balance<T> { 
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        queue::withdraw_directly(&mut fund.asset_queue, amount)
    }

    public fun process_orders<S, A>(fund: &mut Fund<S, A>, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        let total_deposits = queue::deposit_input_mint_output(
            &mut fund.asset_queue,
            &mut fund.share_queue,
            fund.net_assets,
            balance::supply_value(&fund.supply),
            &mut fund.supply);
        
        fund.net_assets = fund.net_assets + total_deposits;

        let (_, total_withdrawals) = queue::burn_input_withdraw_output(
            &mut fund.asset_queue,
            &mut fund.share_queue,
            fund.net_assets,
            balance::supply_value(&fund.supply),
            &mut fund.supply);
        
        fund.net_assets = fund.net_assets - total_withdrawals;
    }

    // The total value of net-assets should be updated regularly.
    // Net-assets can sometimes be calculated on-chain, but often they will involve lots of off-chain pricing. As such,
    // it is not guaranteed that a fund's net-assets will be correct, or that the fund manager is honest.
    //
    // - If net_assets is underestimated, then fund-holders redeeming shares will be underpaid, and
    // people will be able to buy in at a discount.
    // - If net_assets is overestimated, then fund-holders redeeming shares will be overpaid, and people
    // will be able to buy in at a premium.
    public fun update_net_assets<S, T>(fund: &mut Fund<S, T>, net_assets: u64, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        fund.net_assets = net_assets;
    }

    public fun update_config(
        fund: &mut Fund<S, T>,
        public_purchase: bool,
        public_redeems: bool,
        instant_purchase: bool,
        instant_redeem: bool,
        auth: &TxAuthority
    ) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        fund.config = Config {
            public_purchase,
            public_redeems,
            instant_purchase,
            instant_redeem
        };
    }
}

// Note that queue itself does not enforce any rules on who can deposit and withdraw; a person with a mutable
// reference to `Queue<T>` can deposit or withdraw to any address. That is, queue relies entirely upon
// referential authority for its security.
//
// Should we add these restrictions in? Or should we leave it up to the Fund program to enforce?
//
// Ideally Queue would be a pure data-type; I wish we didn't need to use ctx or generate object-ids
// to create it.
module economy::queue {
    use sui::balance::{Self, Balance};
    use sui::tx_context::TxContext;
    use sui::linked_table::{Self as map, LinkedTable as Map};

    use sui_utils::linked_table2 as map2;

    // Incoming is a map of depositors to deposits to be processed
    // Balance is a pool of active funds
    // Outoing is a map of people owed money to the funds they can claim
    struct Queue<phantom T> has store {
        incoming: Map<address, Balance<T>>,
        balance: Balance<T>,
        outgoing: Map<address, Balance<T>>
    }

    // ======== Creation / Deletion API =========

    public fun new<T>(ctx: &mut TxContext): Queue<T> {
        Queue {
            incoming: map::new<address, Balance<T>>(ctx),
            balance: balance::zero<T>(),
            outgoing: map::new<address, Balance<T>>(ctx)
        }
    }

    // Merges all Balance<T> into one and returns it, even if it's empty
    public fun destroy<T>(queue: Queue<T>): Balance<T> {
        let return_balance = balance::zero();

        let Queue { incoming, balance, outgoing } = queue;

        balance::join(&mut return_balance, map2::collapse_balance(incoming));
        balance::join(&mut return_balance, balance);
        balance::join(&mut return_balance, map2::collapse_balance(outgoing));

        return_balance
    }

    // Aborts if any Balance<T> is greater than 0
    public fun destroy_empty<T>(queue: Queue<T>) {
        let Queue { incoming, balance, outgoing } = queue;

        map::destroy_empty(incoming);
        balance::destroy_empty(balance);
        map::destroy_empty(outgoing);
    }

    // ======== Queue API =========

    public fun deposit<T>(queue: &mut Queue<T>, addr: address, balance: Balance<T>) {
        map2::merge_balance(&mut queue.incoming, addr, balance);
    }

    // Cancels a pending deposit and returns the funds
    public fun cancel_deposit<T>(queue: &mut Queue<T>, addr: address): Balance<T> {
        map::remove(&mut queue.incoming, addr)
    }

    // We withdraw everything; there's no point in keeping fractional values in queue
    public fun withdraw<T>(queue: &mut Queue<T>, addr: address): Balance<T> {
        if (map::contains(&queue.outgoing, addr)) {
            map::remove(&mut queue.outgoing, addr)
        } else {
            balance::zero()
        }
    }

    // ======== Direct API =========

    public fun deposit_directly<T>(queue: &mut Queue<T>, balance: Balance<T>) {
        balance::join(&mut queue.balance, balance)
    }

    public fun withdraw_directly<T>(queue: &mut Queue<T>, amount: u64): Balance<T> {
        balance::split(&mut queue.balance, amount)
    }

    // ======== Process Queue =========

    // Moves q_a.incoming -> balance, mint `S` with `supply` -> q_s.outgoing
    public fun deposit_input_mint_output<S, A>(
        q_a: &mut Queue<A>,
        q_s: &mut Queue<S>,
        asset_size: u64,
        share_size: u64,
        supply: &mut Supply<S>
    ): u64 {
        let deposits = 0;

        while (!map::is_empty(&q_a.incoming)) {
            // deposit incoming funds
            let (user, balance) = map::pop_front(&mut q_a.incoming);
            let balance_value = balance::value(&balance);
            balance::join(&mut q_a.balance, balance);
            deposits = deposits + balance_value;

            // mint outgoing shares
            let share_amount = ratio_conversion(balance_value, share_size, asset_size);
            let shares = balance::increase_supply(supply, share_amount);
            map2::merge_balance(&mut q_s.outgoing, user, shares);
        };

        deposits
    }

    // q_s incoming -> burn with `supply`, q_a balance -> q_a outgoing
    // If q_a.balance is not sufficient to cover redeeming shares, this process will stop
    // Returns a 'success' boolean, since this will never abort
    public fun burn_input_withdraw_output<S, A>(
        q_a: &mut Queue<A>,
        q_s: &mut Queue<S>,
        asset_size: u64,
        share_size: u64,
        supply: &mut Supply<S>
    ): (bool, u64) {
        let withdrawals = 0;

        while (!map::is_empty(&q_s.incoming)) {
            // withdraw outgoing funds
            let (user, shares) = map::pop_front(&mut q_s.incoming);
            let shares_value = balance::value(&shares);
            let asset_amount = ratio_conversion(shares_value, asset_size, share_size);

            // Check if we've run out of funds for now; stop rather than abort
            if (balance::value(&q_a.balance) < asset_amount) {
                map::push_front(&mut q_s.incoming, user, shares);
                return (false, withdrawals)
            };
            let balance = balance::split(&mut q_a.balance, asset_amount);
            map2::merge_balance(&mut q_a.outgoing, user, balance);
            withdrawals = withdrawals + asset_amount;

            // burn incoming shares
            balance::decrease_supply(supply, shares);
        };

        (true, withdrawals)
    }

    // ======== Getters =========

    public fun ratio_conversion(amount: u64, numerator: u64, denominator: u64): u64 {
        ((amount as u128) * (numerator as u128) / (denominator as u128) as u64)
    }
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
