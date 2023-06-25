// Simple transfer module that allows an owner to transfer ownership to anyone else arbitrarily
// This is the simplest possible transfer-module (outside of non-transferable ownership)

module transfer_system::simple_transfer {
    use std::option;

    use sui::object::{Self, UID};

    use sui_utils::encode;

    use ownership::ownership::{Self, TRANSFER};
    use ownership::tx_authority::{Self, TxAuthority};

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;

    // Point to this struct as your transfer authority
    struct SimpleTransfer has drop { } 

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
        assert!(ownership::can_act_as_owner<TRANSFER>(uid, auth), ENO_OWNER_AUTHORITY);
        
        let auth = tx_authority::add_type(&SimpleTransfer {}, auth);
        ownership::transfer(uid, option::some(new_owner), &auth);
    }
}