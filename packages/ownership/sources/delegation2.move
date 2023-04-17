module ownership::delegations2 {



    // ============ Delegation Store ============ 

    // Shared, root-level object. Owned by an address; not necessarily the principal.
    // It's important this is shared and root-level, so that the owner can remove permissions whenever it likes.
    // If this were a single-writer or wrapped object, that would not be possible. Hence do not add `store`
    struct DelegationStore has key {
        id: UID,
        principal: address,
        agent_permissions: VecMap<address, vector<String>> // (agent-address, [permission-name])
    }

    public fun create<Witness: drop>(
        witness: Witness,
        owner: address,
        ctx: &mut TxContext
    ): Delegations {
        let delegations = Delegations {
            id: object::new(ctx),
            principal: tx_authority::type_into_address<Witness>(),
            agent_permissions: vec_map2::empty()
        };

        // TO DO: add ownership 

        delegations
    }

    public fun return_and_share(store: Delegation) {
        transfer::share_object(store);
    }

    public fun add_to_store<T>(
        stored: &mut Delegations,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(ownership::is_authorized_by_owner(&stored.id, auth), ENO_OWNER_AUTHORITY);

        let permissions = vec_map2::borrow_mut_fill(&mut stored.agent_permissions, agent, vector[]);
        vector2::merge(permissions, vector[encode::type_name<T>()]);
    }

    public fun remove_from_store<T>() { }

    // ============ Namespace Management ============

    // Used to store delegations inside of arbitrary object UIDs
    struct Key has store, copy, drop { } 

    // Convenience function
    public fun open_namespace<Namespace>(uid: &mut UID, auth: &TxAuthority) {
        provision_namespace_(uid, tx_authority::type_into_address<Namespace>(), auth);
    }

    public fun open_namespace_(uid: &mut UID, namespace: address, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field::add(uid, Key { namespace }, true);
    }

    public fun close_namespace_(uid: &mut UID, namespace: address, auth: &TxAuthority) {
        // assert!(ownership::is_signed_by(namespace, auth), ENO_AGENT_PERMISSION);
        assert!(has_permission_from<Key>(namespace, auth), ENO_AGENT_PERMISSION);
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        // remove inventory
        // delete data

        dynamic_field::remove(uid, Key { namespace });
    }

    public fun allow_transfer(uid: &mut UID, transfer_addr:: address, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field::add(uid, Key { namespace: transfer_addr }, true);
    }


    // ======= Authority Checkers ========

        // Use this in uid_mut
    public fun has_permission_from_owner(uid: &UID, auth: &TxAuthority): bool {
        if (ownership::is_signed_by_owner(uid, auth)) { return true };
        let i = 0;

        // Check against all signing agents if this exists
        // Check against all delegate agents of type T if this exists
        dynamic_field::exists_(uid, Key { namespace }) { return true };

    }

    public fun has_permission_from<T>(principal: address, auth: &TxAuthority): bool {
        if (tx_authority::is_signed_by_(principal, auth)) { return true };

        let permissions = vec_map2::get_with_default(&auth.delegations, principal, vector[]);
        vector::contains(permissions, encode::type_name<T>)
    }


}