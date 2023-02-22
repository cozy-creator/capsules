module guard::sender {
    use sui::dynamic_field;
    use sui::tx_context::{Self, TxContext};

    use guard::guard::{Self, Key, Guard};

    struct Sender has store {
        value: address
    }

    const SENDER_GUARD_ID: u64 = 2;

    public fun create(guard: &mut Guard, value: address) {
        let sender =  Sender { 
            value 
        };

        let key = guard::key(SENDER_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Sender>(uid, key, sender);
    }

    public fun validate(guard: &Guard, ctx: &TxContext) {
        let key = guard::key(SENDER_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Sender>(uid, key), 0);
        let sender = dynamic_field::borrow<Key, Sender>(uid, key);

        assert!(sender.value == tx_context::sender(ctx), 0)
    }  
}