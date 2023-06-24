module economy::pending_transfer3 {

    // Constants
    const ONE_DAY_MS: u64 = 1000 * 60 * 60 * 24;

    // Module authority
    struct Witness has drop {}

    public fun create_pending_swap(
        uid1: &mut UID,
        uid2: &mut UID,
        sender1: &Person,
        sender2: &Person,
        clock: &Clock,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        // TO DO: assert that uid1 was for sale
        assert!(ownership::can_act_as_owner<TRANSFER>(uid2, auth), ENO_AUTHORITY);

        // This will abort if we are not the transfer-authority for these objects
        let auth = tx_authority::begin_with_type(&Witness {});
        ownership::freeze_transfer(uid1, &auth);
        ownership::freeze_transfer(uid2, &auth);

        let pending = pending_action::create(Witness {}, ONE_DAY_MS, clock, ctx);
        pending_action::add<address, TRANSFER>(Witness {}, &mut pending, uid1, person1, person::address(person2));
        pending_action::add<address, TRANSFER>(Witness {}, &mut pending, uid2, person2, person::address(person1));
        pending_action::return_and_share(pending);
    }

    // This will abort if the pending action has not been fully approved
    public fun perform_pending_swap(
        pending: &mut PendingAction<Witness, address>,
        uid1: &mut UID,
        uid2: &mut UID,
        clock: &Clock,
    ) {
        let remaining = pending_action::begin_(Witness {}, pending, clock);

        let auth = tx_authority::begin_with_type(&Witness {});
        ownership::unfreeze_transfer(uid1, &auth);
        ownership::unfreeze_transfer(uid2, &auth);

        let (recipient, auth) = pending_action::next_object(&mut remaining, object::uid_to_inner(uid1));
        ownership::transfer(uid1, recipient, &auth);

        let (recipient, auth) = pending_action::next_object(&mut remaining, object::uid_to_inner(uid2));
        ownership::transfer(uid2, recipient, &auth);

        pending_action::end(remaining);
    }
}