module capsule::capsule {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use capsule::ownership::{Self};
    use capsule::witness_authority;
    use metadata::schema::Schema;
    use metadata::metadata;

    const ENOT_OWNER: u64 = 0;

    struct Capsule<T> has key, store {
        id: UID,
        contents: T
    }

    public fun create<T: store>(id: UID, contents: T) {
        transfer::share_object(Capsule { id, contents });
    }

    public fun create_<Witness: drop, Transfer: drop, T: store>(
        witness: Witness,
        contents: T,
        owner: address,
        attributes: vector<vector<u8>>, // bytes for metadata
        schema: &Schema,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);

        witness_authority::bind<Witness>(&mut id);
        let witness = metadata::batch_add_attributes(witness, &mut id, attributes, schema, ctx);
        let witness = ownership::bind_transfer_authority<Witness, Transfer>(witness, &mut id, ctx);
        ownership::bind_owner(witness, &mut id, owner);

        create(id, contents);
    }

    public fun open<T: store>(capsule: &mut Capsule<T>, ctx: &TxContext): (&mut UID, &mut T) {
        assert!(ownership::is_valid_owner(&capsule.id, tx_context::sender(ctx)), ENOT_OWNER);

        (&mut capsule.id, &mut capsule.contents)
    }

    // When Sui supports optional reference arguments, we might be able to cobine open and open_
    // into one function.
    // Note that if the caller wants to use capsule.id as an owner, they should call into
    // `owner::borrow_ownership()` to change the owner from their auth-object ID to the address
    // calling into the function
    public fun open_<T: store, Object: key>(capsule: &mut Capsule<T>, auth: &Object): (&mut UID, &mut T) {
        assert!(ownership::is_valid_owner_(&capsule.id, auth), ENOT_OWNER);

        (&mut capsule.id, &mut capsule.contents)
    }

    // Perhaps we can add an open_and_own function as well? Might be 

    public fun extend<T: store>(capsule: &mut Capsule<T>): (&mut UID) {
        &mut capsule.id
    }
}

