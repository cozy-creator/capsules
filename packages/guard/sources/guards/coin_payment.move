module guard::coin_payment {
    use sui::bag;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};

    use guard::guard_id;
    use guard::guard_set::{Self, GuardSet};

    struct CoinPayment<phantom C> has store {
        amount: u64,
        balance: Balance<C>,
    }

    const EGuardAlreadyExist: u64 = 0;
    const EGuardDoesNotExist: u64 = 1;
    const EInvalidCoinPayment: u64 = 2;

    public fun create<T, C>(guard_set: &mut GuardSet<T>, _witness: &T, amount: u64) {
        let payment =  CoinPayment<C> {
            amount,
            balance: balance::zero(),
        };

        let guard_id = guard_id::coin_payment();
        let guards = guard_set::guards_mut(guard_set);

        assert!(!bag::contains(guards, guard_id), EGuardAlreadyExist);
        bag::add<u64, CoinPayment<C>>(guards, guard_id, payment);
    }

    public fun validate<T, C>(guard_set: &GuardSet<T>, coin: &Coin<C>) {
        let guard_id = guard_id::coin_payment();
        let guards = guard_set::guards(guard_set);

        assert!(bag::contains(guards, guard_id), EGuardDoesNotExist);

        let coin_payment = bag::borrow<u64, CoinPayment<C>>(guards, guard_id);
        assert!(coin::value(coin) >= coin_payment.amount, EInvalidCoinPayment)
    }

    public fun collect<T, C>(guard_set: &mut GuardSet<T>, _witness: &T, coin: Coin<C>, ctx: &mut TxContext) {
        let guard_id = guard_id::coin_payment();
        let guards = guard_set::guards_mut(guard_set);

        assert!(bag::contains(guards, guard_id), EGuardDoesNotExist);

        let coin_payment = bag::borrow_mut<u64, CoinPayment<C>>(guards, guard_id);
        let coin = split_coin_internal(coin, coin_payment.amount, ctx);
        balance::join(&mut coin_payment.balance, coin::into_balance(coin));
    }

    public fun withdraw<T, C>(guard_set: &mut GuardSet<T>, _witness: &T, amount: u64, ctx: &mut TxContext): Coin<C> {
        let guard_id = guard_id::coin_payment();
        let guards = guard_set::guards_mut(guard_set);

        assert!(bag::contains(guards, guard_id), EGuardDoesNotExist);

        let coin_payment = bag::borrow_mut<u64, CoinPayment<C>>(guards, guard_id);
        coin::take(&mut coin_payment.balance, amount, ctx)
    }

    public fun balance<T, C>(guard_set: &GuardSet<T>): u64 {
        let guard_id = guard_id::coin_payment();
        let guards = guard_set::guards(guard_set);

        assert!(bag::contains(guards, guard_id), EGuardDoesNotExist);

        let coin_payment = bag::borrow<u64, CoinPayment<C>>(guards, guard_id);
        balance::value(&coin_payment.balance)
    }

    fun split_coin_internal<C>(coin: Coin<C>, amount: u64, ctx: &mut TxContext): Coin<C> {
        if(coin::value(&coin) > amount) { 
            let split_coin = coin::split(&mut coin, amount, ctx);
            if(coin::value(&coin) == 0) {
                coin::destroy_zero(coin);
            } else {
                transfer::public_transfer(coin, tx_context::sender(ctx));
            };

            split_coin
        } else { 
            coin 
        }
    }
}


#[test_only]
module guard::payment_test {
    use std::vector;

    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use guard::guard::Guard;
    use guard::payment;

    use guard::guard_test;

    struct Witness has drop {}

    fun initialize_scenario(amount: u64, sender: address): Scenario {
        let witness = Witness {};
        let scenario = guard_test::initialize_scenario(&witness, sender);      

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            payment::create<Witness, SUI>(&mut guard, &witness, amount, sender);
            test_scenario::return_shared(guard);
        };

        scenario
    }

    fun mint_test_coins<C>(scenario: &mut Scenario, value: u64, count: u8): vector<Coin<C>> {
        let ctx = test_scenario::ctx(scenario);
        let (i, coins) =  (0, vector::empty<Coin<C>>());

        while(i <= count) {
            let coin = coin::mint_for_testing<C>(value, ctx);
            vector::push_back(&mut coins, coin);

            i = i + 1;
        };

        coins
    }

    fun destroy_test_coins<C>(coins: vector<Coin<C>>) {
        let (i, len) =  (0, vector::length(&coins));

        while(i < len) {
            let coin = vector::pop_back(&mut coins);
            coin::destroy_for_testing<C>(coin);

            i = i + 1;
        };

        vector::destroy_empty(coins)
    }

    #[test]
    fun test_validate_payment() {
        let (amount, sender) = (1000, @0xEFAE);
        let scenario = initialize_scenario(amount, sender);
        test_scenario::next_tx(&mut scenario, sender);

        let witness = Witness {};
        let coins = mint_test_coins<SUI>(&mut scenario, 200, 5);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            payment::validate(&mut guard, &witness, &coins);
            test_scenario::return_shared(guard);
        };

        destroy_test_coins(coins);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = guard::payment::EInvalidCoinPayment)]
    fun test_validate_payment_failure() {
        let (amount, sender) = (1000, @0xEFAE);
        let scenario = initialize_scenario(amount, sender);
        test_scenario::next_tx(&mut scenario, sender);

        let witness = Witness {};
        let coins = mint_test_coins<SUI>(&mut scenario, 200, 3);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            payment::validate(&mut guard, &witness, &coins);
            test_scenario::return_shared(guard);
        };

        destroy_test_coins(coins);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_collect_payment() {
        let (amount, sender) = (1000, @0xEFAE);
        let scenario = initialize_scenario(amount, sender);
        test_scenario::next_tx(&mut scenario, sender);

        let witness = Witness {};
        let coins = mint_test_coins<SUI>(&mut scenario, 200, 5);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);

            payment::collect(&mut guard, &witness, coins, test_scenario::ctx(&mut scenario));
            assert!(payment::balance_value<Witness, SUI>(&guard) == amount, 0);

            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = sui::balance::ENotEnough)]
    fun test_collect_payment_not_enough_failure() {
        let (amount, sender) = (1000, @0xEFAE);
        let scenario = initialize_scenario(amount, sender);
        test_scenario::next_tx(&mut scenario, sender);

        let witness = Witness {};
        let coins = mint_test_coins<SUI>(&mut scenario, 200, 3);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            payment::collect(&mut guard, &witness, coins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_take_payment() {
        let (amount, sender) = (1000, @0xEFAE);
        let scenario = initialize_scenario(amount, sender);
        test_scenario::next_tx(&mut scenario, sender);

        let witness = Witness {};
        let coins = mint_test_coins<SUI>(&mut scenario, 200, 5);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            payment::collect(&mut guard, &witness, coins, test_scenario::ctx(&mut scenario));

            assert!(payment::balance_value<Witness, SUI>(&guard) == amount, 0);

            test_scenario::return_shared(guard);
            test_scenario::next_tx(&mut scenario, sender)
        };

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            let coin = payment::take<Witness, SUI>(&mut guard, &witness, 500, test_scenario::ctx(&mut scenario));

            assert!(payment::balance_value<Witness, SUI>(&guard) == 500, 0);
            
            destroy_test_coins(vector[coin]);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = guard::payment::EInvalidTaker)]
    fun test_take_payment_invalid_taker_failure() {
        let (amount, sender) = (1000, @0xEFAE);
        let scenario = initialize_scenario(amount, sender);
        test_scenario::next_tx(&mut scenario, sender);

        let witness = Witness {};
        let coins = mint_test_coins<SUI>(&mut scenario, 200, 5);

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            payment::collect(&mut guard, &witness, coins, test_scenario::ctx(&mut scenario));

            assert!(payment::balance_value<Witness, SUI>(&guard) == amount, 0);

            test_scenario::return_shared(guard);
            test_scenario::next_tx(&mut scenario, @0xEFAC)
        };

        {
            let guard = test_scenario::take_shared<GuardSet<Witness>>(&scenario);
            let coin = payment::take<Witness, SUI>(&mut guard, &witness, 500, test_scenario::ctx(&mut scenario));

            destroy_test_coins(vector[coin]);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }
}