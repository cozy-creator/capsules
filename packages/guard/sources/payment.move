module guard::payment {
    use std::vector;

    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use sui::transfer;

    use guard::guard::{Self, Key, Guard};

    struct Payment<phantom T> has store {
        balance: Balance<T>,
        amount: u64
    }

    const PAYMENT_GUARD_ID: u64 = 0;

    fun new<T>(amount: u64): Payment<T> {
        Payment {
            balance: balance::zero(),
            amount
        }
    }

    public fun set<T>(guard: &mut Guard, amount: u64) {
        let payment =  new<T>(amount);
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Payment<T>>(uid, key, payment);
    }

    public fun validate<T>(guard: &Guard, coins: &vector<Coin<T>>) {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<T>>(uid, key), 0);
        let payment = dynamic_field::borrow<Key, Payment<T>>(uid, key);

        let (i, total, len) = (0, 0, vector::length(coins));

        while(i < len) {
            let coin = vector::borrow(coins, i);
            total = total + coin::value(coin);

            i = i + 1;
        };

        assert!(total >= payment.amount, 1)
    }

    public fun collect<T>(guard: &mut Guard, coins: vector<Coin<T>>, ctx: &mut TxContext) {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<T>>(uid, key), 0);
        let payment = dynamic_field::borrow_mut<Key, Payment<T>>(uid, key);

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

    public fun take<T>(guard: &mut Guard, amount: u64, ctx: &mut TxContext) {
        let key = guard::key(PAYMENT_GUARD_ID);
        let uid = guard::extend(guard);

        assert!(dynamic_field::exists_with_type<Key, Payment<T>>(uid, key), 0);
        let payment = dynamic_field::borrow_mut<Key, Payment<T>>(uid, key);

        let coin = coin::take(&mut payment.balance, amount, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }
}