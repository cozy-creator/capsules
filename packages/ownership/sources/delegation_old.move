module ownership::delegation {

    // Shared, root-level object. Owned by an address; not necessarily the principal.
    // It's important this is shared and root-level, so that the owner can remove permissions whenever it likes.
    // If this were a single-writer or wrapped object, that would not be possible. Hence do not add `store`
    struct Delegations has key {
        id: UID,
        principal: address,
        agent_permissions: VecMap<address, vector<String>> // (agent-address, [permission-name])
    }

    // Do not add copy to this; we do not want someone duplicating permissions and hiding them somewhere else. This would
    // make it impossible for the principal to revoke this delegation at a later time.
    // We could also static-type this rather than placing type_name as a String
    struct Delegation has store, drop {
        principal: address,
        type_name: String
    }

    // Used to store delegations inside of arbitrary object UIDs
    struct Key has store, copy, drop { }

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

    public fun add_to_store<T>(
        stored: &mut Delegations,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(ownership::is_authorized_by_owner(&stored.id, auth), ENO_OWNER_AUTHORITY);

        let permissions = vec_map2::borrow_mut_fill(&mut stored.agent_permissions, agent, vector[]);
        vector2::merge(permissions, vector[encode::type_name<T>()]);
    }

    public fun add_to_uid<T>(uid: &mut UID, agent: address, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let agent_permissions = dynamic_field2::borrow_mut_fill<Key, VecMap<address, vector<String>>(uid, Key { }, vec_map::empty());
        let permissions = vec_map2::borrow_mut_fill(agent_permissions, agent, vector[]);
        vector2::merge(permissions, vector[encode::type_name<T>()]);
    }

    public fun authorize_namespace<Namespace>(uid: &mut UID, auth: &TxAuthority) {

    }

    public fun authorize_namespace_(uid: &mut UID, namespace: address, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field::add(uid, Key { namespace }, true);
    }

    public fun unauthorize_namespace_(uid: &mut UID, namespace: address, auth: &TxAuthority) {
        // assert!(ownership::is_signed_by(namespace, auth), ENO_AGENT_PERMISSION);
        assert!(has_permission_from<Key>(namespace, auth), ENO_AGENT_PERMISSION);
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field::remove(uid, Key { namespace });
    }

    public fun remove_delegation() {

    }

    public fun return_and_share(store: Delegation) {
        transfer::share_object(store);
    }

    // ======= Modify TxAuthority =======

    // Convenience function
    public fun begin_and claim_permissions(stored: &Delegations<Witness>, ctx: &TxContext): TxAuthority {
        let auth = begin(ctx);
        claim_permissions(stored, &auth)
    }

    public fun claim_permissions(
        stored: &Delegations,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { 
            addresses: auth.addresses,
            delegations: auth.delegations
        };

        // Iterate through every agent currently in our transaction authority
        let i = 0;
        while (i < vector::length(&new_auth.addresses)) {
            // Find the permissions stored for this agent
            let agent = *vector::borrow(&new_auth.addresses, i);
            let permissions = vec_map2::get_default(&stored.agent_permissions, agent, vector[]);

            // Merge theese permissions into the existing transaction authority
            let delegations = vec_map2::get_or_fill(&mut new_auth.delegations, stored.principal, vector[]);
            vector2::merge(&mut delegations, permissions);

            i = i + 1;
        };

        new_auth
    }

    // ======= Authority Checkers =======

    public fun has_permission_from_owner<T>(uid: &UID, auth: &TxAuthority): bool {
        let owners = ownership::get_owner(uid);
        let i = 0;
        while (i < vector::length(&owners)) {
            let principal = vector::borrow(&owners, i);
            if (has_permission_from<T>(principal, auth)) { return true };
            i = i + 1;
        };

        // Look for delegations stored in UID
        if (!dynamic_field::exists_(uid, Key{ })) { return false };
        let agent_permissions = dynamic_field::borrow<Key, VecMap<address, vector<String>>(uid, Key { });
        let type_name = encode::type_name<T>();

        let i = 0;
        while (i < vector::length(&owners)) {
            let principal = vector::borrow(&owners, i);
            let permissions = vec_map2::get_with_default(agent_permissions, principal, vector[]);
            if (vector::contains(permissions, type_name)) { return true };
            i = i + 1;
        };

        false
    }

           dynamic_field::add(uid, Key { namespace }, true);

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



    assert!(tx_authority::is_signed_by_(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);

    // attach::data declares this type
    DataEdit has store, drop { namespace: address }

    assert!(delegation_has_permission<DataEdit>(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);

    assert!(delegation::has_permission<ForeignWitness>(&carrier.id, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE); // EXPERIMENTAL
    
    struct Permission<T> has store, drop { }

    // Step 1: Call into tx_authority::begin() and receive a TxAuthority with you as the owner
    // Step 2: You need a hardcoded function like:
    // public fun add_permission<T>(object: &mut Object, auth: &TxAuthority) {
    //    let uid = object::uid_mut(object);
    //    delegation::store_permission<T>(uid, auth);
    // }
    // Now when the foreign function wants to call into to write to your object, they'll do the following:
    // Step 1: call into delegation::claim_permission<Foreign>(store: PermissionStore<Foreign>, ctx), giving them a new TxAuthority
    // This will add the `DataEdit` delegation to TxAuthority
    // Step 2: call into a hard-coded function like:
    // public fun write_to_object(object: &mut Object, auth: &TxAuthority) {
    //    let uid = object::uid_mut(object);
    //    data::set_<Foreign>(uid, keys, values, auth)
    // }

            uid: &mut UID,
        keys: vector<String>,
        values: vector<T>,
        auth: &TxAuthority
    public fun store_permission<T>(uid: &mut UID, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field::add(&uid, Permission<T> { }, true);
    }

    public fun has_permission(permission, auth: &TxAuthority): bool {

    }

    I am 'overwatch' and I have permission to write to 'Mario Party' namespace, 

            assert!(delegation::has_permission<Key>(uid, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE); // EXPERIMENTAL
    
    assert!(delegation::has_permission<Key>(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE); // EXPERIMENTAL

    let vec = vec_map::get(tx_authority.delegations, namespace);
    vector::contains(vec, type_name<Key>)

    `john` has permission to `write to namespace in this uid` and this is the proof
    I (auth) have permission to write to uid namespace
}