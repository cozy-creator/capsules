/// Payment guard
/// 
/// This guard enables the validating, collecting and taking of any Sui coin type. \
/// It allows for the setting of payment amount, coin type and payment taker.


module guard::payment {
    use std::vector;

    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use sui::transfer;

    use guard::guard::{Self, Key, Guard};

    struct Payment<phantom C> has store {
        /// the total balance of coins paid
        balance: Balance<C>,
        /// the amount of payment to be collected
        amount: u64,
        /// the address that can take from the collected payment
        taker: address
    }

    const PAYMENT_GUARD_ID: u64 = 0;

    const EKeyNotSet: u64 = 0;
    const EInvalidPayment: u64 = 1;
    const EInvalidTaker: u64 = 2;

    /// Creates a new payment guard type `T` and coin type `C` \
    /// amount: `u64` - amount of payment to collect \
    /// taker: `address` - address that can take from the collected payment
    public fun create<T, C>(guard: &mut Guard<T>, _witness: &T, amount: u64, taker: address) {
        let payment =  Payment<C> {
            balance: balance::zero(),
            amount,
            taker
        };

        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Payment<C>>(uid, key, payment);
    }

    /// Validates the payment of coin type `C` against guard type `T` \
    /// The validation checks include:
    /// - payment guard existence
    /// - total coin type `T` value is greater than or equal to the configured payment amount
    /// 
    /// coins: `&vector<Coin<C>>` - vector of coin type `T` to be used for payment
    public fun validate<T, C>(guard: &Guard<T>, _witness: &T, coins: &vector<Coin<C>>) {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<C>>(uid, key), EKeyNotSet);
        let payment = dynamic_field::borrow<Key, Payment<C>>(uid, key);

        let (i, total, len) = (0, 0, vector::length(coins));

        while(i < len) {
            let coin = vector::borrow(coins, i);
            total = total + coin::value(coin);

            i = i + 1;
        };

        assert!(total >= payment.amount, EInvalidPayment)
    }

    /// Collects the payment of coin type `C` \
    /// coins: `&vector<Coin<C>>` - vector of coin type `T` to be used for payment
    public fun collect<T, C>(guard: &mut Guard<T>, _witness: &T, coins: vector<Coin<C>>, ctx: &mut TxContext) {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<C>>(uid, key), EKeyNotSet);
        let payment = dynamic_field::borrow_mut<Key, Payment<C>>(uid, key);

        let coin = vector::pop_back(&mut coins);
        let (i, len) = (0, vector::length(&coins));

        while(i < len) {
            coin::join(&mut coin, vector::pop_back(&mut coins));
            i = i + 1;
        };

        vector::destroy_empty(coins);

        let coin_balance = coin::into_balance(coin::split(&mut coin, payment.amount, ctx));
        balance::join(&mut payment.balance, coin_balance);

        if(coin::value(&coin) == 0) {
            coin::destroy_zero(coin);
        } else {
            transfer::transfer(coin, tx_context::sender(ctx));
        };
    }

    /// Takes an amount from the available payment balance \
    /// amount: `u64` - amount to be taken from the payment balance
    public fun take<T, C>(guard: &mut Guard<T>, _witness: &T, amount: u64, ctx: &mut TxContext): Coin<C> {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<C>>(uid, key), 0);
        let payment = dynamic_field::borrow_mut<Key, Payment<C>>(uid, key);

        assert!(tx_context::sender(ctx) == payment.taker, EInvalidTaker);

        coin::take(&mut payment.balance, amount, ctx)
    }

    /// Returns the balance value of the payment availabe in a guard
    public fun balance_value<T, C>(guard: &Guard<T>): u64 {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<C>>(uid, key), 0);
        let payment = dynamic_field::borrow<Key, Payment<C>>(uid, key);

        balance::value(&payment.balance)
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
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
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
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            payment::validate(&mut guard, &witness, &coins);
            test_scenario::return_shared(guard);
        };

        destroy_test_coins(coins);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = guard::payment::EInvalidPayment)]
    fun test_validate_payment_failure() {
        let (amount, sender) = (1000, @0xEFAE);
        let scenario = initialize_scenario(amount, sender);
        test_scenario::next_tx(&mut scenario, sender);

        let witness = Witness {};
        let coins = mint_test_coins<SUI>(&mut scenario, 200, 3);

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
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
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);

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
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
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
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            payment::collect(&mut guard, &witness, coins, test_scenario::ctx(&mut scenario));

            assert!(payment::balance_value<Witness, SUI>(&guard) == amount, 0);

            test_scenario::return_shared(guard);
            test_scenario::next_tx(&mut scenario, sender)
        };

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
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
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            payment::collect(&mut guard, &witness, coins, test_scenario::ctx(&mut scenario));

            assert!(payment::balance_value<Witness, SUI>(&guard) == amount, 0);

            test_scenario::return_shared(guard);
            test_scenario::next_tx(&mut scenario, @0xEFAC)
        };

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            let coin = payment::take<Witness, SUI>(&mut guard, &witness, 500, test_scenario::ctx(&mut scenario));

            destroy_test_coins(vector[coin]);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }
}