// Sui's Permission Delegation System
//
// Note that transfers should wipe all UID-stored delegations
// ACL (access control list) is a 16-bit integer, with each bit corresponding to a role

module ownership::delegation {
    use sui::object::{Self, TxContext};

    use sui_utils::access_control_list as acl;

    use ownership::ownership;

    // Error constants
    const ENO_PERMISSION: u64 = 0;

    // This is a key that stores the ACL granted by the owner to the `for` address
    struct Delegation has store, copy, drop { for: address } // -> RBAC vector

    // This is the key for obtaining the list of all delegate addresses. We store the list so that
    // so that we can enumerate through them 
    struct DelegationList has store, copy, drop {} // -> vector<address>

    // To use this, the client has to understand how the permissions are converted into a u16
    public fun set_acl(uid: &mut UID, for: address, acl: u16) {
        dynamic_field2::set<Delegation, u16>(Delegation { for }, rbac);
    }

    public fun remove_acl(uid: &mut UID, for: address) {
        dynamic_field2::drop<Delegation, u16>(Delegation { for });
    }

    public fun remove_all(uid: &mut UID) {
        // TO DO
        dynamic_field2::drop<Delegation, u16>(Delegation { for });
    }

    // These are a little easier for clients to use because we do the permission -> u16 conversion for the caller
    public fun grant_role(uid: &mut UID, for: address, role: u8) {
        let acl = dynamic_field2::borrow_mut_fill(uid, Delegation { for }, 0u16);
        acl::add_role(acl, role);
    }

    public fun revoke_role(uid: &mut UID, for: address, role: u8) {
        let key = Delegation { for };
        if (!dynamic_field::exists_(uid, key)) { return }

        let acl = dynamic_field2::borrow_mut<Delegation, u16>(uid, key);
        acl::remove_role(acl, role);
    }

    // ===== Accessor Functions =====

    public fun get_acl(uid: &UID, for: address): u16 {
        dynamic_field2::get_with_default(uid, Delegation { for }, 0u16)
    }

    // ===== Role-Specific Authority Checkers =====

    // Role enums. These are the indices of the bits that correspond to each role in the ACL (access control list)
    // 0 = no role, 1 = has role, for the specified index
    const NAMESPACE_ROLE: u8 = 0;
    const EDIT_DATA_ROLE: u8 = 1;
    const READ_INVENTORY_ROLE: u8 = 2;
    const EDIT_INVENTORY_ROLE: u8 = 3;
    const TRANSFER_ROLE: u8 = 4;
    // TO DO: consider more roles

    // ====== Permissions that can only be stored in a DelegationStore ======

    public fun has_namespace_role(namespace: Option<address>, auth: &TxAuthority): bool {
        if (option::is_none(&namespace)) { return true };
        namespace = option::destroy_some(namespace);

        if (tx_authority::is_partial_signer_with_role(namespace, auth, NAMESPACE_ROLE)) { return true };
        if (tx_authority::is_full_signer(namespace, auth)) { return true };

        false
    }

    // ====== Permisions that can only be stored in UIDs ======

    // Owenrs and modules have the data-edit role by default
    public fun has_data_edit_role(uid: &UID, auth: &TxAuthority): bool {
        let i = 0;
        while (i < vector::length(&auth.full_signers)) {
            let addr = *vector::borrow(&auth.full_signers, i);
            if (is_owner(uid, addr) || is_module(uid, addr)) { return true };
            if (has_role(uid, addr, DATA_EDIT_ROLE)) { return true }
            i = i + 1;
        };

        false
    }

    // ===== Generic Authority Checkers =====

    public fun is_owner(uid: &UID, addr: address): bool {
    }

    public fun is_module(uid: UID, addr: address): bool {
    }

    public fun has_role(uid: &UID, for: address, role: u8): bool {
        let key = Delegation { for };
        if (!dynamic_field::exists_(uid, key)) return false;
        let acl = dynamic_field::borrow<Delegation, u16>(uid, key);
        acl::has_role(acl, role)
    }
}