// Are you sick and tired of being able to modify your objects?
// Do you wish you could just cast them into the eternal abyss of Sui's global memory storage,
// never to worry about modifying them again?
// Well boy do we have a module for you! This is just the immutable module you've been looking for!

module sui_utils::immutable {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    // Error constants
    const ECONTENTS_ARE_PRIVATE: u64 = 0;

    // Generic container, root-level frozen object
    struct Immutable<T: store> has key {
        id: UID,
        allow_read: bool,
        contents: T
    }

    public fun freeze_<T: store>(contents: T, allow_read: bool, ctx: &mut TxContext) {
        transfer::freeze_object(Immutable {
            id: object::new(ctx),
            allow_read,
            contents
        })
    }

    public fun borrow<T: store>(immutable: &Immutable<T>): &T {
        assert!(immutable.allow_read, ECONTENTS_ARE_PRIVATE);

        &immutable.contents
    }

}