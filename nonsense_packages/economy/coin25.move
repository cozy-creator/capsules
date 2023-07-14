// Aptos: Coin<T>, has a 'value' u64. It is store-only
// There is a CoinStore<T>, which is a key-only root-level object containing Coin<T>
// It has a 'freeze' boolean property.
// 
// Has a designated CoinInfo<T> metadata on-chain. This is always stored at the same
// address where `T` was published. This is the address of the account that published the
// package defining `T`. So for example, if my address is 0x123, any package I publish will
// be under 0x123. (I think?)
// It can accessed like borrow_global_mut<CoinInfo<T>>(&package_id)
//
// Note that because Aptos-IDs are just an increment on the creation-address, a busy-address
// can end up congesting itself by creating a bunch of objects sequentially. Sui's hash-IDs
// are better

module economy::coin25 {
    // Root-level shared object
    struct Coin25<phantom T> has key {
        id: UID,
        balance: Balance<T>,
        frozen: bool
    }

    struct Account has key {
        id: UID
    }

    // Action structs
    struct FREEZE {}

    public fun deposit() {}

    public fun withdraw() {}

    public fun deposit_from_coin() {}

    public fun withdraw_to_coin(): Coin<T> {}

    // =========== Package Authority Actions ===========
    // These functions can only be called with `T` package-authority. Meaning they can only be
    // called by (1) on-chain, by the package-itself, or (2) off-chain, by whoever owns the
    // Organization object that controls the package.

    public fun freeze<T>(coin: &mut Coin25<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        coin.frozen = true;
    }

    public fun freeze<T>(coin: &mut Coin25<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        coin.frozen = true;
    }
}

// Shared object that manages multiple balance types at once
module economy::account {

    // Action structs
    struct WITHDRAW {}

    public fun transfer_to_account(from: &mut Account, to: &mut Account, amount: u64, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&account.id, auth), ENO_OWNER_AUTHORITY);
    }

    public fun withdraw_to_coin<T>(from: &mut Account, amount: u64, auth: &TxAuthority): Coin<T> {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&account.id, auth), ENO_OWNER_AUTHORITY);
    }

}

// The intention for this is some combination of on-chain or off-chain logic that withdraws
// money from user's accounts, and tries to earn yield using it.
//
// For Typus and Cetus, your money is permanently stored inside of specific liquidity pools,
// and must be added or removed by hand.
//
// For Deepbook, you really only want to keep money in there to cover an open-order.
//
// Scenario: I deposit 1 ETH, worth $1,700. Market-maker now owes me 1 ETH.
// Market-maker sells ETH for USDC and BTC, and market-makes those.
// Later on, I want to withdraw my 1 ETH. The market-maker must (1) cancel open orders,
// (2) withdraw funds, (3) and swap back to ETH.
// There is no guarantee that I will get my 1 ETH back; the market-maker may have lost money,
// ETH may have moved up in price against BTC and USD, etc.
// For sanity, we should pick a currency like USD, and measure the value against that.
// So if I give the market-maker 1 ETH, I am owed $1,700 (its USD value at the time), not 1 ETH.
// Later, when I withdraw, I am entitled to my fractional share of the market-maker's total USD balance.
// That is, if all assets owned by the market-maker were liquidated, I am owed a percentage of that.
// 
module economy::money_manager {

    // constants
    const ONE_DAY: u64 = 1000 * 60 * 60 * 24;

    // ========== For Depositors ==========

    public fun deposit_to_market_maker<T>(
        account: &mut Account,
        maker: &mut Account,
        amount: u64,
        auth: &TxAuthority
    ) {
        account::transfer_to_account(account, maker, amount, auth);
        account::add_claim_against(maker, account, amount, auth);
    }

    public fun withdraw_all_from_market_maker<T>(
        account: &mut Account,
        maker: &mut Account,
        auth: &TxAuthority
    ) {
    }

    // Funds must be instantly available
    public fun withdraw_from_market_maker<T>(
        account: &mut Account,
        maker: &mut Account,
        amount: u64,
        auth: &TxAuthority
    ) {

    }

    // ========== Trading Bot Functions ==========

    // Aborts if there are not enough funds in the pool or account to cover the order (price * amount)
    public fun place_buy_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        price: u64,
        amount: u64,
        account: &mut Account,
        clock: &Clock,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        // What if this doesn't exist? Should we make this upon creation? Static field?
        let account_cap = dynamic_field::borrow<u64, AcountCap>(&account.id, 0);

        // Ensure sufficient available funds
        let (_, _, balance, _) = deepbook::account_balance(pool, account_cap);
        if (balance < price * amount) {
            let coin = account::withdraw_to_coin(account, price * amount - balance, auth);
            deepbook::deposit_quote(pool, coin, account_cap);
        }

        let (_, _, success, order_id) = deepbook::place_limit_order(
            pool,
            ???, // client-orderid?
            price,
            amount,
            ???, // self-matching?
            true, 
            clock::timestamp_ms(clock) + ONE_DAY, 
            ???, // restriction?
            clock, 
            account_cap, 
            ctx);
    }

    public fun place_sell_order() {

    }
}