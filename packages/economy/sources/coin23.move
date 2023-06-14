// How do we stop people from making balances unavailable to edit by an external source?
// This is a constraint for Circle; they always need to be able to access and freeze an
// account. Ways:
// - Have two different structs, one that can be split + store, another that cannot
// - Have an individual property per object that prevents split (but cannot do store)
// - Have a global config that prevents split at runtime (but cannot do store)
//

// Use Cases:
// - User paying merchant, or peer-to-peer transfer (instant transfer)
// - User issuing authorization for unfunded future one-off payments (claim)
// - User issuing authorization for funded future payments (hold and claim)
// - User issuing authorization for unfunded recurring payments (claim)
// - Splitting organization funds amongst a group of individuals

// Types of transfers:
// - unfunded one-off transfers ($$ is known, single time, $$ not guaranteed)
// - funded one-off transfers (holds) ($$ range is known, single time, $$ guaranteed)
// - recurring unfunded transfers ($$ is known, multiple times, $$ not guaranteed)
// - "pay as you go" ($$ is not known, multiple times, $$ not guaranteed)
// (amount range, payment dates, end, funded / not)
// payment dates = once every XX regular interval
// end = once, until user cancels (at will), until $TOTAL is collected, request to close but must settle $$
// funded = subject to hold expiration date
//
// amount range - use partial claim
// payment date - refresh available amount for claim and amount
// end - one full time, until exhausted, cancelled, until total, request to close
// funded -> move funds to hold, indexed by claim-id, expiry (can be used with refresh?)

// Types:
// Claim - specified amount, once, expire / cancelled by owner / used, unfunded
// 

// Future Thoughts (TO DO):
// Should we add some mechanism to make deposits permissioned? A DEPOSIT action?
// Should anyone be allowed to create an account for coins of type T, or should that be
// restricted, for who can hold what?

// SPL Token 22:
// Mint, Burn / Transfer from any account
// Approval; delegation of a specified balance (or everything)
// Freeze / Unfreeze
//
// Confidential balance
// Transfer fee
// Transfer restrictions (non-transferable) / Market-confounding mechanism
//
// Memo (??) (seems to be a non-functional message?) (requires deposit-authority?)
// Interest bearing (??) (<---- display standard for this)
// default account state (you need permission to open a token balance)

// Be able to send people money via email / message (a link that only they can claim)

// Cancel status?

// Thought: is package-witness too powerful when used with organization? Organization effectively has
// admin-control over doing stuff that we might want to be on-chain only.

module economy::coin23 {
    use sui::balance::{Self, Balance};
    use sui::dynamic_field;
    use sui::math;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;

    use sui_utils::dynamic_field2;

    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::ownership;

    const ENO_WITHDRAW_AUTHORITY: u64 = 0;
    const EINSUFFICIENT_FUNDS: u64 = 1;
    const ENO_CLAIM_AUTHORITY: u64 = 2;

    // Account designed for Circle / USDC
    // Root-level shared object
    struct Account<phantom T> has key {
        id: UID,
        inbound_funds: Balance<T>,
        outbound_funds: VecMap<address, Hold<T>>,
        rev_share: VecMap<address, u64>, // address -> bps owed per address
        balance: Balance<T>
    }

    struct Hold<phantom T> has store {
        expiration_ms: Option<u64>, // the hold expires, and the funds can be returned to `balance`
        balance: Balance<T>
    }

    // Dynamic field keys
    struct BalanceKey has store, copy, drop { addr: address }
    struct Key has store, copy, drop { for: address } // maps to a more advanced claim object

    // - The Account owner cannot cancel a claim unless they have possession of it.
    // - Claim objects have referntial authority; only pass a &mut reference to them when redeeming them.
    // - Claims are not guaranteed to be funded; the account's balance may be insufficient.
    // - If you want to guarantee an account is funded, use a hold record instead.
    // - Claims can be used partially; the full amount does not need to be redeemed at once.
    // - Claims cannot be dropped; they must be explicitly destroyed
    // Shared, root-level object
    struct Claim<phantom T> has key, store {
        id: UID,
        for_account: ID,
        amount: u64,
        refresh: Option<Refresh>,
        expiration_ms: Option<u64> // claim is no longer valid after this date
    }

    struct Refresh has store, copy, drop {
        amount_per_refresh: u64,
        refresh_interval_ms: u64,
        last_refresh_ms: u64,
        refreshes_remaining: Option<u64>,
        bond_amount: u64
    }

    // Thse are stored inside of the account, and can always be cancelled by the account owner.
    struct RecurringClaim<phantom T> has store, drop {
        for_account: ID,
        remaining_amount: u64
    }

    struct HoldRecord has store, drop {
        amount: u64,
        expires_on_ms: u64
    }

    struct Entitlement {

    }

    // 100 , 50 / 50
    // 50, 0 / 50
    // 60, 5 / 55
    // total / amount-withdrawn

    // Action types
    struct WITHDRAW {} // Delegating this action allows the agent to fully withdraw all funds
    struct CLAIM {} // used to claim held funds

    // ======== Consumer (Account Owner) API ========

    public fun create<T>(ctx: &mut TxContext): Account<T> {
        Account { id: object::new(ctx), balance: balance::zero(), frozen: false }
    }

    public fun return_and_share(account: Account) {
        transfer::share_object(account);
    }

    public fun transfer(sender: &mut Account, amount: u64, receiver: &mut Account, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&sender.id, auth), ENO_WITHDRAW_AUTHORITY);

        transfer_internal(sender, amount, receiver);
    }

    public fun create_claim<T>(
        sender: &mut Account<T>,
        amount: u64,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Claim<T> {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&sender.id, auth), ENO_WITHDRAW_AUTHORITY);
        assert!(balance::value(&sender.balance) >= amount, EINSUFFICIENT_FUNDS);

        Claim {
            id: object::new(ctx),
            for_account: object::uid_to_id(&sender.id),
            amount, 
            funded: false 
        }
    }

    public fun hold_funds<T>(account: &mut Account<T>, amount: u64): Claim<T> {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&sender.id, auth), ENO_WITHDRAW_AUTHORITY);

        balance::join(&mut account.held_balance, balance::split(&mut account.balance, amount));
    }

    public fun create_hold() {

    }

    public fun redeem_hold() {

    }

    public fun cancel_hold() {

    }

    // Can be done by the owner
    public fun cancel_expired_hold() {

    }

    public fun redeem_partial_claim(
        account: &mut Account<T>,
        claim: &mut Claim<T>,
        amount: u64,
        to: &mut Account<T>
    ) {
        claim.amount = claim.amount - amount;

        let key = Key { claim_id: object::uid_to_id(&claim.id) };
        let addr_maybe = dynamic_field2::get_maybe<Key, address>(&account.id, key);
        if (option::is_some(addr_maybe)) {
            if (claim.amount == 0) { dynamic_field::remove<Key, address>(&mut account.id, key); };

            let addr = option::destroy_some(addr_maybe);
            assert!(tx_authority::can_act_as_address<CLAIM>(addr, auth), ENO_CLAIM_AUTHORITY);

            balance::join(&mut to.balance, balance::split(&mut account.held_balance, amount));
        } else {
            balance::join(&mut to.balance, balance::split(&mut account.balance, amount));
        };
    }

    public fun redeem_Claim() {

    }

    public fun create_recurring_claim() {

    }

    public fun cancel_recurring_claim() {

    }

    public fun destroy() { }

    // ======== Crank Entitlement ========
    // Crank is a compute optimization that moves the cost of dividing up funds from deposit
    // transactions to withdrawal transactions.

    public fun crank_state<T>(account: &mut Account<T>, clock: &Clock) {
        if (balance::value(account.inbounds_funds) == 0) { return };

        let i = 0;
        while (i < vec_map::size(&account.rev_share)) {
            let (addr, split_bps) = vec_map::get_entry_by_idx(&account.rev_share, i);
            let amount = ((split_bps as u128) * (account.rev_share.total_deposited as u128) / 10_000u128 as u64);

            let key = BalanceKey { addr };
            if (!dynamic_field::exists_(&account.id, key)) {
                dynamic_field::add(&mut account.id, key, balance::zero());
            };
            let balance = dynamic_field::borrow_mut<BalanceKey, Balance<T>>(&mut account.id, key);
            balance::join(balance, balance::split(&mut account.inbound_funds, amount));

            i = i + 1;
        };

        balance::join(&mut account.balance, balance::withdraw_all(&mut account.inbound_funds));
    }

    public fun withdraw_entitlement<T>(
        account: &mut Account<T>,
        for: address,
        to: &mut Account<T>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<WITHDRAW>(for, auth), ENO_WITHDRAW_AUTHORITY);

        // TO DO: this will fail if this doesn't exist
        let balance = vec_map::borrow_mut(&mut account.outbound_funds, for);
        deposit(to, balance::withdraw_all(balance));
    }

    public fun deposit<T>(account: &mut Account<T>, balance: Balance<T>) {
        balance::join(&mut account.inbound_funds, balance);
        crank_state(account);
    }

    // Does not run crank, hence using less compute
    public fun deposit_simple(account: &mut Account<T>, balance: Balance<T>) {
        balance::join(&mut account.inbound_funds, balance);
    }

    // Adding a new hold can never shorten the duration of an existing hold, only lengthen it
    public fun hold_funds<T>(
        account: &mut Account<T>,
        amount: u64,
        duration_ms: u64, 
        clock: &Clock, 
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Claim<T> {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&account.id, auth), ENO_WITHDRAW_AUTHORITY);

        let claim = Claim { 
            id: object::new(ctx),
            for: object::uid_to_id(&account.id),
            amount,
            expiration_ms: clock::timestamp_ms(clock) + duration_ms,
        };

        let balance = balance::split(&mut account.balance, amount);
        let outbound = vec_map::borrow_mut(&mut account.outbound_funds, for);
        let expiration_ms = clock::timestamp_ms(clock) + duration_ms;
        balance::join(&mut outbound.balance, balance);
        outbound.expiration_ms = math::max(outbound.expiration_ms, expiration_ms);
    }



    // ======== Merchant API ========

    public fun redeem_partial_claim<T>(
        account: &mut Account<T>, 
        claim: &mut Claim<T>,
        amount: u64,
        receiver: &mut Account<T>
    ) {
        claim.amount = claim.amount - amount;
        transfer_internal(account, amount, receiver);
    }

    public fun redeem_claim<T>(account: &mut Account<T>, claim: Claim<T>, receiver: &mut Account<T>) {
        let Claim { for, amount } = claim;
        assert!(object::uid_to_id(&account.id) == for, EINVALID_CLAIM);

        transfer_internal(account, amount, receiver);
    }

    public fun merge_claims() {

    }

    public fun split_claim() {

    }

    // ======== Getters ========

    public fun claim_amount<T>(claim: &Claim<T>): u64 {
        claim.amount
    }

    public fun claim_account_id<T>(claim: &Claim<T>): ID {
        claim.for_account
    }

    // ======== Admin API ========

    public fun freeze_balance() {

    }

    public fun freeze_partial_balance() {
        
    }

    public fun unfreeze_balance() {

    }

    public fun unfreeze_partial_balance() {

    }

    // ======== Coin23 API ========

    // Upgraded version of sui::coin::Coin
    // Single-writer object
    struct Coin23<phantom T> has key, store {
        id: UID,
        balance: Balance<T>
    }

    public fun create_coin() {
        assert!(ownership::can_act_as_owner<WITHDRAW>(&sender.id, auth), ENO_WITHDRAW_AUTHORITY);
    }

    public fun consume_coin() {

    }

    // ======== Internal Functions ========

    fun transfer_internal(sender: &mut Account, amount: u64, receiver: &mut Account) {
        balance::join(&mut receiver.balance, balance::split(&mut sender.balance, amount));
    }

    // ======== Convenience Entry Functions ========

}