// Simple transfer module that allows an owner to transfer ownership to anyone else arbitrarily

module transfer_system::self {
    use std::string::String;
    use sui::object::UID;
    use sui::tx_context::{Self, TxContext};
    use ownership::ownership;

    // Error constants
    const ENO_OWNERSHIP_AUTHORITY: u64 = 0;

    // Witness type
    struct Self has drop {} 

    // Transfer using address as authority
    public fun transfer(id: &mut UID, new_owner: String, ctx: &mut TxContext) {
        assert!(ownership::is_valid(id, tx_context::sender(ctx)), ENO_OWNERSHIP_AUTHORITY);

        ownership::transfer(Self {}, id, new_owner);
    }

    // Transfer using object as authority
    // This function can be collapsed into the above function once Sui allows optional references as arguments
    public fun transfer_<Obj: key>(id: &mut UID, new_owner: String, obj: &Obj) {
        assert!(ownership::is_valid_(id, obj), ENO_OWNERSHIP_AUTHORITY);

        ownership::transfer(Self {}, id, new_owner);
    }

    // Transfer using witness as authority
    public fun transfer_with_witness<Witness: drop>(witness: Witness, id: &mut UID, new_owner: String) {
        assert!(ownership::is_valid_witness<Witness>(id), ENO_OWNERSHIP_AUTHORITY);

        ownership::transfer(Self {}, id, new_owner);
    }
}