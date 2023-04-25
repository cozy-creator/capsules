// These are authority-checks for client endpoints. Modules should use these for access-control.
// Client-authority is stored within the object's UID as dynamic fields by the ownership::ownership
// module.
// Most of these are pass-through functions to ownership::ownership

// This validity-checks should be used by modules to assert the correct permissions are present.

module authorization::client {

    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::ownership;

    // Permission type; allows for access to a UID mutably
    struct UID_MUT {}

    // Defaults to `true` if owner is not set.
    public fun has_owner_admin_permission(uid: &UID, auth: &TxAuthority): bool {
        ownership::has_owner_admin_permission(uid, auth)
    }

    // Defaults to `true` if the owner does not exist
    public fun has_owner_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        ownership::has_owner_permission<Permission>(uid, auth)
    }

    public fun has_module_admin_permission(uid: &UID, auth: &TxAuthority): bool {
        ownership::has_module_admin_permission(uid, auth)
    }

    // If this is initialized, module authority exists and is always the native module (the module
    // that issued the object). I.e., the hash-address corresponding to `0x599::my_module::Witness`.
    public fun has_module_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        ownership::has_module_permission<Permission>(uid, auth)
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun has_transfer_admin_permission(uid: &UID, auth: &TxAuthority): bool {
        ownership::has_transfer_admin_permission(uid, auth)
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun has_transfer_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        ownership::has_transfer_permission<Permission>(uid, auth)
    }

    // Also checks to see if a namespace has previously been provisioned in this UID
    public fun validate_uid_mut(uid: &UID, auth: &TxAuthority): bool {
        if (ownership::validate_uid_mut(uid, auth)) { return true };

        // Check provisions--these are manually added by an owner or namespace to an object's UID
        let agents = tx_authority::agents(auth);
        while (!vector::is_empty(&agents)) {
            let agent = vector::pop_back(&mut agents);
            if (is_provisioned(uid, agent)) { return true };
        };

        false
    }
}

    // public fun has_stored_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
    //     let permissions = dynamic_field::borrow<Key, VecMap<address, vector<Permissions>>(uid, Key { });
    //     let i = 0;
    //     while (i < vector::length(&auth.permissions)) {
    //         let permission = vector::borrow(&auth.permissions, i);
    //         let principal = tx_authority::type_into_address<Permission>();
    //         if (vector::contains(&permissions, &principal)) true
    //         else {
    //             i = i + 1;
    //         }
    //     };
        
    //     let key = Key { permission, principal };
    //     let permission = tx_authority::type_into_address<Permission>();
    //     let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
    //     vector::contains(&ownership.transfer_auth, &permission)
    // }