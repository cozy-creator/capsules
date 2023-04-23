// Transfer authority commands

module ownership::transfer {
    // Requires transfer authority. Does NOT require ownership or module authority.
    // This means the specified transfer authority can change ownership unilaterally, without the current
    // owner being the sender of the transaction.
    // This is useful for marketplaces, reclaimers, and collateral-repossession.
    public fun transfer(uid: &mut UID, new_owner: vector<address>, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_TRANSFER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.owner = new_owner;
    }

    // Requires module, owner, and transfer authorities all to sign off on this migration
    public fun migrate_transfer_auth(uid: &mut UID, new_transfer_auths: vector<address>, auth: &TxAuthority) {
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);
        assert!(is_authorized_by_transfer(uid, auth), ENO_TRANSFER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.transfer_auth = new_transfer_auths;
    }

    // This ejects all transfer authority, and it can never be set again, meaning the owner can never be
    // changed again.
    public fun make_owner_immutable(uid: &mut UID, auth: &TxAuthority) {
        migrate_transfer_auth(uid, vector::empty(), auth);
    }
}