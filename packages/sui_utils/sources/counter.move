module sui_utils::counter {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;

    struct Counter<phantom T> has key, store {
        id: UID,
        value: u256
    }

    public fun new_<T: drop>(_w: T, ctx: &mut TxContext): Counter<T> {
        Counter {
            id: object::new(ctx),
            value: 0
        }
    }

    public fun new<T: drop>(w: T, ctx: &mut TxContext) {
        transfer::share_object(new_(w, ctx))
    }

    public fun increment<T>(self: &mut Counter<T>, _w: &T): u256 {
        self.value = self.value + 1;
        self.value
    }

    public fun decrement<T>(self: &mut Counter<T>, _w: &T): u256 {
        self.value = self.value - 1;
        self.value
    }
}