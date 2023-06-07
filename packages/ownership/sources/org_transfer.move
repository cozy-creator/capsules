// Same as simple-transfer, but with ADMIN intead of TRANSFER as the requested permission.
// This exists for Organization, so that an owner doesn't carelessly grant the 'TRANSFER' permission
// to an agent, and then the TRANSFER agent takes over the Organization object by transfer it to
// itself.

module ownership::org_transfer {
    use std::option;

    use sui::object::{Self, UID};

    use sui_utils::encode;

    use ownership::permission::ADMIN;
    use ownership::ownership::{Self};
    use ownership::tx_authority::{Self, TxAuthority};

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;

    // Package Witness
    struct Witness has drop { } 

    // Convenience function
    public fun transfer_to_object<T: key>(uid: &mut UID, obj: &T, auth: &TxAuthority) {
        let addr = object::id_address(obj);
        transfer(uid, addr, auth);
    }

    // Convenience function
    public fun transfer_to_type<T>(uid: &mut UID, auth: &TxAuthority) {
        let addr = encode::type_into_address<T>();
        transfer(uid, addr, auth);
    }

    // Transfer ownership to an arbitrary address
    public fun transfer(uid: &mut UID, new_owner: address, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(uid, auth), ENO_OWNER_AUTHORITY);
        
        let auth = tx_authority::add_type(&Witness {}, auth);
        ownership::transfer(uid, option::some(new_owner), &auth);
    }
}