module guard::allow_list {
    use std::vector;

    use sui::dynamic_field;

    use guard::guard::{Self, Key, Guard};

    struct AllowList has store {
        addresses: vector<address>
    }

    const ALLOW_LIST_GUARD_ID: u64 = 1;

    fun new(addresses: vector<address>): AllowList {
        AllowList { addresses }
    }

    public fun empty(guard: &mut Guard) {
        set(guard, vector::empty<address>());
    }

    public fun set(guard: &mut Guard, addresses: vector<address>) {
        let allow_list =  new(addresses);
        let key = guard::key(ALLOW_LIST_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, AllowList>(uid, key, allow_list);
    }

    public fun validate(guard: &Guard, addr: address) {
        let key = guard::key(ALLOW_LIST_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, AllowList>(uid, key), 0);
        let allow_list = dynamic_field::borrow<Key, AllowList>(uid, key);

        assert!(vector::contains(&allow_list.addresses, &addr), 0)
    }  
}