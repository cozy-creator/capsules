// These are authority-checks for client endpoints. Modules should use these for access-control.
// Client-authority is stored within the object's UID as dynamic fields by the ownership::ownership
// module.

// This validity-checks should be used by modules to assert the correct permissions are present.

module ownership::client {

    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::ownership::{Self, UID_MUT};

    // Defaults to `true` if owner is not set.
    public fun has_owner_admin_permission(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let owner = ownership::get_owner(uid);
            if (option::is_none(&owner)) true
            else {
                let owner = option::destroy_some(owner);
                tx_authority::has_admin_permission(owner, auth)
            }
        }
    }

    // Defaults to `true` if the owner does not exist
    public fun has_owner_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let owner = ownership::get_owner(uid);
            if (option::is_none(&owner)) true
            else {
                let owner = option::destroy_some(owner);
                tx_authority::has_permission<Permission>(owner, auth)
            }
        }
    }

    public fun has_module_admin_permission(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let module_authority = option::destroy_some(ownership::get_module_authority(uid));
            tx_authority::has_admin_permission(module_authority, auth)
        }
    }

    // If this is initialized, module authority exists and is always the native module (the module
    // that issued the object). I.e., the hash-address corresponding to `0x599::my_module::Witness`.
    public fun has_module_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let module_authority = option::destroy_some(ownership::get_module_authority(uid));
            tx_authority::has_permission<Permission>(module_authority, auth)
        }
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun has_transfer_admin_permission(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let transfer = ownership::get_transfer_authority(uid);
            if (vector::is_empty(&transfer)) false
            else {
                tx_authority::has_k_or_more_admin_agents(&transfer, 1, auth)
            }
        }
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun has_transfer_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let transfer = ownership::get_transfer_authority(uid);
            if (vector::is_empty(&transfer)) false
            else {
                tx_authority::has_k_or_more_agents_with_permission<Permission>(&transfer, 1, auth)
            }
        }
    }

    // Checks all instances of why an agent needs mutable access to a UID
    public fun validate_uid_mut(uid: &UID, auth: &TxAuthority): bool {
        if (has_module_permission<UID_MUT>(uid, auth)) { return true }; // Witness type added
        if (has_transfer_permission<UID_MUT>(uid, auth)) { return true }; // Transfer type added
        if (has_owner_permission<UID_MUT>(uid, auth)) { return true }; // Owner type added

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