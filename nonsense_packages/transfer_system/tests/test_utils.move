#[test_only]
module transfer_system::test_utils {
    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, Coin};
    
    public fun init_scenario(addr: address): Scenario {
        test_scenario::begin(addr)
    }

    public fun end_scenario(scenario: Scenario) {
        test_scenario::end(scenario);
    }

    public fun mint_coin<C>(scenario: &mut Scenario, value: u64): Coin<C> {
        let ctx = test_scenario::ctx(scenario);
        coin::mint_for_testing<C>(value, ctx)
    }

    public fun burn_coin<C>(coin: Coin<C>) {
        coin::burn_for_testing<C>(coin);
    }
}