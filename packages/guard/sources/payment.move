module guard::payment {
    use std::vector;

    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use sui::transfer;

    use guard::guard::{Self, Key, Guard};

    struct Payment<phantom C> has store {
        balance: Balance<C>,
        amount: u64,
        taker: address
    }

    const PAYMENT_GUARD_ID: u64 = 0;

    const EKeyNotSet: u64 = 0;
    const EInvalidPayment: u64 = 1;
    const EInvalidTaker: u64 = 2;

    public fun create<T, C>(guard: &mut Guard<T>, amount: u64, taker: address) {
        let payment =  Payment<C> {
            balance: balance::zero(),
            amount,
            taker
        };

        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Payment<C>>(uid, key, payment);
    }

    public fun validate<T, C>(guard: &Guard<T>, coins: &vector<Coin<C>>) {
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

    public fun collect<T, C>(guard: &mut Guard<T>, coins: vector<Coin<C>>, ctx: &mut TxContext) {
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

    public fun take<T, C>(guard: &mut Guard<T>, amount: u64, ctx: &mut TxContext): Coin<C> {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<C>>(uid, key), 0);
        let payment = dynamic_field::borrow_mut<Key, Payment<C>>(uid, key);

        assert!(tx_context::sender(ctx) == payment.taker, EInvalidTaker);

        coin::take(&mut payment.balance, amount, ctx)
    }
}


#[test_only]
module guard::payment_test {
    use std::vector;

    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use guard::guard::{Self, Guard};
    use guard::payment;

    struct Witness has drop {}

    fun initialize_guard(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);

        let guard = guard::initialize(&Witness {}, ctx);
        guard::share_object(guard);
    }

    fun initialize_scenario(amount: u64, sender: address): Scenario {
        let scenario = test_scenario::begin(sender);

        initialize_guard(&mut scenario);        
        test_scenario::next_tx(&mut scenario, sender);
        
        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            payment::create<Witness, SUI>(&mut guard, amount, sender);
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

        let coins = mint_test_coins<SUI>(&mut scenario, 200, 5);

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            payment::validate<Witness, SUI>(&mut guard, &coins);
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

        let coins = mint_test_coins<SUI>(&mut scenario, 200, 3);

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            payment::validate<Witness, SUI>(&mut guard, &coins);
            test_scenario::return_shared(guard);
        };

        destroy_test_coins(coins);
        test_scenario::end(scenario);
    }
}