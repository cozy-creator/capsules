/// Guard makes it easy to add access restriction and control to any Sui move package. \
/// The module implements a set of guard you can choose from and use in your move code. Some of the available 
/// guards to include payment, package, sender etc.

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

    /// Inititalizes a new instance of the guard object for `T` \
    /// This is the base on which the main guards will be built upon.
    public fun initialize<T>(_witness: &T, ctx: &mut TxContext): Guard<T> {
        Guard {
            id: object::new(ctx)
        }
    }

    /// Transfers a guard to an owner (currently, the transaction sender)
    public fun transfer<T>(guard: Guard<T>, _witness: &T, ctx: &mut TxContext) {
        transfer::transfer(guard, tx_context::sender(ctx))
    }

    /// Makes a guard to a shared object
    public fun share_object<T>(guard: Guard<T>, _witness: &T) {
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

#[test_only]
module guard::guard_test {
    use sui::test_scenario::{Self, Scenario};

    use guard::guard;

    public fun initialize_scenario<T>(witness: &T, sender: address): Scenario {
        let scenario = test_scenario::begin(sender);
        let ctx = test_scenario::ctx(&mut scenario);

        let guard = guard::initialize(witness, ctx);
        guard::share_object(guard, witness);
        test_scenario::next_tx(&mut scenario, sender);

        scenario
    }
}