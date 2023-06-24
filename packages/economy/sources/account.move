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

    // =========== Owner API ===========

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

    // =========== Package Authority Actions ===========
    // These functions can only be called with `T` package-authority. Meaning they can only be
    // called by (1) on-chain, by the package-itself, using a Witness struct, or (2) off-chain, by
    // whoever owns the Organization object that contains the package.

    public fun freeze_<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = true;
    }

    public fun unfreeze<T>(account: &mut Account<T>, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<T, FREEZE>(auth), ENO_PACKAGE_AUTHORITY);

        account.frozen = false;
    }
}