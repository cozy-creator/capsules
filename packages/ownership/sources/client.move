// These are authority-checks for client endpoints. Modules should use these for access-control.
// Client-authority is stored within the object's UID as dynamic fields by the ownership::ownership
// module.

module ownership::client {

    // Defaults to `true` if the owner does not exist
    public fun has_owner_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (option::is_none(&ownership.owner)) true
            else {
                let owner = *option::borrow(&ownership.owner);
                tx_authority::has_permission<Permission>(owner, auth)
            }
        }
    }

    // Defaults to `true` if owner is not set.
    public fun has_owner_admin_permission(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (option::is_none(&ownership.owner)) true
            else {
                let owner = *option::borrow(&ownership.owner);
                tx_authority::has_admin_permission(owner, auth)
            }
        }
    }

    // If this is initialized, module authority exists and is always the native module (the module
    // that issued the object). I.e., the hash-address corresponding to `0x599::my_module::Witness`.
    public fun is_authorized_by_module(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let module_authority = option::destroy_some(get_module_authority(uid));
            tx_authority::is_signed_by(module_authority, auth)
        }
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun is_authorized_by_transfer(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (vector::is_empty(&ownership.transfer_auth)) false
            else {
                tx_authority::has_k_of_n_signatures(&ownership.transfer_auth, 1, auth)
            }
        }
    }

    public fun validate_uid_mut(uid: &UID, auth: &TxAuthority): bool {
        if (ownership::has_module_permission<UID_MUT>(uid, auth)) { return true }; // Witness type added
        if (ownership::has_owner_permission<UID_MUT>(uid, auth)) { return true }; // Owner type added
        if (ownership::has_transfer_permission<UID_MUT>(uid, auth)) { return true }; // Transfer type added

        let agents = tx_authority::agents(auth);
        while (!vector::is_empty(&agents)) {
            let agent = vector::pop_back(&mut agents);
            if (is_provisioned(uid, agent)) { return true }; // Namespace was previously granted access
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