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

    public fun empty<T>(guard: &mut Guard<T>, witness: &T) {
        create(guard, witness, vector::empty<address>());
    }

    public fun create<T>(guard: &mut Guard<T>, _witness: &T, addresses: vector<address>) {
        let allow_list =  Allowlist { 
            addresses 
        };

        let key = guard::key(ALLOWLIST_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Allowlist>(uid, key, allow_list)
    }

    public fun validate<T>(guard: &Guard<T>, witness: &T, addresses: vector<address>) {
        let (i, len) = (0, vector::length(&addresses));

        while(i < len) {
            let addr = vector::pop_back(&mut addresses);
            assert!(is_allowed(guard, witness, addr), EAddressNotAllowed);

            i = i + 1;
        }
    }

    public fun allow<T>(guard: &mut Guard<T>, _witness: &T, addresses: vector<address>) {
        let key = guard::key(ALLOWLIST_GUARD_ID);
        let uid = guard::extend(guard);

        assert!(dynamic_field::exists_with_type<Key, Allowlist>(uid, key), EKeyNotSet);
        let allowlist = dynamic_field::borrow_mut<Key, Allowlist>(uid, key);

        let (i, len) = (0, vector::length(&addresses));
        while(i < len) {
            let addr = vector::borrow(&mut addresses, i);
            vector::push_back(&mut allowlist.addresses, *addr);

            i = i + 1;
        }
    }

    public fun is_allowed<T>(guard: &Guard<T>, _witness: &T, addr: address): bool {
        let key = guard::key(ALLOWLIST_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Allowlist>(uid, key), EKeyNotSet);
        let allowlist = dynamic_field::borrow<Key, Allowlist>(uid, key);

        vector::contains(&allowlist.addresses, &addr)
    }
}

#[test_only]
module guard::allowlist_test {
    use sui::test_scenario::{Self, Scenario};

    use guard::guard::Guard;
    use guard::allowlist;

    use guard::guard_test;

    struct Witness has drop {}

    fun initialize_scenario(sender: address, addresses: vector<address>): Scenario {
        let witness = Witness {};
        let scenario = guard_test::initialize_scenario(&witness, sender);      

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            allowlist::create<Witness>(&mut guard, &witness, addresses);
            test_scenario::return_shared(guard);
        };

        scenario
    }

    #[test]
    fun test_validate_allowlist() {
        let (sender, addresses) = (@0xFEAC, vector[@0x1AFB, @0xBABA, @0xEAFC]);
        let scenario = initialize_scenario(sender, addresses);
        let witness = Witness {};

        test_scenario::next_tx(&mut scenario, sender);

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            allowlist::validate(&mut guard, &witness, addresses);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_allow_allowlist() {
        let (sender, addresses) = (@0xFEAC, vector[@0x1AFB, @0xBABA, @0xEAFC]);
        let scenario = initialize_scenario(sender, addresses);
        let witness = Witness {};

        test_scenario::next_tx(&mut scenario, sender);
        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            
            allowlist::allow(&mut guard, &witness, vector[@0xAE5C]);
            test_scenario::return_shared(guard);
        };

        test_scenario::next_tx(&mut scenario, sender);
        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);

            allowlist::validate(&guard, &witness, vector[@0xAE5C, @0x1AFB]);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = guard::allowlist::EAddressNotAllowed)]
    fun test_validate_allowlist_failure() {
        let (sender, addresses) = (@0xFEAC, vector[@0x1AFB, @0xBABA, @0xEAFC]);
        let scenario = initialize_scenario(sender, addresses);
        let witness = Witness {};

        test_scenario::next_tx(&mut scenario, sender);

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            allowlist::validate(&mut guard, &witness, vector[@0xAE5C]);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }
}