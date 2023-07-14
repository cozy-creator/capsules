module guard::sender {
    use sui::dynamic_field;
    use sui::tx_context::{Self, TxContext};

    use guard::guard::{Self, Key, Guard};

    struct Sender has store {
        value: address
    }

    const SENDER_GUARD_ID: u64 = 2;

    const EKeyNotSet: u64 = 0;
    const EInvalidSender: u64 = 1;

    public fun create<T>(guard: &mut Guard<T>, _witness: &T, value: address) {
        let sender =  Sender { 
            value 
        };

        let key = guard::key(SENDER_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Sender>(uid, key, sender);
    }

    public fun update<T>(guard: &mut Guard<T>, _witness: &T, value: address) {
        let key = guard::key(SENDER_GUARD_ID);
        let uid = guard::extend(guard);

        assert!(dynamic_field::exists_with_type<Key, Sender>(uid, key), EKeyNotSet);
        let sender = dynamic_field::borrow_mut<Key, Sender>(uid, key);

        sender.value = value;
    }

    public fun validate<T>(guard: &Guard<T>, _witness: &T, ctx: &TxContext) {
        let key = guard::key(SENDER_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Sender>(uid, key), EKeyNotSet);
        let sender = dynamic_field::borrow<Key, Sender>(uid, key);

        assert!(sender.value == tx_context::sender(ctx), EInvalidSender)
    }  
}