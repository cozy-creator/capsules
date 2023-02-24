
<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard"></a>

# Module `0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::guard`

Guard makes it easy to add access restriction and control to any Sui move package or object.
The module implements a set of guard you can choose from and use in your move code. Some of the available
guards to include payment, package, sender etc.


-  [Resource `Guard`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard)
-  [Struct `Key`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Key)
-  [Function `initialize`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_initialize)
-  [Function `transfer`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_transfer)
-  [Function `share_object`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_share_object)
-  [Function `key`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key)
-  [Function `extend`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend)
-  [Function `uid`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid)


<pre><code><b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard"></a>

## Resource `Guard`



<pre><code><b>struct</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">Guard</a>&lt;T&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="_UID">object::UID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Key"></a>

## Struct `Key`



<pre><code><b>struct</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Key">Key</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>slot: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_initialize"></a>

## Function `initialize`

Inititalizes a new instance of the guard object for <code>T</code>.
This is the base on which the main guards will be built upon.


<pre><code><b>public</b> <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_initialize">initialize</a>&lt;T&gt;(_witness: &T, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_initialize">initialize</a>&lt;T&gt;(_witness: &T, ctx: &<b>mut</b> TxContext): <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">Guard</a>&lt;T&gt; {
    <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">Guard</a>&lt;T&gt; {
        id: <a href="_new">object::new</a>(ctx)
    }
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_transfer"></a>

## Function `transfer`

Transfers a guard <code>T</code> to an owner (currently, the transaction sender)


<pre><code><b>public</b> <b>fun</b> <a href="">transfer</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="">transfer</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">Guard</a>&lt;T&gt;, ctx: &<b>mut</b> TxContext) {
    <a href="_transfer">transfer::transfer</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>, <a href="_sender">tx_context::sender</a>(ctx))
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_share_object"></a>

## Function `share_object`

Makes a guard <code>T</code> to a shared object


<pre><code><b>public</b> <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_share_object">share_object</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_share_object">share_object</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">Guard</a>&lt;T&gt;) {
    <a href="_share_object">transfer::share_object</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>)
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key"></a>

## Function `key`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">key</a>(slot: u64): <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Key">guard::Key</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">key</a>(slot: u64): <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Key">Key</a> {
    <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Key">Key</a> { slot }
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend"></a>

## Function `extend`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">extend</a>&lt;T&gt;(self: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;): &<b>mut</b> <a href="_UID">object::UID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">extend</a>&lt;T&gt;(self: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">Guard</a>&lt;T&gt;): &<b>mut</b> UID {
    &<b>mut</b> self.id
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid"></a>

## Function `uid`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid">uid</a>&lt;T&gt;(self: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;): &<a href="_UID">object::UID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid">uid</a>&lt;T&gt;(self: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">Guard</a>&lt;T&gt;): &UID {
    &self.id
}
</code></pre>



</details>
