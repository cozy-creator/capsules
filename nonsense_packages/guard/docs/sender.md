
<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender"></a>

# Module `0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::sender`



-  [Struct `Sender`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender)
-  [Constants](#@Constants_0)
-  [Function `create`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_create)
-  [Function `update`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_update)
-  [Function `validate`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_validate)


<pre><code><b>use</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::guard</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender"></a>

## Struct `Sender`



<pre><code><b>struct</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender">Sender</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>value: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_EKeyNotSet"></a>



<pre><code><b>const</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_EKeyNotSet">EKeyNotSet</a>: u64 = 0;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_EInvalidSender"></a>



<pre><code><b>const</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_EInvalidSender">EInvalidSender</a>: u64 = 1;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_SENDER_GUARD_ID"></a>



<pre><code><b>const</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_SENDER_GUARD_ID">SENDER_GUARD_ID</a>: u64 = 2;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_create"></a>

## Function `create`



<pre><code><b>public</b> <b>fun</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_create">create</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, value: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_create">create</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, value: <b>address</b>) {
    <b>let</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender">sender</a> =  <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender">Sender</a> {
        value
    };

    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_SENDER_GUARD_ID">SENDER_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <a href="_add">dynamic_field::add</a>&lt;Key, <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender">Sender</a>&gt;(uid, key, <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender">sender</a>);
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_update"></a>

## Function `update`



<pre><code><b>public</b> <b>fun</b> <b>update</b>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, value: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <b>update</b>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, value: <b>address</b>) {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_SENDER_GUARD_ID">SENDER_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender">Sender</a>&gt;(uid, key), <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_EKeyNotSet">EKeyNotSet</a>);
    <b>let</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender">sender</a> = <a href="_borrow_mut">dynamic_field::borrow_mut</a>&lt;Key, <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender">Sender</a>&gt;(uid, key);

    <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender">sender</a>.value = value;
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_validate"></a>

## Function `validate`



<pre><code><b>public</b> <b>fun</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_validate">validate</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, ctx: &<a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_validate">validate</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &Guard&lt;T&gt;, ctx: &TxContext) {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_SENDER_GUARD_ID">SENDER_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid">guard::uid</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender">Sender</a>&gt;(uid, key), <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_EKeyNotSet">EKeyNotSet</a>);
    <b>let</b> <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender">sender</a> = <a href="_borrow">dynamic_field::borrow</a>&lt;Key, <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_Sender">Sender</a>&gt;(uid, key);

    <b>assert</b>!(<a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender">sender</a>.value == <a href="_sender">tx_context::sender</a>(ctx), <a href="sender.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_sender_EInvalidSender">EInvalidSender</a>)
}
</code></pre>



</details>
