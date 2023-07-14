// Creates a hold in the specified account, returning a claim object which can be used to redeem
// the held funds prior to the expiry date.

module economy::claim {
    use sui::clock::Clock;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::TxContext;

    use ownership::tx_authority::TxAuthority;
    use ownership::ownership;

    use economy::coin23::{Self, Coin23, CurrencyRegistry};

    // Error constants
    const EWRONG_ACCOUNT: u64 = 0;

    // `for`, `amount`, and `expiry_ms` are not necessary; they exist for informational purposes.
    // Without them, it's hard for the `Claim` holder to know what Coin23 they can redeem against,
    // how much there is to redeem, and when their claim has expired.
    // In way, we are denormalizing the data here; this same information is both in a 'Hold' inside
    // of 'Coin23<T>' as well as in a separate 'Claim' object, however, this makes holding funds
    // more ergonomic
    // Single-writer object, can be publicy transferred
    struct Claim<phantom T> has key, store {
        id: UID,
        for_account: ID, // Coin23<T>'s object-id
        amount: u64,
        expiry_ms: u64
    }

    public fun create<T>(
        account: &mut Coin23<T>,
        amount: u64,
        duration_ms: u64,
        clock: &Clock,
        registry: &CurrencyRegistry,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Claim<T> {
        let uid = object::new(ctx);
        let expiry_ms = coin23::add_hold(
            account, object::uid_to_address(&uid), amount, duration_ms, clock, registry, auth);

        Claim {
            id: uid,
            for_account: object::id(account),
            amount,
            expiry_ms
        }
    }

    public entry fun redeem_claim<T>(
        claim: &mut Claim<T>,
        from: &mut Coin23<T>,
        to: &mut Coin23<T>,
        amount: u64,
        clock: &Clock,
        registry: &CurrencyRegistry,
        ctx: &mut TxContext
    ) {
        let merchant_addr = object::uid_to_address(&claim.id);
        let auth = ownership::begin_with_object_id(&claim.id);
        coin23::withdraw_from_held_funds_(from, to, merchant_addr, amount, clock, registry, &auth, ctx);
        claim.amount = claim.amount - amount; // internal account
    }

    public entry fun redeem_entire_claim<T>(
        claim: Claim<T>,
        from: &mut Coin23<T>,
        to: &mut Coin23<T>,
        clock: &Clock,
        registry: &CurrencyRegistry,
        ctx: &mut TxContext
    ) { 
        let Claim { id: uid, for_account: _, amount, expiry_ms: _ } = claim;
        let merchant_addr = object::uid_to_address(&uid);
        let auth = ownership::begin_with_object_id(&uid);
        coin23::withdraw_from_held_funds_(from, to, merchant_addr, amount, clock, registry, &auth, ctx);
        object::delete(uid);
    }

    // We not strictly required to release the held funds from the Coin23, it's polite to do so,
    // so we do that here
    public entry fun destroy<T>(claim: Claim<T>, account: &mut Coin23<T>) {
        assert!(claim.for_account == object::id(account), EWRONG_ACCOUNT);

        let Claim { id: uid, for_account: _, amount: _, expiry_ms: _ } = claim;
        let auth = ownership::begin_with_object_id(&uid);
        coin23::release_held_funds(account, object::uid_to_address(&uid), &auth);
        object::delete(uid);
    }

    // ========= Getters ========= 

    // Returns Coin23 ID, amount remaining, and expiry timestamp in ms
    public fun info<T>(claim: &Claim<T>): (ID, u64, u64) {
        (claim.for_account, claim.amount, claim.expiry_ms)
    }
}