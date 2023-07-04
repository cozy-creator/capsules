// This enables reversible transfers; it's helpful to protect consumers from phishing and fraud.
//
// A pending transfer can only be committed if (1) all guardians approve it, or (2) the time limit expires.
// A pending transfer can be cancelled by any guardian. When canceled, a pending transfer has no effect.
// Guardian-addresses are the guardians of the Person who owns the object being transferred.
// Objects are placed in a 'frozen' state while a PendingTransfer is active.
//
// It is up to transfer-systems / marketplaces to implement this if they choose, but it is not required.
// For some applications, the friction / delay added by pending_transfer is untenable, in which case it's
// better to use a direct, instant transfer.

module economy::pending_transfer {
    use std::option;

    use sui::object::{Self, ID, UID};
    use sui::tx_context::TxContext;

    use sui_utils::vec_map2;

    use ownership::ownership::{Self, TRANSFER};
    use ownership::person::{Self, Person};

    // Error codes
    const ENO_TRANSFER_AUTH: u64 = 0;
    const EINCORRECT_PERSON_SUPPLIED: u64 = 1;
    const EPENDING_TRANSFER_CANNOT_BE_MODIFIED: u64 = 2;
    const ENOT_GUARDIAN_OF_TRANSFER: u64 = 3;

    // Constants
    const ONE_DAY_MS: u64 = 1000 * 60 * 60 * 24;

    // Root-level shared object
    struct PendingTransfer has key {
        id: UID,
        locked: bool, // objects cannot be added once set to `true`
        contents: VecMap<ID, address>, // object-id, and address it is being sent to
        must_approve: vector<address>,
        unlock_timestamp: u64
    }

    // This is a hot-potato struct that prevents items in the pending transfer from being ignored
    // All items must be transferred in the same transaction, or the transaction aborts
    struct RemainingTransfers {
        contents: VecMap<ID, address>
    }

    // ======== Create Transfer ========

    // Owner of this `uid` must be defined, and must match the principal of `Person` or this will abort.
    public fun create(
        uid: &UID,
        person: &Person,
        to: address,
        wait_period_ms: u64,
        clock: &Clock,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): PendingTransfer {
        assert!(ownership::can_act_as_transfer_auth<TRANSFER>(uid, auth), ENO_TRANSFER_AUTH);

        let owner = option::destroy_some(ownership::get_owner(uid));
        assert!(person::address(person) == owner, EINCORRECT_PERSON_SUPPLIED);

        PendingTransfer {
            id: object::new(ctx),
            locked: false,
            contents: vec_map2::new(to, object::id(uid)),
            must_approve: vector[person::guardian(person)],
            unlock_timestamp: clock::timestamp_ms(clock) + wait_period_ms
        }
    }

    // Owner of this `uid` must be defined, and must match the principal of `Person` or this will abort.
    //
    // We use 'lock' to ensure that objects can only be added to a PendingTransfer in the same transaction
    // that created it.
    //
    // If users were allowed to add objects to a PendingTransfer after the tx that created it, this would lead
    // to annoying exploits, like finding a PendingTransfer whose time has alraedy expired and then
    // adding a bunch of objects to it and then committing its transfer immediately.
    public fun add_object(
        pending: &mut PendingTransfer,
        uid: &UID,
        person: &Person,
        to: address,
        auth: &TxAuthority
    ) {
        assert!(!pending.locked, EPENDING_TRANSFER_CANNOT_BE_MODIFIED);
        assert!(ownership::can_act_as_transfer_auth<TRANSFER>(uid, auth), ENO_TRANSFER_AUTH);

        let owner = option::destroy_some(ownership::get_owner(uid));
        assert!(person::address(person) == owner, EINCORRECT_PERSON_SUPPLIED);

        vec_map::add(&mut pending.contents, to, object::id(uid));
        vector2::push_back_unique(&mut pending.must_approve, person::guardian(person));
    }

    public fun return_and_share(pending: PendingTransfer) {
        pending.locked = true;
        transfer::share_object(pending);
    }

    // ======== Approve or Deny Transfer ========

    public fun approve(pending: &mut PendingTransfer, guardian: address, auth: &TxAuthority) {
        assert!(tx_authority::can_act_address<TRANSFER>(guardian, auth), ENO_GUARDIAN_AUTH);

        vector2::remove_maybe(&mut pending.must_approve, guardian);
    }

    // This cannot be used until shard objects can be deleted
    public fun cancel(pending: PendingTransfer, guardian: address, auth: &TxAuthority) {
        assert!(tx_authority::can_act_address<TRANSFER>(guardian, auth), ENO_GUARDIAN_AUTH);

        let PendingTransfer { id, locked: _, contents: _, must_approve, unlock_timestamp: _ } = pending;
        object::delete(id);

        assert!(vector::contains(&must_approve, guardian), ENOT_GUARDIAN_OF_TRANSFER);
    }

    public fun cancel_(pending: &mut PendingTransfer, guardian: address, auth: &TxAuthority) {
        assert!(tx_authority::can_act_address<TRANSFER>(guardian, auth), ENO_GUARDIAN_AUTH);

        pending.contents = vec_map::empty();
        pending.must_approve = vector[];
    }

    // ======== Crank Transfer ========

    // This function will not be useable until Sui can delete shared objects.
    // For now use `begin_transfer_` instead.
    public fun begin_transfer(pending: PendingTransfer, uid: &mut UID, clock: &Clock): RemainingTransfers {
        let PendingTransfer = { id, locked: _, contents, must_approve, unlock_timestamp };
        object::delete(id);
        if (clock::timestamp_ms(clock) < unlock_timestamp) {
            assert!(vector::is_empty(&must_approve), ENOT_ALL_PARTIES_HAVE_AGREED);
        };

        let remainder = RemainingTransfers { contents };
        continue_transfer(&mut remainder, uid);
        remainder
    }

    // We cannot delete `PendingTransfer` yet, because it's a shared object
    public fun begin_transfer(pending: &mut PendingTransfer, uid: &mut UID, clock: &Clock): RemainingTransfers {
        // If unlock-time has not yet expired, all parties must have signed off
        if (clock::timestamp_ms(clock) < pending.unlock_timestamp) {
            assert!(vector::is_empty(pending.must_approve), ENOT_ALL_PARTIES_HAVE_AGREED);
        };

        let remainder = RemainingTransfers { contents: vector[] };
        while (vector::length(&pending.contents) > 0) {
            vector_push(&mut remainder, vec_map::pop(&mut pending.contents));
        };

        continue_transfer(&mut remainder, uid);
        remainder
    }

    public fun continue_transfer(remainder: &mut RemainingTransfers, uid: &mut UID) {
        let id = object::uid_to_id(uid);
        let (_, recipient) = vec_map::remove(&mut remainder.contents, &id);
        ownership::transfer_internal(uid, recipient);
    }

    public fun conclude_transfer(remainder: RemainingTransfers) {
        let RemainingTransfers { contents } = remainder;

        assert!(vec_map::is_empty(&contents), ENOT_ALL_ASSETS_HAVE_BEEN_TRANSFERRED);
    }

    // ======== Getters ========

    public fun stuff() {
        // TO DO
    }

    public fun remaining_transfers(remainder: &RemainingTransfers): VecMap<ID, address> {
        remainder.contents
    }
}