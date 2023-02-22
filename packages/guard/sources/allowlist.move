module guard::allowlist {
    use std::vector;

    use sui::dynamic_field;

    use guard::guard::{Self, Key, Guard};

    struct Allowlist has store {
        addresses: vector<address>
    }

    const ALLOWLIST_GUARD_ID: u64 = 1;

    const EKeyNotSet: u64 = 0;
    const EAddressNotAllowed: u64 = 1;

    public fun empty<T>(guard: &mut Guard<T>) {
        create(guard, vector::empty<address>());
    }

    public fun create<T>(guard: &mut Guard<T>, addresses: vector<address>) {
        let allow_list =  Allowlist { 
            addresses 
        };

        let key = guard::key(ALLOWLIST_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Allowlist>(uid, key, allow_list)
    }

    public fun validate<T>(guard: &Guard<T>, addr: address) {
        let key = guard::key(ALLOWLIST_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Allowlist>(uid, key), EKeyNotSet);
        let allow_list = dynamic_field::borrow<Key, Allowlist>(uid, key);

        assert!(vector::contains(&allow_list.addresses, &addr), EAddressNotAllowed)
    }  
}