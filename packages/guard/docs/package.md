
<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package"></a>

# Module `0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::package`

Package guard

This guard can be used to restrict thirdparty packages call to your module functions.
It leverages the witness pattern to ensure that a package calling a module function is allowed.

```move
let guard = guard::initialize<Witness>(&Witness {}, ctx);

// create package guard by passing the allowed package witness
package::create<Witness, AllowedPackageWitness>(&mut guard);

// create package guard by passing the allowed package id
package::create_<Witness>(&mut guard, allowed_package_id);

// validate a the package calling a function is allowed
package::validate<Witness, ThirdPartyPackageWitness>(&guard);
```


-  [Struct `Package`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package)
-  [Constants](#@Constants_0)
-  [Function `create`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create)
-  [Function `create_`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create_)
-  [Function `validate`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_validate)
-  [Function `update`](#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_update)


<pre><code><b>use</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">0x1b969b64e325bdb04ac114b01dd57aecf7c3c925::guard</a>;
<b>use</b> <a href="">0x20244f3cab18405108fb286865e2cf651c9f487::encode</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::object</a>;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package"></a>

## Struct `Package`



<pre><code><b>struct</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package">Package</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>value: <a href="_ID">object::ID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_EKeyNotSet"></a>



<pre><code><b>const</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_EKeyNotSet">EKeyNotSet</a>: u64 = 0;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_EInvalidPackage"></a>



<pre><code><b>const</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_EInvalidPackage">EInvalidPackage</a>: u64 = 1;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_PACKAGE_GUARD_ID"></a>



<pre><code><b>const</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_PACKAGE_GUARD_ID">PACKAGE_GUARD_ID</a>: u64 = 3;
</code></pre>



<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create"></a>

## Function `create`

Creates a new package guard using allowed package witness <code>W</code>


<pre><code><b>public</b> <b>fun</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create">create</a>&lt;T, W&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create">create</a>&lt;T, W&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;) {
    <b>let</b> id = <a href="_package_id">encode::package_id</a>&lt;W&gt;();
    <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create_">create_</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>, id);
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create_"></a>

## Function `create_`

Creates a new package guard using the allowed package id


<pre><code><b>public</b> <b>fun</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create_">create_</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;, id: <a href="_ID">object::ID</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_create_">create_</a>&lt;T&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;, id: ID) {
    <b>let</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package">package</a> = <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package">Package</a> {
        value: id
    };

    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_PACKAGE_GUARD_ID">PACKAGE_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <a href="_add">dynamic_field::add</a>&lt;Key, <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package">Package</a>&gt;(uid, key, <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package">package</a>)
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_validate"></a>

## Function `validate`

Validates that the package witness <code>W</code> against the guard type <code>T</code>


<pre><code><b>public</b> <b>fun</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_validate">validate</a>&lt;T, W&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_validate">validate</a>&lt;T, W&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &Guard&lt;T&gt;) {
    <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_PACKAGE_GUARD_ID">PACKAGE_GUARD_ID</a>);
    <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_uid">guard::uid</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

    <b>let</b> id = <a href="_package_id">encode::package_id</a>&lt;W&gt;();

    <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package">Package</a>&gt;(uid, key), <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_EKeyNotSet">EKeyNotSet</a>);
    <b>let</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package">package</a> = <a href="_borrow">dynamic_field::borrow</a>&lt;Key, <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package">Package</a>&gt;(uid, key);

    <b>assert</b>!(<a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package">package</a>.value == id, <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_EInvalidPackage">EInvalidPackage</a>)
}
</code></pre>



</details>

<a name="0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_update"></a>

## Function `update`

Updates the package guard with a new allowed package witness <code>W</code>


<pre><code><b>public</b> <b>fun</b> <b>update</b>&lt;T, W&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_Guard">guard::Guard</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <b>update</b>&lt;T, W&gt;(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>: &<b>mut</b> Guard&lt;T&gt;) {
     <b>let</b> key = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_key">guard::key</a>(<a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_PACKAGE_GUARD_ID">PACKAGE_GUARD_ID</a>);
     <b>let</b> uid = <a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard_extend">guard::extend</a>(<a href="guard.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_guard">guard</a>);

     <b>let</b> id = <a href="_package_id">encode::package_id</a>&lt;W&gt;();

     <b>assert</b>!(<a href="_exists_with_type">dynamic_field::exists_with_type</a>&lt;Key, <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package">Package</a>&gt;(uid, key), <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_EKeyNotSet">EKeyNotSet</a>);
     <b>let</b> <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package">package</a> = <a href="_borrow_mut">dynamic_field::borrow_mut</a>&lt;Key, <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package_Package">Package</a>&gt;(uid, key);

     <a href="package.md#0x1b969b64e325bdb04ac114b01dd57aecf7c3c925_package">package</a>.value = id;
 }
</code></pre>



</details>
