// These are authority-checks for client endpoints. Modules should use these for access-control.
// Client-authority is stored within the object's UID as dynamic fields by the ownership::ownership
// module.
// Most of these are pass-through functions to ownership::ownership

// This validity-checks should be used by modules to assert the correct permissions are present.

module ownership::namespace_provisioning {
    use std::vector;

    use sui::dynamic_field;
    use sui::object::UID;

    use sui_utils::dynamic_field2;

    use ownership::action::ANY;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::ownership;

    // Error enums
    const ENO_PROVISION_AUTHORITY: u64 = 0;

    // Also checks to see if a namespace has previously been provisioned in this UID
    public fun can_borrow_uid_mut(uid: &UID, auth: &TxAuthority): bool {
        if (ownership::can_act_as_owner<ANY>(uid, auth)) { return true }; // Owner type added
        if (ownership::can_act_as_package<ANY>(uid, auth)) { return true }; // Witness type added
        if (ownership::can_act_as_transfer_auth<ANY>(uid, auth)) { return true }; // Transfer type added

        // Check for namespace provisioning--these are manually added by an owner or namespace to an object's UID
        let agents = tx_authority::agents(auth);
        while (!vector::is_empty(&agents)) {
            let agent = vector::pop_back(&mut agents);
            if (is_provisioned(uid, agent)) { return true };
        };

        false
    }

    // ======== Namespace Provisioning ========
    // If we want a namespace to have access to a non-native object, the owner must explicitly
    // call into ownership::provision() and provision the namespace. From there the namespace
    // can access the object's UID and write data to its own namespace.
    // Namespaces can only be explicitly deleted by the namespace itself, even if the object-owner
    // changes.

    // Used to check which namespaces have access to this object
    struct Key has store, copy, drop { namespace: address }

    // permission type
    struct PROVISION {} // allows provisioning and de-provisioning of namespaces

    public fun provision(uid: &mut UID, namespace: address, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_address<PROVISION>(namespace, auth), ENO_PROVISION_AUTHORITY);

        dynamic_field2::set(uid, Key { namespace }, true);
    }

    public fun deprovision(uid: &mut UID, namespace: address, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_address<PROVISION>(namespace, auth), ENO_PROVISION_AUTHORITY);

        dynamic_field2::drop<Key, bool>(uid, Key { namespace })
    }

    public fun is_provisioned(uid: &UID, namespace: address): bool {
        dynamic_field::exists_(uid, Key { namespace })
    }

    // TO DO: we might want to auto-provision a namespace upon access to inventory or data::attach,
    // so that access cannot be lost in the future.
    // We might remove the type-checks in the future for PROVISION and make UID have referential-authority
}

    // public fun has_stored_permission<Action>(uid: &UID, auth: &TxAuthority): bool {
    //     let permissions = dynamic_field::borrow<Key, VecMap<address, vector<Actions>>(uid, Key { });
    //     let i = 0;
    //     while (i < vector::length(&auth.permissions)) {
    //         let permission = vector::borrow(&auth.permissions, i);
    //         let principal = tx_authority::type_into_address<Action>();
    //         if (vector::contains(&permissions, &principal)) true
    //         else {
    //             i = i + 1;
    //         }
    //     };
        
    //     let key = Key { permission, principal };
    //     let permission = tx_authority::type_into_address<Action>();
    //     let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
    //     vector::contains(&ownership.transfer_auth, &permission)
    // }