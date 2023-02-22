module guard::guard {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};

    friend guard::payment;

    struct Guard has key {
        id: UID,
        object_id: ID
    }

    struct Key has copy, drop, store {
        slot: u64
    }

    public entry fun initialize<T: key>(object: &T, ctx: &mut TxContext) {
        let guard = initialize_(object, ctx);
        transfer::transfer(guard, tx_context::sender(ctx));
    }

    public fun initialize_<T: key>(object: &T, ctx: &mut TxContext): Guard {
        Guard {
            id: object::new(ctx),
            object_id: object::id(object)
        }
    }

    public fun key(slot: u64): Key {
        Key { slot }
    }

    public(friend) fun extend(self: &mut Guard): &mut UID {
        &mut self.id
    }

    public(friend) fun uid(self: &Guard): &UID {
        &self.id
    }
}