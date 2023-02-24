
<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment"></a>

# Module `0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::payment`

Payment guard

This guard enables the validating, collecting and taking of any Sui coin type.
It allows for the setting of payment amount, coin type and payment taker.

```move
let guard = guard::initialize<Witness>(&Witness {}, ctx);

// create payment guard
payment::create<Witness, SUI>(&mut guard, 10000, @0xFEAC);

// validate a payment
payment::validate<Witness, SUI>(&guard, &coins);

// collect a payment
payment::collect<Witness, SUI>(&mut guard, coins, ctx);

// take an amount from payment balance
let coin = payment::take<Witness, SUI>(&mut guard, 10000, ctx);
transfer::transfer(coin, @0xAEBF)
```


-  [Struct `Payment`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment)
-  [Constants](#@Constants_0)
-  [Function `create`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_create)
-  [Function `validate`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_validate)
-  [Function `collect`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_collect)
-  [Function `take`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_take)
-  [Function `balance_value`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_balance_value)


<pre><code><b>use</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::guard</a>;
<b>use</b> <a href="">0x2::balance</a>;
<b>use</b> <a href="">0x2::coin</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment"></a>

## Struct `Payment`



<pre><code><b>struct</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="">balance</a>: <a href="_Balance">balance::Balance</a>&lt;C&gt;</code>
</dt>
<dd>
 the total balance of coins paid
</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>
 the amount of payment to be collected
</dd>
<dt>
<code>taker: <b>address</b></code>
</dt>
<dd>
 the address that can take from the collected payment
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EKeyNotSet"></a>



<pre><code><b>const</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EKeyNotSet">EKeyNotSet</a>: u64 = 0;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EInvalidPayment"></a>



<pre><code><b>const</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EInvalidPayment">EInvalidPayment</a>: u64 = 1;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EInvalidTaker"></a>



<pre><code><b>const</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EInvalidTaker">EInvalidTaker</a>: u64 = 2;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_PAYMENT_GUARD_ID"></a>



<pre><code><b>const</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_PAYMENT_GUARD_ID">PAYMENT_GUARD_ID</a>: u64 = 0;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_create"></a>

## Function `create`

Creates a new payment guard type <code>T</code> and coin type <code>C</code>
amount: <code>u64</code> - amount of payment to collect
taker: <code><b>address</b></code> - address that can take from the collected payment


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_create">create</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, amount: u64, taker: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_create">create</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, amount: u64, taker: <b>address</b>) {
    <b>let</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a> =  <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt; {
        <a href="">balance</a>: <a href="_zero">balance::zero</a>(),
        amount,
        taker
    };

    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_PAYMENT_GUARD_ID">PAYMENT_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <a href="_add">dynamic_field::add</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a>);
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_validate"></a>

## Function `validate`

Validates the payment of coin type <code>C</code> against guard type <code>T</code>
The validation checks include:
- payment guard existence
- total coin type <code>T</code> value is greater than or equal to the configured payment amount

coins: <code>&<a href="">vector</a>&lt;Coin&lt;C&gt;&gt;</code> - vector of coin type <code>T</code> to be used for payment


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_validate">validate</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, coins: &<a href="">vector</a>&lt;<a href="_Coin">coin::Coin</a>&lt;C&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_validate">validate</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &Guard&lt;T&gt;, coins: &<a href="">vector</a>&lt;Coin&lt;C&gt;&gt;) {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_PAYMENT_GUARD_ID">PAYMENT_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid">guard::uid</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key), <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EKeyNotSet">EKeyNotSet</a>);
    <b>let</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a> = <a href="_borrow">dynamic_field::borrow</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key);

    <b>let</b> (i, total, len) = (0, 0, <a href="_length">vector::length</a>(coins));

    <b>while</b>(i &lt; len) {
        <b>let</b> <a href="">coin</a> = <a href="_borrow">vector::borrow</a>(coins, i);
        total = total + <a href="_value">coin::value</a>(<a href="">coin</a>);

        i = i + 1;
    };

    <b>assert</b>!(total &gt;= <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a>.amount, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EInvalidPayment">EInvalidPayment</a>)
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_collect"></a>

## Function `collect`

Collects the payment of coin type <code>C</code>
coins: <code>&<a href="">vector</a>&lt;Coin&lt;C&gt;&gt;</code> - vector of coin type <code>T</code> to be used for payment


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_collect">collect</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, coins: <a href="">vector</a>&lt;<a href="_Coin">coin::Coin</a>&lt;C&gt;&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_collect">collect</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, coins: <a href="">vector</a>&lt;Coin&lt;C&gt;&gt;, ctx: &<b>mut</b> TxContext) {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_PAYMENT_GUARD_ID">PAYMENT_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key), <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EKeyNotSet">EKeyNotSet</a>);
    <b>let</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a> = <a href="_borrow_mut">dynamic_field::borrow_mut</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key);

    <b>let</b> <a href="">coin</a> = <a href="_pop_back">vector::pop_back</a>(&<b>mut</b> coins);
    <b>let</b> (i, len) = (0, <a href="_length">vector::length</a>(&coins));

    <b>while</b>(i &lt; len) {
        <a href="_join">coin::join</a>(&<b>mut</b> <a href="">coin</a>, <a href="_pop_back">vector::pop_back</a>(&<b>mut</b> coins));
        i = i + 1;
    };

    <a href="_destroy_empty">vector::destroy_empty</a>(coins);

    <b>let</b> coin_balance = <a href="_into_balance">coin::into_balance</a>(<a href="_split">coin::split</a>(&<b>mut</b> <a href="">coin</a>, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a>.amount, ctx));
    <a href="_join">balance::join</a>(&<b>mut</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a>.<a href="">balance</a>, coin_balance);

    <b>if</b>(<a href="_value">coin::value</a>(&<a href="">coin</a>) == 0) {
        <a href="_destroy_zero">coin::destroy_zero</a>(<a href="">coin</a>);
    } <b>else</b> {
        <a href="_transfer">transfer::transfer</a>(<a href="">coin</a>, <a href="_sender">tx_context::sender</a>(ctx));
    };
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_take"></a>

## Function `take`

Takes an amount from the available payment balance
amount: <code>u64</code> - amount to be taken from the payment balance


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_take">take</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, amount: u64, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="_Coin">coin::Coin</a>&lt;C&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_take">take</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, amount: u64, ctx: &<b>mut</b> TxContext): Coin&lt;C&gt; {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_PAYMENT_GUARD_ID">PAYMENT_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key), 0);
    <b>let</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a> = <a href="_borrow_mut">dynamic_field::borrow_mut</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key);

    <b>assert</b>!(<a href="_sender">tx_context::sender</a>(ctx) == <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a>.taker, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_EInvalidTaker">EInvalidTaker</a>);

    <a href="_take">coin::take</a>(&<b>mut</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a>.<a href="">balance</a>, amount, ctx)
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_balance_value"></a>

## Function `balance_value`

Returns the balance value of the payment availabe in a guard


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_balance_value">balance_value</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_balance_value">balance_value</a>&lt;T, C&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &Guard&lt;T&gt;): u64 {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_PAYMENT_GUARD_ID">PAYMENT_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid">guard::uid</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key), 0);
    <b>let</b> <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a> = <a href="_borrow">dynamic_field::borrow</a>&lt;Key, <a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment_Payment">Payment</a>&lt;C&gt;&gt;(uid, key);

    <a href="_value">balance::value</a>(&<a href="payment.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_payment">payment</a>.<a href="">balance</a>)
}
</code></pre>



</details>
