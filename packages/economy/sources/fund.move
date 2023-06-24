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
// issued or destroyed. In the future, at the manager's discrition, they may do a secondary offering
// or buy-back shares if they are trading at a discount.

module economy::fund {
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
        anyone_can_deposit: bool,
        anyone_can_withdraw: bool,
        instant_deposit: bool,
        instant_withdraw: bool
    }

    // Action types
    struct DEPOSIT {}
    struct WITHDRAW {}
    struct FUND_MANAGER {}

    // ============= User Interface =============

    public fun request_deposit<S, A>(
        account: &mut Account<A>,
        fund: &mut Fund<S, A>,
        amount: u64,
        auth: &TxAuthority
    ) {
        if (!fund.config.anyone_can_deposit) {
            assert!(tx_authority::can_act_as_package<S, DEPOSIT>(auth), ENO_DEPOSIT_AUTHORITY);
        };

        let balance = account::withdraw(account, amount, auth);
        queue::deposit(&mut fund.asset_queue, account::owner(account), balance);
    }

    public fun instant_deposit<S, T>(
        account: &mut Account<T>,
        fund: &mut Fund<S, T>,
        amount: u64,
        auth: &TxAuthority
    ): Balance<S> { 
        // Withdraw from account
        // deposit into Fund
        // receive shares back
    }

    public fun request_withdrawal(
        account: &mut Account,
        fund: &mut Fund<S, T>,
        amount: u64,
        auth: &TxAuthority
    ) { }

    public fun instant_withdrawal<S, T>(
        account: &mut Account,
        fund: &mut Fund<S, T>,
        amount: u64,
        auth: &TxAuthority
    ) { 

    }

    // ============= Helpers =============
    // Makes it easier to work with the fund

    // deposit from balance
    // deposit from coin
    // withdraw to balance
    // withdraw to coin
    // withdrawal all

    // ============= Getters =============

    public fun instantly_withdrawable<S, T>(fund: &Fund<S, T>): u64 { }

    // Calculates the value of a share, priced in `T`.
    public fun share_to_currency<S, T>(share: u64, fund: &Fund<S, T>): u64 { }

    public fun available_amount<S, T>(addr: address, fund: &Fund<S, T>): u64 { 

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
                anyone_can_deposit: false,
                anyone_can_withdraw: false,
                instant_deposit: false,
                instant_withdraw: false
            }
        };

        (fund, metadata)
    }

    // Can be called sometime after publish. Funds created with this function cannot be
    // guaranteed to be unique on `S`; a module can create several Supply<S> and hence
    // create several funds.
    public fun create_with_supply() {

    }

    // Adds an owner and shares the fund. Upon creation, a fund-object can either be a root-level
    // shared object, or it can be a single-writer object, either stored root-level or wrapped
    // inside of another object. In this case, it reverts to referential authority, meaning anyone
    // with access to the fund can do whatever they want to it.
    public fun share() {
        // TO DO: make sure capsules works even if it's not right...

        let typed_id = typed_id::new(&fund);
        ownership::as_shared_object<Fund, AdminTransfer>(&mut outlaw.id, typed_id, owner, &auth);
    }

    public fun destroy() {

    }

    // This adds funds, to meet withdrawal requests
    public fun manager_deposit() { }

    // This removes funds, so that the fund-manager can deploy them
    public fun manager_withdraw() { }

    // TO DO: should fund-managers be allowed to 

    public fun accept_deposits() {

    }

    public fun accept_withdrawals() {

    }

    public fun process_all<S, T>(fund: &mut Fund<S, T>, auth: &TxAuthority) {
        process_deposits(fund, auth);
        process_withdrawals(fund, auth);
    }

    public fun process_deposits<S, T>(fund: &mut Fund<S, T>, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        let total_deposits = queue::deposit_input_mint_output(
            &mut fund.asset_queue,
            &mut fund.share_queue,
            fund.net_assets,
            balance::supply_value(&fund.supply),
            &mut fund.supply);
        
        fund.net_assets = fund.net_assets + total_deposits;
    }

    public fun process_withdrawals<S, T>(fund: &mut Fund<S, T>, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        let (_success, total_withdrawals) = queue::burn_input_withdraw_output(
            &mut fund.asset_queue,
            &mut fund.share_queue,
            fund.net_assets,
            balance::supply_value(&fund.supply),
            &mut fund.supply);
        
        fund.net_assets = fund.net_assets - total_withdrawals;
    }

    // The total value of net-assets should be updated regularly. This number is not guaranteed
    // to be correct and the fund manager is not necessarily honest. Net-assets may not be calculated
    // on-chain; it could be an entirely off-chain value.
    // - If net_assets is underestimated, then fund-holders redeeming shares will be underpaid, and
    // people will be able to buy in at a discount.
    // - If net_assets is overestimated, then fund-holders redeeming shares will be overpaid, and people
    // will be able to buy in at a premium.
    public fun update_net_assets<S, T>(fund: &mut Fund<S, T>, net_assets: u64, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        fund.net_assets = net_assets;
    }

    // =========== Change Config ===========

    public fun update_config(
        fund: &mut Fund<S, T>,
        auth: &TxAuthority
    ) {
        assert!(ownership::can_act_as_owner<FUND_MANAGER>(&fund.id, auth), ENOT_FUND_MANAGER);

        fund.config = config;
    }
}

// Note that queue itself does not enforce any rules on who can deposit and withdraw; a person with a mutable
// reference to `Queue<T>` can deposit or withdraw to any address.
// Should we add these restrictions in? Or should we leave it up to the fund manager to enforce?
//
// Ideally Queue would be a pure data-type; I wish we didn't need to use ctx or generate object-ids
// to create it.
module economy::queue {
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

    public fun destroy_empty<T>(
        queue: Queue<T>
    ): (Map<address, Balance<T>>, Balance<T>, Map<address, Balance<T>>) {
        let Queue { incoming, balance, outgoing } = queue;
        // TO DO
    }

    public fun merge_and_destroy<T>(queue: Queue<T>): Balance<T> {
        // TO DO
    }

    // ======== Useage API =========

    public fun deposit(queue: &mut Queue<T>, owner: address, balance: Balance<T>) {

    }

    public fun withdraw(queue: &mut Queue<T>, owner: address, amount: u64) {

    }

    public fun borrow_incoming() {

    }

    public fun borrow_incoming_mut(queue: &mut Queue<T>): &mut Map<address, Balance<T>> {

    }

    public fun borrow_balance(queue: &Queue<T>): &Balance<T> {

    }

    public fun borrow_balance_mut(queue: &mut Queue<T>): &mut Balance<T> {

    }

    public fun borrow_outgoing() {

    }

    public fun borrow_outgoing_mut(queue: &mut Queue<T>): &mut Map<address, Balance<T>> {

    }

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
            let balance_value = balance::value(&balance) as u128;
            balance::join(&mut q_a.balance, balance);
            deposits = deposits + balance_value;

            // mint outgoing shares
            let share_amount = balance_value * (share_size as u128) / (asset_size as u128) as u64;
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
            let shares_value = balance::value(&shares) as u128;
            let asset_amount = shares_value * (asset_size as u128) / (share_size as u128) as u64;

            // Check if we've run out of funds for now; stop rather than abort
            if (balance::value(&q_a.balance) < asset_amount) {
                map::push_front(&mut q_s.incoming, user, shares);
                return (false, withdrawals)
            };
            let balance = balance::split(&mut q_a.balance, asset_amount);
            map2::merge_balance(&mut q_a.outgoing, user, balance);
            withdrawals = withdrawals + balance;

            // burn incoming shares
            balance::decrease_supply(supply, shares);
        };

        (true, withdrawals)
    }
}

module economy::shares {
    // Stored object
    struct Share<T> has store {
        fund_id: ID,
        number_of_shares: u64
    }

    // You can buy into or sell out of this fund with `Balance<T>`
    // net_assets can be either calculated on-chain, or off-chain
    // Shared root-level object
    struct Fund<phantom T> has key, store {
        id: UID,
        shares_outstanding: u64, // total float
        net_assets: u64 // denominated in `Balance<T>`
    }

    public fun issue_shares<T>(fund: &mut Fund<T>, balance: Balance<T>): Share<T> {
        let value = balance::value(&balance);
        let new_shares = if (fund.net_assets == 0) {
            value
        } else {
            value * fund.shares_outstanding / fund.net_assets
        };

        pool.shares_outstanding = pool.shares_outstanding + new_shares;
        pool.net_assets = pool.net_assets + value;

        // TO DO: transfer balance somewhere ?

        Share {
            fund_id: fund.id,
            nubmer_of_shares: new_shares
        }
    }

    // This only works if the funds are available to cover the withdrawal
    public fun redeem_shares<T>(fund: &mut Fund<T>, share: Share<T>): Balance<T> {
        let Share { fund_id, number_of_shares } = share;
        assert!(fund_id == fund.id, EINCORRECT_FUND);

        let value = number_of_shares * fund.net_assets / fund.shares_outstanding;

        pool.shares_outstanding = pool.shares_outstanding - number_of_shares;
        pool.net_assets = pool.net_assets - value;

        // TO DO: get balance<T> from somewhere?
    }

    public fun request_redemption<T>(fund: &mut Fund<T>, share: Share<T>) {
        let Share { fund_id, number_of_shares } = share;
        assert!(fund_id == fund.id, EINCORRECT_FUND);

        // TO DO: add a note asking for a refund?
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
