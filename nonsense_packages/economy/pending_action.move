module economy::pending_action {
    use ownership::action_set::{Self, SingleUseActions};

    // Root-level shared object
    struct PendingAction<T> has key {
        id: UID,
        controller: address,
        must_approve: vector<address>,
        auto_approve_at_timestamp: u64,
        finalized: bool, // PendingAction cannot be modified after this is set to `true`
        contents: VecMap<ID, Details<T>>
    }

    // This is a hot-potato struct derived from a destroyed PendingAction. It guarantees that all
    // actions inside of `contents` must be dealt with
    struct RemainingActions<T> {
        contents: VecMap<ID, Details<T>>
    }

    struct Details<T> has store, drop {
        inner: T,
        single_use: SingleUseActions
    }

    // ======== Initialize Pending Actions ========

    public(friend) fun create<Witness: drop, T>(
        _: Witness,
        wait_period_ms: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): PendingAction<T> {
        PendingAction {
            id: object::new(ctx),
            controller,
            must_approve: vector[],
            auto_approve_at_timestamp: clock::timestamp_ms(clock) + wait_period_ms
            finalized: false,
            contents: vec_map::empty()
        }
    }

    public fun add<T: store, Action>(
        pending: &mut PendingAction<T>,
        uid: &UID,
        person: &Person,
        inner: T,
        principal: address, // The person who is performing the action
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_address<ADMIN>(pending.controller, auth), ENO_ADMIN_AUTH);

        let single_use = action_set::create_single_use<ADMIN>(principal, auth);

        // We must extract the guardian address of the owner of this object
        let owner = option::destroy_some(ownership::get_owner(uid));
        assert!(person::address(person) == owner, EINCORRECT_PERSON_SUPPLIED);
        let guardian = person::guardian(person);
        vector2::push_back_unique(&mut pending.must_approve, person::guardian(person));

        ownership::freeze(uid, guardian, single_auth)

        vec_map::add(&mut pending.contents, object::uid_to_id(uid), Details { inner, single_use });
    }

    public fun return_and_share(pending: PendingAction) {
        pending.finalized = true;
        transfer::share_object(pending);
    }

    // ======== Execute Pending Actions ========

    // This function will not be useable until Sui can delete shared objects.
    // For now use `begin_` instead.
    public fun begin<T: store>(
        pending: PendingAction<T>,
        clock: &Clock,
        auth: &TxAuthority
    ): RemainingActions<T> {
        let PendingAction { 
            id, controller, must_approve, auto_approve_at_timestamp, finalized: _, contents } = pending;
        
        assert!(tx_authority::can_act_as_address<ADMIN>(controller, auth), ENO_ADMIN_AUTH);

        if (clock::timestamp_ms(clock) < auto_approve_at_timestamp) {
            assert!(vector::is_empty(&must_approve), ENOT_ALL_PARTIES_HAVE_AGREED);
        };

        object::delete(id);

        RemainingActions { contents }
    }

    // The PendingAction object will still exist after this,b ut tis contents will be empty and
    // hence it cannot be used again for anything.
    public fun begin_<T: store>(
        pending: &mut PendingAction<T>,
        clock: &Clock,
        auth: &TxAuthority
    ): RemainingActions<T> {
        assert!(tx_authority::can_act_as_address<ADMIN>(pending.controller, auth), ENO_ADMIN_AUTH);

        if (clock::timestamp_ms(clock) < pending.auto_approve_at_timestamp) {
            assert!(vector::is_empty(&pending.must_approve), ENOT_ALL_PARTIES_HAVE_AGREED);
        };

        // We cannot simply duplicate the contents because they don't have the `copy` ability
        let remainder = RemainingActions { contents: vec_map::empty() };
        while (vector::length(&pending.contents) > 0) {
            let (id, details) = vec_map::pop(&mut pending.contents);
            vec_map::insert(&mut remainder.contents, id, details);
        };
        remainder
    }

    public fun next_object<T: store>(remainder: &mut RemainingActions<T>, id: ID): (T, TxAuthority) {
        let details = vec_map::remove(&mut remainder.contents, &id);
        let Details { inner, single_use } = details;
        (inner, tx_authority::begin_with_single_use(single_use))
    }

    // This will abort if the remainder's `contents` are not empty
    // This ensure that all actions are performed and none are ignored
    public fun end<T: store>(remainder: RemainingActions<T>) {
        let RemainingActions { contents } = remainder;
        vec_map::destroy_empty(contents);
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

    // ======== Getters ========

    public fun stuff() {
        // TO DO
    }

    public fun remaining_transfers(remainder: &RemainingActions): VecMap<ID, address> {
        remainder.contents
    }

}