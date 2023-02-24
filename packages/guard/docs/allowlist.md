
<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist"></a>

# Module `0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::allowlist`



-  [Struct `Allowlist`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist)
-  [Constants](#@Constants_0)
-  [Function `empty`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_empty)
-  [Function `create`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_create)
-  [Function `validate`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_validate)
-  [Function `allow`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_allow)
-  [Function `is_allowed`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_is_allowed)


<pre><code><b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::guard</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::object</a>;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist"></a>

## Struct `Allowlist`



<pre><code><b>struct</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist">Allowlist</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>addresses: <a href="">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_ALLOWLIST_GUARD_ID"></a>



<pre><code><b>const</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_ALLOWLIST_GUARD_ID">ALLOWLIST_GUARD_ID</a>: u64 = 1;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_EAddressNotAllowed"></a>



<pre><code><b>const</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_EAddressNotAllowed">EAddressNotAllowed</a>: u64 = 1;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_EKeyNotSet"></a>



<pre><code><b>const</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_EKeyNotSet">EKeyNotSet</a>: u64 = 0;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_empty"></a>

## Function `empty`



<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_empty">empty</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_empty">empty</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;) {
    <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_create">create</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>, <a href="_empty">vector::empty</a>&lt;<b>address</b>&gt;());
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_create"></a>

## Function `create`



<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_create">create</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, addresses: <a href="">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_create">create</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, addresses: <a href="">vector</a>&lt;<b>address</b>&gt;) {
    <b>let</b> allow_list =  <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist">Allowlist</a> {
        addresses
    };

    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_ALLOWLIST_GUARD_ID">ALLOWLIST_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <a href="_add">dynamic_field::add</a>&lt;Key, <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist">Allowlist</a>&gt;(uid, key, allow_list)
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_validate"></a>

## Function `validate`



<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_validate">validate</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, addresses: <a href="">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_validate">validate</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &Guard&lt;T&gt;, addresses: <a href="">vector</a>&lt;<b>address</b>&gt;) {
    <b>let</b> (i, len) = (0, <a href="_length">vector::length</a>(&addresses));

    <b>while</b>(i &lt; len) {
        <b>let</b> addr = <a href="_pop_back">vector::pop_back</a>(&<b>mut</b> addresses);
        <b>assert</b>!(<a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_is_allowed">is_allowed</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>, addr), <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_EAddressNotAllowed">EAddressNotAllowed</a>);

        i = i + 1;
    }
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_allow"></a>

## Function `allow`



<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_allow">allow</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, addresses: <a href="">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_allow">allow</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, addresses: <a href="">vector</a>&lt;<b>address</b>&gt;) {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_ALLOWLIST_GUARD_ID">ALLOWLIST_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist">Allowlist</a>&gt;(uid, key), <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_EKeyNotSet">EKeyNotSet</a>);
    <b>let</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist">allowlist</a> = <a href="_borrow_mut">dynamic_field::borrow_mut</a>&lt;Key, <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist">Allowlist</a>&gt;(uid, key);

    <b>let</b> (i, len) = (0, <a href="_length">vector::length</a>(&addresses));
    <b>while</b>(i &lt; len) {
        <b>let</b> addr = <a href="_borrow">vector::borrow</a>(&<b>mut</b> addresses, i);
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist">allowlist</a>.addresses, *addr);

        i = i + 1;
    }
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_is_allowed"></a>

## Function `is_allowed`



<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_is_allowed">is_allowed</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, addr: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_is_allowed">is_allowed</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &Guard&lt;T&gt;, addr: <b>address</b>): bool {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_ALLOWLIST_GUARD_ID">ALLOWLIST_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid">guard::uid</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist">Allowlist</a>&gt;(uid, key), <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_EKeyNotSet">EKeyNotSet</a>);
    <b>let</b> <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist">allowlist</a> = <a href="_borrow">dynamic_field::borrow</a>&lt;Key, <a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist_Allowlist">Allowlist</a>&gt;(uid, key);

    <a href="_contains">vector::contains</a>(&<a href="allowlist.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_allowlist">allowlist</a>.addresses, &addr)
}
</code></pre>



</details>
