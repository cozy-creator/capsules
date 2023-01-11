module ownership::permissions {
    // error enums
    const ENO_PERMISSION: u64 = 0;

    struct Key has store, copy, drop { slot: u8 }

    // Slots for key
    const CREATOR: u8 = 0; // ID, must be present for other permissions to be set
    const EDIT_METADATA: u8 = 0; // vector<address> can edit object metadata arbitrarily
    // const OPEN: u8 = 0; // can open capsules
    // const EXTEND: u8 = 1; // can extend capsules
    // const DATA: u8 = 3; // can edit data
    // const INVENTORY: u8 = 4; // can edit inventory

    public fun set_metadata_editor(uid: &mut UID, addrs: vector<address>, auth: &TxAuthority) {
        assert!(is_authorized_by_metadata_editor(uid, auth), ENO_PERMISSION);

        dynamic_field::add(uid, Key { slot: EDIT_METADATA }, addrs);
    }

    // Convenience function
    // Sets the sole authority to @0x0, meaning the metadata can never be edited again
    public fun lock_metadata(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_authorized_by_metadata_editor(uid, auth), ENO_PERMISSION);

        dynamic_field::add(uid, Key { slot: EDIT_METADATA }, @0x0);
    }

    // If metadata-edit permission is not defined, then permission defaults to owner
    public fun is_authorized_by_metadata_editor(uid: &UID, auth: &TxAuthority): bool {
        if (dynamic_field::exists_(uid, Key { slot: EDIT_METADATA })) {
            let addrs = dynamic_field::borrow(uid, Key { slot: EDIT_METADATA });
            let total = tx_authority::num_valid_addresses(addrs, auth);
            if (total >= 1) true
            else false
        } else { 
            is_authorized_by_owner(uid, auth)
        }
    }
}