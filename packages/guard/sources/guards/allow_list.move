module guard::allow_list {
    use std::vector;

    use sui::bag;
    use sui::hash;

    use guard::guard_id;
    use guard::guard_set::{Self, GuardSet};

    struct AllowList has store {
        merkle_root: vector<u8>
    }

    const EGuardAlreadyExist: u64 = 0;
    const EGuardDoesNotExist: u64 = 1;
    const EInvalidBytesLength: u64 = 2;
    const EValueNotAllowed: u64 = 3;

    public fun create<T>(guard_set: &mut GuardSet<T>, _witness: &T, merkle_root: vector<u8>) {
        assert!(vector::length(&merkle_root) == 32, EInvalidBytesLength);

        let guard_id = guard_id::allow_list();
        let guards = guard_set::guards_mut(guard_set);

        assert!(!bag::contains(guards, guard_id), EGuardAlreadyExist);
        bag::add<u64, AllowList>(guards, guard_id, AllowList { merkle_root })
    }

    public fun validate<T>(guard_set: &GuardSet<T>, proof: vector<vector<u8>>, positions: vector<u8>, value: vector<u8>) {
        assert!(is_allowed(guard_set, proof, positions, value), EValueNotAllowed);
    }

    public fun update_merkle_root<T>(guard_set: &mut GuardSet<T>, _witness: &T, merkle_root: vector<u8>) {
        assert!(vector::length(&merkle_root) == 32, EInvalidBytesLength);

        let guard_id = guard_id::allow_list();
        let guards = guard_set::guards_mut(guard_set);

        assert!(bag::contains(guards, guard_id), EGuardDoesNotExist);

        let allow_list = bag::borrow_mut<u64, AllowList>(guards, guard_id);
        allow_list.merkle_root = merkle_root
    }

    public fun is_allowed<T>(guard_set: &GuardSet<T>, proof: vector<vector<u8>>, positions: vector<u8>, value: vector<u8>): bool {
        let guard_id = guard_id::allow_list();
        let guards = guard_set::guards(guard_set);

        assert!(bag::contains(guards, guard_id), EGuardDoesNotExist);

        let allow_list = bag::borrow<u64, AllowList>(guards, guard_id);
        verify_merkle_proof(proof, positions, allow_list.merkle_root, hash::keccak256(&value))
    }

    fun verify_merkle_proof(proof: vector<vector<u8>>, positions: vector<u8>, root: vector<u8>, leaf: vector<u8>): bool {
        assert!(vector::length(&root) == 32, EInvalidBytesLength);
        assert!(vector::length(&leaf) == 32, EInvalidBytesLength);

        let (i, proof_len, current_hash) = (0, vector::length(&proof), leaf);
        while (i < proof_len) {
            let position = *vector::borrow(&positions, i);
            let proof_hash = *vector::borrow_mut(&mut proof, i);

            if (position == 1) {
                vector::append(&mut current_hash, proof_hash);
                current_hash = hash::keccak256(&current_hash)
            } else {
                vector::append(&mut proof_hash, current_hash);
                current_hash = hash::keccak256(&proof_hash)
            };

            i = i + 1
        };

        current_hash == root
    }
}

#[test_only]
module guard_set::allow_list_test {
    use sui::test_scenario::{Self, Scenario};

    use guard_set::guard_set::Guard;
    use guard_set::allow_list;

    use guard_set::guard_test;

    struct Witness has drop {}

    fun initialize_scenario(sender: address, addresses: vector<address>): Scenario {
        let witness = Witness {};
        let scenario = guard_test::initialize_scenario(&witness, sender);      

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            allow_list::create<Witness>(&mut guard, &witness, addresses);
            test_scenario::return_shared(guard);
        };

        scenario
    }

    #[test]
    fun test_validate_allow_list() {
        let (sender, addresses) = (@0xFEAC, vector[@0x1AFB, @0xBABA, @0xEAFC]);
        let scenario = initialize_scenario(sender, addresses);
        let witness = Witness {};

        test_scenario::next_tx(&mut scenario, sender);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            allow_list::validate(&mut guard, &witness, addresses);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_allow_allow_list() {
        let (sender, addresses) = (@0xFEAC, vector[@0x1AFB, @0xBABA, @0xEAFC]);
        let scenario = initialize_scenario(sender, addresses);
        let witness = Witness {};

        test_scenario::next_tx(&mut scenario, sender);
        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            
            allow_list::allow(&mut guard, &witness, vector[@0xAE5C]);
            test_scenario::return_shared(guard);
        };

        test_scenario::next_tx(&mut scenario, sender);
        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);

            allow_list::validate(&guard, &witness, vector[@0xAE5C, @0x1AFB]);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = guard_set::allow_list::EAddressNotAllowed)]
    fun test_validate_allow_list_failure() {
        let (sender, addresses) = (@0xFEAC, vector[@0x1AFB, @0xBABA, @0xEAFC]);
        let scenario = initialize_scenario(sender, addresses);
        let witness = Witness {};

        test_scenario::next_tx(&mut scenario, sender);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            allow_list::validate(&mut guard, &witness, vector[@0xAE5C]);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }
}