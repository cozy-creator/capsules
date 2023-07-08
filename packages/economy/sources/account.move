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
// - We opted for a simple uniform transfer system here. Transfers check for frozen-balances,
// non-transferability, and fees. This fits most use-cases. A more advanced system would have
// its own transfer-module, just like Capsules does.
// - Accounts are non-transferrable; you transfer balances within Accounts rather than ownership of
// the entire account.

module economy::account {
    use std::option;
    use std::type_name;

    use sui::balance::Balance;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::linked_table::{Self as map, LinkedTable as Map};
    use sui::object::UID;
    use sui::transfer;

    use sui_utils::linked_table2 as map2;

    use ownership::action::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::ownership::TRANSFER;

    // Constants
    const ONE_DAY: u64 = 1000 * 60 * 60 * 24;

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const ENO_PACKAGE_AUTHORITY: u64 = 1;
    const EINVALID_REBILL: u64 = 2;
    const EACCOUNT_FROZEN: u64 = 3;
    const EINVALID_TRANSFER: u64 = 4;
    const EINVALID_EXPORT: u64 = 5;
    const ENO_MERCHANT_AUTHORITY: u64 = 6;

    // Root-level shared object
    struct Account<phantom T> has key {
        id: UID,
        available: Balance<T>,
        held: Map<address, Balance<T>>,
        hold_expiry: Map<u64, vector<address>>, // u64 is a timestamp in ms when the hold expires
        rebills: Map<address, vector<Rebill>>, // merchant-address -> rebills available
        frozen: bool
    }

    // This is useful for cancel-at-will rebills, such as a gym membership. If the merchant misses a rebill
    // window, the rebill amounts _do not_ stack. Amounts available refresh, rather than stack, between
    // rebill cycles.
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
    struct Rebill has store, copy, drop {
        available: u64, // available to be withdrawn in the current period
        refresh_amount: u64, // max balance that can be withdrawn per refresh
        refresh_cadence: u64, // ms interval
        last_refresh: u64 // ms timestamp
    }

    // Action types for end-users
    struct WITHDRAW {} // used by account-owner and merchant to withdraw

    // =========== End-User API ===========
    // Used by the owner of the account

    // You can create an account for any type `T`, however there is no guarantee that a currency
    // of that type actually exists (lol).
    public fun create_account<T>(ctx: &mut TxContext): Account<T> {
        Account { 
            id: object::new(ctx),
            available: balance::zero(),
            held: map::new(),
            hold_expiry: map::new(),
            rebills: map::new(),
            frozen: false
        }
    }

    public fun return_and_share<T>(account: Account<T>, owner: address) {
        let auth = tx_authority::being_with_package_witness_<Witness>(Witness {});
        let typed_id = typed_id::new(&account);

        // Accounts are non-transferable, hence transfer-auth is set to @0x0
        ownership::as_shared_object_<Account>(&mut account.id, typed_id, owner, @0x0, &auth);

        transfer::share_object(account);
    }

    // Deposits are permissionless
    public fun import_from_balance<T>(account: &mut Account<T>, balance: Balance<T>) {
        assert!(!account.frozen, EACCOUNT_FROZEN);

        balance::join(&mut account.available, balance);
    }

    public entry fun import_from_coin<T>(account: &mut Account<T>, coin: Coin<T>) {
        assert!(!account.frozen, EACCOUNT_FROZEN);

        balance::join(&mut account.available, coin::into_balance(coin));
    }

    // Requires permission from the `Account` owner and that user-transfers are allowed OR
    // requires permission from the package itself, and that creator-transfers are allowed.
    // This is an Account -> Account transfer, and hence keeps all balances within our closed system,
    // allowing creators to ensure their conditions are followed.
    public fun transfer<T>(
        from: &mut Account<T>,
        to: &mut Account<T>,
        amount: u64,
        registry: &CurrencyRegistry,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        let (allowed, fee, fee_addr) = is_valid_transfer(from, amount, registry, auth);
        assert!(allowed, EINVALID_TRANSFER);
        assert!(!from.frozen && !to.frozen, EACCOUNT_FROZEN);

        pay_fee(account, fee, fee_addr, ctx);
        balance::join(&mut to.available, balance::split(&mut from.available, amount - fee));
    }

    public fun export_to_balance<T>(
        account: &Account<T>,
        registry: &CurrencyRegistry,
        amount: u64,
        auth: &TxAuthority
    ): Balance<T> {
        assert!(is_valid_export(account, registry, auth), EINVALID_EXPORT);
        assert!(!account.frozen, EACCOUNT_FROZEN);

        balance::split(&mut account.available, amount)
    }

    public fun export_to_coin<T>(
        account: &Account<T>,
        registry: &CurrencyRegistry,
        amount: u64,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Coin<T> {
        assert!(is_valid_export(account, registry, auth), EINVALID_EXPORT);
        assert!(!account.frozen, EACCOUNT_FROZEN);

        coin::from_balance(balance::split(&mut account.available, amount), ctx)
    }

    // This doesn't work yet because shared-objects cannot be destroyed
    // Will abort if any funds are available or held. Frozen status is ignored since the account is empty.
    public fun destroy_empty_account<T>(account: Account<T>, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&account.id, auth), ENO_OWNER_AUTHORITY);

        let Account { id, available, held, hold_expiry, rebills, frozen: _ } = account;
        object::delete(id);
        balance::destroy_zero(available);
        map::destroy_empty(held);
        map::drop(hold_expiry);
        map::drop(rebills);
    }

    // This also doesn't work yet; shared objects cannot be destroyed
    // Aborts if any funds are currently held for someone else
    // This only works for the owner or currency-creator, not a DeFi-integration partner
    public fun destroy_account(account: Account<T>, registry: &CurrencyRegistry, auth: &TxAuthority): Balance<T> {
        assert!(is_valid_export(account, registry, auth), EINVALID_EXPORT);
        assert!(!account.frozen, EACCOUNT_FROZEN);

        let Account { id, available, held, hold_expiry, rebills, frozen: _ } = account;
        object::delete(id);
        map::destroy_empty(held);
        map::drop(hold_expiry);
        map::drop(rebills);

        available
    }

    // =========== Merchant API ===========
    // Used by merchants to deposit to or withdraw from accounts
    // Rebill: amount max, refresh cadence (user can always cancel)
    // Hold: amount max, expiry (end-user can always withdraw)

    // Refresh cadence must be 24 hours or longer, amount must be more than 0.
    // We do not impose a limit on the number of rebills that can be created.
    public fun add_rebill<T>(
        account: &mut Account<T>,
        merchant: address,
        max_amount: u64,
        refresh_cadence: u64,
        clock: &Clock,
        registry: &CurrencyRegistry,
        auth: &TxAuthority
    ) {
        assert!(refresh_cadence >= ONE_DAY, EINVALID_REBILL);
        assert!(max_amount > 0, EINVALID_REBILL);

        // Checks if the `Account` owner or creator authorized this
        let (allowed, _) = is_valid_transfer(account, max_amount, registry, auth);
        assert!(allowed, EINVALID_TRANSFER);
        assert!(!account.frozen, EACCOUNT_FROZEN);

        let rebill = Rebill {
            available: 0, // not available until next refresh
            refresh_amount: max_amount,
            refresh_cadence,
            last_refresh: clock::timestamp_ms(clock)
        };

        let rebills = map2::borrow_mut_fill<address, vector<Rebill>>(&mut account.rebills, merchant, vector[]);
        vector::push_back(&mut rebills, rebill);
    }
    
    public fun withdraw_with_rebill<T>(
        customer: &mut Account<T>,
        merchant: &mut Account<T>,
        rebill_index: u64, // incase multiple rebills exist for this merchant
        amount: u64,
        clock: &Clock,
        registry: &CurrencyRegistry,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        let (fee, fee_addr) = calculate_fee(amount, registry);
        assert!(allowed, EINVALID_TRANSFER);
        assert!(!customer.frozen && !merchant.frozen, EACCOUNT_FROZEN);

        let merchant_addr = option::destroy_some(ownership::get_owner(&merchant.id));
        assert!(tx_authority::can_act_as_address<WITHDRAW>(merchant_addr, auth), ENO_MERCHANT_AUTHORITY);

        let rebills = map::borrow_mut<address, vector<Rebill>>(&mut customer.rebills, merchant);
        let rebill = vector::borrow_mut(rebills, rebill_index);

        crank_rebill(rebill, clock);
        pay_fee(customer, fee, fee_addr, ctx);

        // Aborts if `amount` is greater than available rebill
        rebill.available = rebill.available - amount;

        balance::join(&mut merchant.available, balance::split(&mut customer.available, amount - fee));
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

    public fun cancel_hold() {

    }

    // =========== Package Authority Actions ===========
    // These functions can only be called on `Coin<T>` with `T` package-authority. Meaning they can only
    // be called by (1) on-chain, by the package-itself, using a Witness struct, or (2) off-chain, by
    // whoever owns the Organization object that contains the package.

    // User Transfer Enum. From less-permissive (0) to most permissive (1)
    const NO_TRANSFER: u8 = 0;
    const NO_EXPORT: u8 = 1;
    const OPEN_EXPORT: u8 = 2;

    // Stores all CurrencyConfig objects
    // Shared, root-level singleton object.
    struct CurrencyRegistry has key {
        id: UID
    }

    // Note that `controlled` must be set to `true` upon creation in order to enable control of the
    // currency.
    //
    // Controlled currency:
    // - Creator (package-id or org with package-id) can withdraw balances. Useful for games involving
    // off-chain logic.
    // - Creator can freeze / unfreeze balances. Frozen balances cannot be withdrawn by the owner or
    // creator. This is a business requirement for Circle. Note that existing holds will still be
    // available, even if an `Account` is frozen.
    // - Transfer-fee optionally imposes a fee for each transfer. This is only imposed on transfers,
    // and not when balances are exported.
    // - `user_transfer_enum` allows a user to export Account as `Balance` or `Coin` if greater than 1.
    // Note that currencies exported outside of `Account` cannot be controlled in any way by the creator,
    // hence allowing this is discouraged.
    // If `user_transer_enum` is > 0, then the user can also do Account <-> Account transfers
    // - `export_auths` is a set of addresses (package-id, orgs, or individals) that are allowed to
    // export `Account`. This is necessary to integrate with DeFi. The integrating-DeFi contract must
    // be careful to make sure that it does not allow users or other untrusted programs to export.
    // That is, you can only do `Account` -> Trusted-DeFi -> `Account` and not -> `Coin`.
    // This limits what DeFi apps can do with a given currency, creating a permissioned system, but it
    // protect's creator controls from being bypassed. I.e., someone could bypass freezing or transfer-
    // fees by simple forking this package and creating a version with CurrencyControls removed.
    //
    // Uncontrolled currency:
    // - Users can convert `Account` to 'Balance' or 'Coin'. This enables permissionless DeFi integration
    // - Creator cannot freeze, withdraw, or make account non-transferable
    // - there is no need for an integration white-list; integration is permissionless
    //
    // Currencies can go from non-permissive -> permissive, but not in reverse. That is, currencies can
    // never become less permissive
    struct CurrencyControls<phantom T> has store {
        creator_can_withdraw: bool,
        creator_can_freeze: bool,
        user_transfer_enum: u8,
        transfer_fee: Option<TransferFee>
        export_auths: Map<address, bool> // this is a set, rather than a Map. `bool` has no meaning
    }

    struct TransferFee has store, copy, drop {
        bps: u64, // 100 bps = 1%
        pay_to: address // will be exported as 'Coin' to this address, for simplicity
    }

    struct Treasury<phantom T> has store {
        can_mint: bool,
        can_burn: bool,
        supply: Supply<T>
    }

    // Action types for packages
    struct FREEZE {} // for Account<T>, this is used by T's declaring-package to freeze accounts

    public fun create_currency() {}

    public fun create_currency_from_treasury_cap() {}

    public fun freeze_<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = true;
    }

    public fun unfreeze<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = false;
    }

    // =========== Utility Functions ===========

    // Must remain private or else it allows unauthorized exports
    fun pay_fee<T>(account: &mut Account<T>, fee: u64, fee_addr: Option<address>, ctx: &mut TxContext) {
        if (fee > 0 && option::is_some(&fee_addr)) {
            let balance = balance::split(&mut account.available, fee);
            let coin = coin::from_balance(balance, ctx);
            transfer::transfer(coin, option::destroy_some(fee_addr));
        };
    }

    public fun crank_rebill(rebill: &mut Rebill, clock: &Clock) {
        let current_time = clock::timestamp_ms(clock);

        if (current_time >= rebill.last_refresh + rebill.refresh_cadence) {
            let cycles = ((current_time - rebill.last_refresh) / rebill.refresh_cadence) as u128;
            rebill.last_refresh = 
                rebill.last_refresh + (((rebill.refresh_cadence as u128) * cycles) as u64);
            rebill.available = rebill.refresh_amount;
        };
    }

    // =========== Getter Functions ===========

    public fun is_valid_export(account: &Account<T>, registry: &CurrencyRegistry, auth: &TxAuthority): bool {
        let key = type_name::get<T>();
        if (dynamic_field::exists_(&registry.id, key)) {
            let controls = dynamic_field::borrow<TypeName, CurrencyControls<T>>(&registry.id, key);

            (controls.user_transfer_enum > NO_EXPORT && ownership::can_act_as_owner<WITHDRAW>(&account.id, auth))
                || (controls.creator_can_withdraw && tx_authority::can_act_as_package<T, WITHDRAW>(auth))
        } else {
            ownership::can_act_as_owner<WITHDRAW>(&account.id, auth)
        }
    }

    // This is orthogonal to whether or not the transfer is allowed
    public fun calc_transfer_fee<T>(amount: u64, registry: &CurrencyRegistry): (u64, Option<address>) {

    }

    // Returns `true` if the transfer is allowed, `false` otherwise. Also returns a u64 which is the amount
    // of the transfer fee.
    public fun is_valid_transfer<T>(
        account: &Account<T>,
        amount: u64,
        registry: &CurrencyRegistry,
        auth: &TxAuthority,
    ): bool {
        let key = type_name::get<T>();
        if (dynamic_field::exists_(&registry.id, key)) {
            let controls = dynamic_field::borrow<TypeName, CurrencyControls<T>>(&registry.id, key);
            
            // check if the user or creator are allowed to withdraw, and have sufficient permission
            let allowed = (controls.user_transfer_enum > NO_TRANSFER && 
                ownership::can_act_as_owner<WITHDRAW>(&account.id, auth))
                || (controls.creator_can_withdraw && tx_authority::can_act_as_package<T, WITHDRAW>(auth));
            
            // Calculate transfer fee if it exists
            let (fee, fee_addr) = if (option::is_some(&controls.transfer_fee)) {
                let transfer_fee = option::borrow(&controls.transfer_fee);
                (((transfer_fee.bps as u128) * (amount as u128) / 10_000u128) as u64, 
                    option::some(transfer_fee.pay_to) )
            } else { 
                (0, option::none()) 
            };

            (allowed, fee, fee_addr)
        } else {
            let allowed = ownership::can_act_as_owner<WITHDRAW>(&from.id, auth), ENO_OWNER_AUTHORITY);

            (allowed, 0, option::none())
        }
    }

    // =========== Convenience Entry Functions ===========
    // Makes life easier for client-apps

    public entry fun create_account_<T>(owner: address, ctx: &mut TxContext) {
        let account = create_account(ctx);
        return_and_share(account, owner);
    }

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

    public entry fun grant_currency() { }
    
    public entry fun destroy_currency() { }
}