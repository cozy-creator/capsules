// Commands useable by the transfer-authority of an object

module ownership::transfer {
    use sui::object::UID;

    use ownership::client;
    use ownership::ownership;
    use ownership::tx_authority::TxAuthority;

    // Permission types
    struct TRANSFER {} // Used to perform a transfer (change the owner)
    struct MIGRATE {} // Used to change the transfer-authority

    // Requires transfer authority. Does NOT require ownership or module authority.
    // This means the specified transfer authority can change ownership unilaterally, without the current
    // owner being the sender of the transaction.
    // This is useful for marketplaces, reclaimers, and collateral-repossession.
    public fun transfer(uid: &mut UID, new_owner: vector<address>, auth: &TxAuthority) {
        assert!(client::has_transfer_permission<TRANSFER>(uid, auth), ENO_TRANSFER_AUTHORITY);

        ownership::set_owner_internal(uid, new_owner);
    }

    // Requires module, owner, and transfer authorities all to sign off on this migration
    // This is a difficult operation to do!
    // TO DO: create an example implementation of this. We might choose to ignore module authority, or perhaps
    // allow for unilateral changes by the module-authority.
    public fun migrate_transfer_auth(uid: &mut UID, new_transfer_auths: vector<address>, auth: &TxAuthority) {
        assert!(client::has_module_permission<MIGRATE>(uid, auth), ENO_OWNER_AUTHORITY);
        assert!(client::has_owner_permission<MIGRATE>(uid, auth), ENO_OWNER_AUTHORITY);
        assert!(client::has_transfer_permission<MIGRATE>(uid, auth), ENO_OWNER_AUTHORITY);

        ownership::set_transfer_authority_internal(uid, new_transfer_auths);
    }

    // This ejects all transfer authority, and it can never be set again, meaning the owner can never be
    // changed again.
    public fun make_owner_immutable(uid: &mut UID, auth: &TxAuthority) {
        migrate_transfer_auth(uid, vector::empty(), auth);
    }
}