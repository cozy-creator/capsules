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

module economy::shares {
    // `S` is the share-type of the fund, and `T` is the type of currency it is priced in
    // For example 'BITO' might be the fund, and 'USDC' is the currency.
    // In this case, you would deposit Balance<USDC> to receive Balance<BITO>.
    // You could also redeem Balance<BITO> to receive Balance<USDC>.
    // The Fund keeps track of the total value of its assets, pricing in USDC,
    // versus the number of shares outstanding, Balance<BITO>.
    //
    // Sometimes deposits can be accepted right away, othertimes not
    //
    // Root-level, shared object
    struct Fund<phantom S, phantom A> has key {
        id: UID,
        total_shares: Supply<S>, // also used to issue and redeem shares
        net_assets: u64, // denominated in `T`
        share_queue: Queue<S>,
        asset_queue: Queue<A>,
        anyone_can_deposit: bool,
        anyone_can_withdraw: bool
    }

    // action structs
    struct DEPOSIT {}
    struct WITHDRAW {}

    // ============= User Interface =============

    public fun request_deposit<S, A>(
        account: &mut Account<A>,
        fund: &mut Fund<S, A>,
        amount: u64,
        auth: &TxAuthority
    ) {
        if (!fund.anyone_can_deposit) {
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
    
    // Can only be called by a package's init function on publish
    public fun initialize<S: drop>(otw: S, ctx: &mut TxContext) {

    }

    public fun process_deposits() { }

    public fun process_withdrawals() { }

    public fun update_net_assets() { }
}

module economy::queue {
    use sui::linked_table::{Self as map, LinkedTable as Map};

    // Incoming is a map of depositors to deposits to be processed
    // Balance is a pool of active funds
    // Outoing is a map of people owed money to the funds they can claim
    struct Queue<phantom T> has store {
        incoming: Map<address, Balance<T>>,
        balance: Balance<T>,
        outgoing: Map<address, Balance<T>>
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
