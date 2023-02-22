module guard::guard {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};

    friend guard::payment;
    friend guard::allowlist;
    friend guard::sender;
    friend guard::package;

    struct Guard<phantom T> has key {
        id: UID
    }

    struct Key has copy, drop, store {
        slot: u64
    }

    public fun initialize<T>(_witness: &T, ctx: &mut TxContext): Guard<T> {
        Guard<T> {
            id: object::new(ctx)
        }
    }

    public fun transfer<T>(guard: Guard<T>, ctx: &mut TxContext) {
        transfer::transfer(guard, tx_context::sender(ctx))
    }

    public fun share_object<T>(guard: Guard<T>) {
        transfer::share_object(guard)
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