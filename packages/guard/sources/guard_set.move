module guard::guard_set {
    use std::vector;

    use sui::transfer;
    use sui::bag::{Self, Bag};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    friend guard::allow_list;
    friend guard::coin_payment;

    struct GuardSet<phantom T> has key, store { 
        id: UID,
        data: GuardSetData
    }

    struct GuardSetData has store {
        guards: Bag,
        enabled: vector<u8>
    }

    public fun create<T: drop>(_witness: &T, ctx: &mut TxContext): GuardSet<T> {
        GuardSet {
            id: object::new(ctx),
            data: GuardSetData {
                guards: bag::new(ctx),
                enabled: vector::empty(),
            }
        }
    }

    public fun return_and_share<T: drop>(self: GuardSet<T>, _witness: &T) {
        transfer::share_object(self)
    }

    public fun guards<T>(self: &GuardSet<T>): &Bag {
        &self.data.guards
    }

    public(friend) fun guards_mut<T>(self: &mut GuardSet<T>): &mut Bag {
        &mut self.data.guards
    }
}

#[test_only]
module guard::guard_test {
    use sui::test_scenario::{Self, Scenario};

    use guard::guard;

    public fun initialize_scenario<T>(witness: &T, sender: address): Scenario {
        let scenario = test_scenario::begin(sender);
        let ctx = test_scenario::ctx(&mut scenario);

        let guard = guard::create(witness, ctx);
        guard::share_object(guard, witness);
        test_scenario::next_tx(&mut scenario, sender);

        scenario
    }
}