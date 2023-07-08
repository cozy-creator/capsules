// Balance can be frozen by the coin-creator
// Rebilling
// Funded holds
// Fees on send
// Market-confounding (fixed price)
// Non-transferable
// 
// Out of scope:
// Privacy at some point later (confidential + anonymous transfers)
// Consumer protection
// Dev protection (infinite money glitch)
// Crank (hydra), split-balance, joint-accounts

// Plan:
// - Inside of an account, place a 'this person can remove XX amount' record. Must include
// an expiration time, refresh time, refresh rate, locked balance
// - Cranks exist with inbound and outbound funds
// - Transfer authority exists for balances; plugin
// - Cancellable by guardian

// Thoughts:
// We opted for a simple uniform transfer system here. Transfers check for frozen-balances,
// non-transferability, and fees. This fits most use-cases. A more advanced system would have
// its own transfer-module.

module economy::account {
    use std::option;
    use std::type_name;

    use sui::balance::Balance;
    use sui::clock;
    use sui::linked_table::{Self as map, LinkedTable as Map};
    use sui::object::UID;

    use sui_utils::linked_table2 as map2;

    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::ownership::TRANSFER;

    // Constants
    const ONE_DAY: u64 = 1000 * 60 * 60 * 24;

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const ENO_PACKAGE_AUTHORITY: u64 = 1;
    const EINVALID_REBILL: u64 = 2;
    const EACCOUNT_FROZEN: u64 = 3;

    // Root-level shared object
    struct Account<phantom T> has key {
        id: UID,
        available: Balance<T>,
        held: Map<address, Balance<T>>,
        hold_expiry: Map<u64, vector<address>>, // u64 is a timestamp in ms when the hold expires
        rebills: Map<ID, Rebill>,
        frozen: bool
    }

    // This is useful for cancel-at-will rebills, such as a gym membership. If the merchant misses a rebill
    // window, the rebill amounts _do not_ stack.
    // The merchant is not required to bill the full available amount; the available amount is a cap.
    // This works for usage-based billing, where the total amount due is not known ahead of time.
    // Neither fixed-rebill nor usage-based-rebill are funded or guaranteed.
    //
    // This is not useful for buy-now-pay-later uncollateralized payment plans. In that case, you'd
    // specify some maximum amount to be paid in total, along with a payment cadence, and allow the loan
    // to be paid back early, and remove the ability to cancel-at-will.
    // 
    // Has its own identifier (id) for easy reference because a merchant may have several rebills against
    // a single Account
    struct Rebill has store {
        id: UID,
        merchant: address,
        available: u64, // available to be withdrawn in the current period
        refresh_amount: u64, // max balance that can be withdrawn per refresh
        refresh_cadence: u64, // ms interval
        last_refresh: u64 // ms timestamp
    }

    // Action types for end-users
    struct DEPOSIT {} // used by account-owner to deposit
    struct WITHDRAW {} // used by account-owner and merchant to withdraw
    struct FREEZE {} // for Account<T>, this is used by T's declaring-package to freeze accounts

    // =========== End-User API ===========
    // Used by the owner of the account

    public fun destroy_account() {}

    public fun deposit_from_account() {
        // assert!(ownership::can_act_as_owner<WITHDRAW>(&account.id, auth), ENO_OWNER_AUTHORITY);
    }

    public fun deposit_from_balance() {}

    public fun deposit_from_coin() {}

    // Withdraws can only be performed by the account owner (if it is allowed) or by the package-auth
    // of `T` (if it is allowed) which includes `Witness` (on-chain) or Organization (off-chain).
    public fun withdraw_to_account<T>(
        from: &mut Account<T>,
        to: &mut Account<T>,
        amount: u64,
        registry: &CurrencyRegistry,
        auth: &TxAuthority
    ) {
        assert!(!from.frozen && !to.frozen, EACCOUNT_FROZEN);

        let key = type_name::get<T>();
        if (dynamic_field::exists_(&registry.id, key)) {
            // `T` is a controlled currency
            let controls = dynamic_field::borrow<TypeName, CurrencyControls<T>>(&registry.id, key);
            
            // check if user transfer is allowed
            assert!((controls.user_can_transfer && ownership::can_act_as_owner<WITHDRAW>(&from.id, auth))
                || (controls.creator_can_withdraw && ownership::can_act_as_package<T, WITHDRAW>(auth)),
                ENO_OWNER_AUTHORITY);
        } else {
            // `T` is not a controlled currency
        }
    }

    public fun withdraw_to_balance() {}

    public fun withdraw_to_coin() {}

    // =========== Merchant API ===========
    // Used by merchants to deposit to or withdraw from accounts
    // Rebill: amount max, refresh cadence (user can always cancel)
    // Hold: amount max, expiry (end-user can always withdraw)

    // Refresh cadence must be 24 hours or longer, amount must be more than 0.
    // We do not impose a limit on the number of rebills that can be created.
    public fun create_rebill<T>(
        account: &mut Account<T>,
        merchant: address,
        max_amount: u64,
        refresh_cadence: u64,
        clock: &Clock,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        assert!(tx_authority::can_act_as_owner<WITHDRAW>(&account.id, auth), ENO_OWNER_AUTHORITY);
        assert!(refresh_cadence >= ONE_DAY, EINVALID_REBILL);
        assert!(max_amount > 0, EINVALID_REBILL);

        let rebill = Rebill {
            id: object::new(ctx),
            merchant,
            available: 0,
            refresh_amount: max_amount,
            refresh_cadence,
            last_refresh: clock::timestamp_ms(clock)
        };

        map::push_back(&mut account.rebills, object::uid_to_inner(&rebill.id), rebill);
    }

    // Rebill can be cancelled either by the account owner or the merchant
    public fun cancel_rebill(account: &mut Account<T>, rebill_id: address, auth: &TxAuthority) {
        let rebill = map::remove(&mut account.rebill, rebill_id);
        let Rebill { 
            id, merchant, available: _, refresh_amount: _, refresh_cadence: _, last_refresh: _ } = rebill;

        assert!(ownership::can_act_as_owner<WITHDRAW>(&account.id, auth) 
            || tx_authority::can_act_as_address<WITHDRAW>(merchant, auth), ENO_OWNER_AUTHORITY);

        object::delete(id);
    }

    public fun create_funded_hold() {

    }

    public fun withdraw_from_hold() {

    }

    // =========== Package Authority Actions ===========
    // These functions can only be called on `Coin<T>` with `T` package-authority. Meaning they can only
    // be called by (1) on-chain, by the package-itself, using a Witness struct, or (2) off-chain, by
    // whoever owns the Organization object that contains the package.

    // How can I prove that a currency was created outside of this module?
    // We need a 'see this doesnt exist' stub
    // A global directory is one solution
    // The existence of a non-zero coin is one solution
    // We can create a stub-config using a non-zero coin ??

    // Stores all CurrencyConfig objects
    // Shared, root-level singleton object.
    struct CurrencyRegistry has key {
        id: UID
    }

    // Note that `controlled` must be set to `true` upon creation in order to enable control of the
    // currency.
    //
    // Controlled currency:
    // - `Account` cannot be converted to `Balance` or `Coin`. It can be converted to `Balance` by a
    // trusted (white-listed) module. This limits what DeFi apps can use a given currency, creating a
    // permissioned system. But it protects creator controls from being bypassed.
    // - Account balance cannot be converted into 'balance' or 'coin'. It's always inside of an `Account`
    // - Can impose transfer fees
    // - Can freeze and withdraw balances
    // - Can make non-transferable
    // - Can change white-list
    //
    // Uncontrolled currency:
    // - Users can convert `Account` to 'Balance' or 'Coin'. This enables permissionless DeFi integration
    // - Creator cannot freeze, withdraw, or make account non-transferable
    // - there is no integration white-list; integration is permissionless
    //
    // Currencies can go from non-permissive -> permissive, but not in reverse. That is, currencies can
    // never become less permissive
    struct CurrencyControls<phantom T> has store {
        creator_can_withdraw: bool,
        creator_can_freeze: bool,
        user_can_transfer: bool,
        transfer_fee_bps: u64, // 100 bps = 1%
        pay_fee_to: Option<address>,
        integrated_auths: Map<address, bool> // this is a set, rather than a Map. `bool` has no meaning
    }

    struct Treasury<phantom T> has store {
        can_mint: bool,
        can_burn: bool,
        supply: Supply<T>
    }

    // Action types for creators
    struct CREATE_ACCOUNT {}

    public fun create_currency() {}

    public fun create_currency_from_treasury_cap() {}

    public fun create_stub_config() {
        transfer::freeze(config);
    }

    // Accounts may optionally require package-permission for a user to create a new account.
    // If this is disabled, anyone can create an account
    // TO DO: what about for balance-types that don't have a currency config?
    public fun create_account<T>(
        config: &CurrencyConfig<T>,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Account<T> {
        // assert!(tx_authority::can_act_as_owner<CREATE_ACCOUNT>(&config.id, auth), ENOT_CREATOR);
        assert!(tx_authority::can_act_as_package<T, CREATE_ACCOUNT>(auth), ENOT_CREATOR);

        Account { 
            id: object::new(ctx),
            balance: balance::zero(),
            frozen: false
        }
    }

    public fun return_and_share<T>(account: Account<T>, owner: address, config: &CurrencyConfig) {

    }

    public fun freeze_<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = true;
    }

    public fun unfreeze<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = false;
    }

    // =========== Convenience Entry Functions ===========

    public entry fun charge_and_rebill<T>(
        merchant: &mut Account<T>,
        customer: &mut Account<T>,
        amount: u64,
        rebill_cadence: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        let merchant_addr = option::destroy_some(ownership::get_owner(&merchant.id));

        transfer_to_account(customer, merchant, amount, auth);
        create_rebill(customer, merchant_addr, amount, refresh_cadence, clock, auth, ctx);
    }
}

    // =========== Transfer Authority Functions ===========
    // This allows `Account` to be extended by transfer-authorities for custom rules

    // public fun transfer<T>(from: &mut Account<T>, to: &mut Account<T>, amount: u64, auth: &TxAuthority) {
    //     assert!(ownership::can_act_as_transfer_auth<TRANSFER>(uid, auth), ENO_TRANSFER_AUTHORITY);

    //     balance.join(&mut to.available, balance::split(&mut from.available, amount))
    // }