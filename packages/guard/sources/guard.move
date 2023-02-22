module guard::guard {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};

    friend guard::payment;
    friend guard::allow_list;
    friend guard::sender;
    friend guard::package;

    struct Guard<phantom T> has key {
        id: UID
    }

    struct Key has copy, drop, store {
        slot: u64
    }

    public entry fun initialize<T>(ctx: &mut TxContext) {
        let guard = Guard<T> {
            id: object::new(ctx)
        };

        transfer::transfer(guard, tx_context::sender(ctx));
    }

    public(friend) fun key(slot: u64): Key {
        Key { slot }
    }

    public(friend) fun extend<T>(self: &mut Guard<T>): &mut UID {
        &mut self.id
    }

    public(friend) fun uid<T>(self: &Guard<T>): &UID {
        &self.id
    }
}