// Balance can be frozen by the coin-creator
// Rebilling, funded holds
// Crank (hydra)
// Fees on send
// Market-confounding (fixed price)
// Non-transferable
// 
// Out of scope:
// Privacy at some point later (confidential + anonymous transfers)
// Consumer protection
// Dev protection (infinite money glitch)

// Plan:
// - Inside of an account, place a 'this person can remove XX amount' record. Must include
// an expiration time, refresh time, refresh rate, locked balance
// - Cranks exist with inbound and outbound funds
// - Transfer authority exists for balances; plugin
// - Cancellable by guardian

module economy::account {
    use sui::balance::Balance;
    use sui::object::UID;

    use ownership::tx_authority::{Self, TxAuthority};

    // error constants
    const ENO_PACKAGE_AUTHORITY: u64 = 0;

    // Root-level shared object
    struct Account<phantom T> has key {
        id: UID,
        balance: Balance<T>,
        frozen: bool
    }

    // Action structs
    struct DEPOSIT {} // used by account-owner to deposit
    struct WITHDRAW {} // used by account-owner to withdraw
    struct FREEZE {} // for Account<T>, this is used by T's declaring-package to freeze accounts

    // =========== End-User API ===========
    // Used by the owner of the account

    public fun create() {}

    public fun destroy() {}

    public fun deposit_from_account() {
        // assert!(ownership::can_act_as_owner<WITHDRAW>(&account.id, auth), ENO_OWNER_AUTHORITY);
    }

    public fun deposit_from_balance() {}

    public fun deposit_from_coin() {}

    public fun withdraw_to_account() {}

    public fun withdraw_to_balance() {}

    public fun withdraw_to_coin() {}

    // =========== Merchant API ===========
    // Used by merchants to deposit to or withdraw from accounts

    // =========== Package Authority Actions ===========
    // These functions can only be called on `Coin<T>` with `T` package-authority. Meaning they can only
    // be called by (1) on-chain, by the package-itself, using a Witness struct, or (2) off-chain, by
    // whoever owns the Organization object that contains the package.

    struct CoinData<phantom T> has key {
        id: UID
    }

    public fun create_coin() {}

    public fun create_from_treasury_cap() {}

    public fun freeze_<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = true;
    }

    public fun unfreeze<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = false;
    }
}