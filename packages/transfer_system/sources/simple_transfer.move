// Simple transfer module that allows an owner to transfer ownership to anyone else arbitrarily

module transfer_system::simple_transfer {
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use ownership::ownership;
    use ownership::tx_authority;

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;

    // Witness type
    struct Witness has drop { } 

    // Convenience function
    public fun transfer_to_object<T: key>(uid: &mut UID, obj: &T, ctx: &TxContext) {
        let addr = object::id_address(obj);
        transfer(uid, vector[addr], ctx);
    }

    // Convenience function
    public fun transfer_to_type<T>(uid: &mut UID, ctx: &TxContext) {
        let addr = tx_authority::type_into_address<T>();
        transfer(uid, vector[addr], ctx);
    }

    // Transfer ownership to an arbitrary address
    public fun transfer(uid: &mut UID, new_owner: vector<address>, ctx: &TxContext) {
        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENO_OWNER_AUTHORITY);

        ownership::transfer(uid, new_owner, &auth);
    }
}