// We use a StructTag to specify the type requested in `ItemOffer` rather than a static type like
// `<phantom T>` so that people can make offers on abstract types like 'give me any Wood<T>'

module economy::item_offer {
    use std::option::{Self, Option};

    use sui::clock::{Self, Clock};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::typed_id;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use economy::coin23::{Coin23, CurrencyRegistry};
    use economy::claim::{Self, Claim};

    // Error constants
    const EINVALID_OFFER: u64 = 0;
    const EINCORRECT_OBJECT: u64 = 1;
    const EOFFER_EXPIRED: u64 = 2;

    // Root-level shared object
    struct ItemOffer<phantom T> has key {
        id: UID,
        send_to: address,
        claim: Option<Claim<T>>, // because shared objects cannot be destroyed
        for_id: Option<ID>,
        for_type: Option<StructTag>,
        amount_each: u64,
        quantity: u8,
        expiry_ms: u64
    }

    // Module authority
    struct Witness has drop {}

    // ======== For Offer-Makers ========
    // Expired offers have to be manually found and deleted. This requires indexing

    // Define `for_id` for an object offer, and define `for_type` for a Type-offer
    public fun make_offer<T>(
        account: &mut Coin23<T>,
        send_to: address,
        for_id: Option<ID>,
        for_type: Option<StructTag>,
        amount_each: u64,
        quantity: u8,
        duration_ms: u64,
        clock: &Clock,
        registry: &CurrencyRegistry,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): ItemOffer<T> {
        if (option::is_some(&for_id)) {
            // object-offer
            let claim = claim::create(account, amount_each, duration_ms, clock, registry, auth, ctx);
            let (_, _, expiry_ms) = claim::info(&claim);

            ItemOffer {
                id: object::new(ctx),
                send_to,
                claim: option::some(claim),
                for_id: for_id,
                for_type: option::none(),
                amount_each,
                quantity: 1,
                expiry_ms
            }
        } else {
            // type-offer
            assert!(option::is_some(&for_type), EINVALID_OFFER);

            let claim = claim::create(
                account, amount_each * (quantity as u64), duration_ms, clock, registry, auth, ctx);
            let (_, _, expiry_ms) = claim::info(&claim);

            ItemOffer {
                id: object::new(ctx),
                send_to,
                claim: option::some(claim),
                for_id: option::none(),
                for_type: for_type,
                amount_each,
                quantity,
                expiry_ms
            }
        }
    }

    public fun return_and_share<T>(offer: ItemOffer<T>, owner: address) {
        let auth = tx_authority::begin_with_package_witness_(Witness { });
        let typed_id = typed_id::new(&offer);

        // ItemOffers are non-transferable, hence transfer-auth is set to @0x0
        ownership::as_shared_object_(&mut offer.id, typed_id, owner, @0x0, &auth);
        transfer::share_object(offer);
    }

    // This won't work yet; shared objects cannot be deleted
    public fun cancel() {}

    // Stand-in until shared objects can be deleted
    public fun cancel_() {

    }

    // ======== For Offer-Takers ========

    // This won't work yet, because shared objects cannot be deleted
    // For this to work, must have offer.quantity == 1. If quantity > 1, called `take_offer_` instead
    public fun take_offer<T>(
        offer: ItemOffer<T>,
        offer_account: &mut Coin23<T>,
        taker_account: &mut Coin23<T>,
        item: &mut UID,
        clock: &Clock,
        registry: &CurrencyRegistry,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        assert!(offer.quantity == 1, EOFFER_EXPIRED);
        assert!(is_valid(&offer, clock), EOFFER_EXPIRED);

        let ItemOffer { id, send_to, claim, for_id, for_type, amount_each, quantity: _, expiry_ms: _ } = offer;
        object::delete(id);

        // object-offer
        if (option::is_some(&for_id)) {
            assert!(option::borrow(&for_id) == object::uid_as_inner(item), EINCORRECT_OBJECT);
        } else { // type-offer
            let item_type = option::destroy_some(ownership::get_type(item));
            assert!(struct_tag::match(option::borrow(&for_type), &item_type), EINCORRECT_OBJECT);
        };

        let claim = option::destroy_some(claim);
        claim::redeem_claim(
            &mut claim, offer_account, taker_account, amount_each, clock, registry, ctx);
        claim::destroy(claim, offer_account);
        ownership::transfer(item, option::some(send_to), auth);
    }

    // Must have transfer-authority added to `auth`, meaning this must be called by the transfer-auth
    // so that ownership::transfer succeeds.
    public fun take_offer_<T>(
        offer: &mut ItemOffer<T>,
        offer_account: &mut Coin23<T>,
        taker_account: &mut Coin23<T>,
        item: &mut UID,
        clock: &Clock,
        registry: &CurrencyRegistry,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        assert!(is_valid(offer, clock), EOFFER_EXPIRED);

        // object-offer
        if (option::is_some(&offer.for_id)) {
            assert!(option::borrow(&offer.for_id) == object::uid_as_inner(item), EINCORRECT_OBJECT);
        } else { // type-offer
            let item_type = option::destroy_some(ownership::get_type(item));
            assert!(struct_tag::match(option::borrow(&offer.for_type), &item_type), EINCORRECT_OBJECT);
        };

        let claim = option::borrow_mut(&mut offer.claim);
        claim::redeem_claim(
            claim, offer_account, taker_account, offer.amount_each, clock, registry, ctx);
        ownership::transfer(item, option::some(offer.send_to), auth);

        offer.quantity = offer.quantity - 1;

        if (offer.quantity == 0) {
            let claim = option::extract(&mut offer.claim);
            claim::destroy(claim, offer_account);
            ownership::destroy(&mut offer.id, &tx_authority::empty());
        };
    }

    // ======== Getters ========

    public fun is_valid<T>(offer: &ItemOffer<T>, clock: &Clock): bool { 
        if (option::is_none(&offer.claim)) { return false };
        if (ownership::is_destroyed(&offer.id)) { return false };
        if (clock::timestamp_ms(clock) > offer.expiry_ms) { return false };

        true
    }

    // If it's not a type offer, then it's an object offer
    public fun is_type_offer<T>(offer: &ItemOffer<T>): bool {
        if (option::is_some(&offer.for_type)) true
        else false
    }

    public fun object_offer_info<T>(offer: &ItemOffer<T>): (address, ID, u64, u64) { 
        (offer.send_to, *option::borrow(&offer.for_id), offer.amount_each, offer.expiry_ms)
    }

    public fun type_offer_info<T>(offer: &ItemOffer<T>): (address, StructTag, u64, u8, u64) {
        (offer.send_to, *option::borrow(&offer.for_type), offer.amount_each, offer.quantity, offer.expiry_ms)
    }

    // ======== Convenience Entry functions ========

    public entry fun create_offer_() {

    }
}