module ownership::delegation_store {

    use ownership::delegation;

    // Error constants
    const ENO_PERMISSION: u64 = 0;

    // Shared, root-level object. Stores delegations issued on behalf of `from`
    struct DelegationStore has key { 
        id: UID,
        from: address // also the immutable owner
    }

    // Convenience function
    public entry fun create(ctx: &mut TxContext) {
        let auth = tx_authority::begin(ctx);
        let owner = tx_context::sender(ctx);
        create_(owner, &auth, ctx);
    }

    public fun create_(owner: address, auth: &TxAuthority, ctx: &mut TxContext) {
        assert!(tx_authority::is_signed_by(owner, auth), ENO_PERMISSION);

        let store = DelegationStore {
            id: object::new(ctx),
            owmer
        };

        transfer::share_object(store);
    }

    // Convenience function
    public entry fun set(store: &mut DelegationStore, to: address, rbac: u16, ctx: &mut TxContext) {
        let auth = tx_authority::begin(ctx);
        set_(store, to, rbac, &auth);
    }

    public fun set_(store: &mut DelegationStore, to: address, rbac: u16, auth: &TxAuthority) {
        assert!(tx_authority::is_signed_by(store.owner, auth), ENO_PERMISSION);

        delegation::set(&mut store.id, to, rbac);
    }

    // Convenience function
    public entry fun remove(store: &mut DelegationStore, to: address, ctx: &mut TxContext) {
        let auth = tx_authority::begin(ctx);
        remove_(store, to, &auth);
    }

    public fun remove_(store: &mut DelegationStore, to: address, auth: &TxAuthority) {
        assert!(tx_authority::is_signed_by(store.owner, auth), ENO_PERMISSION);

        delegation::remove(&mut store.id, to);
    }
}