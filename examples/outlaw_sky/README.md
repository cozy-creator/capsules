This is a walkthrough demonstrating how to create assets on Sui using Capsule-tools. We demonstrate two methods: (1) [using the Sui CLI](#sui-cli), and (2) [using the Sui Typescript SDK](#sui-typescript-sdk). The CLi is useful for developers performing their own ad-hoc operations, while the Typescript SDK is useful for webapps and Node.js servers.

---

## Sui CLI

This assumes you have the [Sui CLI installed](https://docs.sui.io/build/install), a keypair generated to submit transactions from, some gas from the faucet to pay for transactions, and that Sui devnet currently isn't broken (lol).

### Step 1: Publish Your Module

Inside of the ./package folder, run the command:

`sui client publish --gas-budget 3000`

This will return two UIDs, looking something like:

> Created Objects:
>
> ID: 0x973a1fc252d367ac06c66ee01c23cc8c713c5491 , Owner: Immutable
> ID: 0x13e39a18ee4182b3e02ce1dfd724a1567404699a , Owner: Account Address ( 0xbb81965d327c51d42d1081e5d81909652f05a675 )

The first ID is the package-id you just deployed, which is an immutable object, and the second ID is the package's publish-receipt, which is owned by whatever keypair you used to deploy the package.

### Step 2: Create a Metadata Schema (optional)

Schemas are immutable root-level owned objects used to enforce `(field-name, type)` pairings, making (de)serialization of on-chain metadata possible. Because schema-objects are immutable, they can never change or be deleted; if you want to change something about a schema, you'll have to create a new schema object. Normally you'd select some standard schema, such as `0xa26589d8c49a8f0ee5f70ad34025198b008ea493`, but if you want to write and deploy your own custom schema, use the following command:

`sui client call --package 0xeb85c3c33d99df932bcb26ef59c963cae67fb1d1 --module schema --function create --args "[ [\"name\", \"String\"], [ \"description\", \"Option<String>\" ], [ \"image\", \"String\" ], [ \"power_level\", \"u64\" ], [ \"attributes\", \"VecMap<String,String>\"] ]" --gas-budget 3000`

This defines 5 fields; `name`, `description`, `image`, `power level`, and `attributes`, which are are three utf8 strings followed by a u64 and finally a VecMap (essentially an array of key-value pairs). Only `description` is optional, while the other 4 fields are required.

### Step 3: Create Type Metadata (optional)

Our module is going to create a new type of object; an Outlaw. Our Outlaw type will be `<package-id>::outlaw_sky::Outlaw`; all Move types consist of the declaring package-id, module-name, and struct-name. Sometimes rather than defining metadata _per object_ we want to define metadata _per type_; suppose we have a field in our schema whose value doesn't vary per object, like `description`; if we create 10,000 outlaws, it would be rather redundant to duplicate the _same_ description value 10,000 times (once per object); what a waste of space! I mean who do you think we are here, _Metaplex_??? No! We can define our type metadata once, and then this acts as all of our Outlaw's 'default' metadata.

All we need is our publish receipt! But first, we have to define our default arguments:

`[ "Outlaw", "These are demo Outlaws created by CapsuleCreator for our tutorial", "https://pbs.twimg.com/profile_images/1569727324081328128/7sUnJvRg_400x400.jpg", 199u64, [] ]`

Unfortunately, if we supply this as an argument to the Sui CLI, it won't know how to serialize this hetergenous array as an array of arrays of bytes (`vector<vector<u8>>`). At some point the Sui CLI will hopefully support this, but for now we have a simple app that serializes your arguments for you. Putting the above arguments arguments in yields the serialized `vector<vector<u8>>` format:

`[ [6, 79, 117, 116, 108, 97, 119], [1, 65, 84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], [77, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [199, 0, 0, 0, 0, 0, 0, 0], [0] ]`

which we then put into our command as the second argument:

`sui client call --package 0xeb85c3c33d99df932bcb26ef59c963cae67fb1d1 --module type --function define --type-args 0x973a1fc252d367ac06c66ee01c23cc8c713c5491::outlaw_sky::Outlaw --args 0x13e39a18ee4182b3e02ce1dfd724a1567404699a "[ [6, 79, 117, 116, 108, 97, 119], [1, 65, 84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], [77, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [199, 0, 0, 0, 0, 0, 0, 0], [0] ]" 0xa26589d8c49a8f0ee5f70ad34025198b008ea493 --gas-budget 8000`

The first argument is our publish receipt; do you remember the object we got back in step-1? That publish receipt proves that we are the ones who published the package, and hence we have special priviliges to define type metadata for the structs we defined in our package (we wouldn't want random people on the internet defining metadata for our own objects!). Also note that type metadata is a **singleton object**; there will only ever be _one_ `metadata::type::Type<<package-id>::outlaw_sky::Outlaw>` in existence. If you try to run the command above again, it will fail! That's because metadata::type leaves a record on your package receipt recording that you used it to create your type metadata object. The next time you try to use that publish receipt again, metadata::type will see the leftover record and abort!

The third argument is our schema object again that we created above. Note that here we will be using this schema for _both_ our type-metadata as we well as our outlaws (see below); but this needn't be the case! They can both be wildly different schemas. However, it's recommend you always use _compatible_ schemas in case you use two different schemas. Two schemas are "compatible" if they both define the same type, i.e., if our schema defines the field `name` to be of type `String` or `Option<String>` these two schemes are considered compatible, but if another schema defines `name` as the type `vector<String>`, then this schema is not compatible. Two schemas are compatible _if and only if_ all of their overlapping field-names are of the same type `T` / `Option<T>`.

Now for the fun of it, let's try editing our type metadata! Try the following command:

**To Do:** Make this update more interesting

`sui client call --package 0xeb85c3c33d99df932bcb26ef59c963cae67fb1d1 --module type --function update --type-args 0x973a1fc252d367ac06c66ee01c23cc8c713c5491::outlaw_sky::Outlaw --args 0x5386dc0ffd2303a06529bff548c6b77a8fd49cfa "[ \"description\", \"image\", \"power_level\" ]" "[ [1, 65, 84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], [77, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [0, 0, 2, 0, 0, 0, 0, 0] ]" 0xa26589d8c49a8f0ee5f70ad34025198b008ea493 true --gas-budget 2000`

Notice how fast and cheap that was? Our transaction was completed in <2 seconds, and cost a measly 893 nanoSUI to write 150 bytes; on mainnet that'll likely be around 90,000 nanoSUI, which works out to 0.00009 SUI, which is equivalent to 5k edit-transactions for $1. Oof.

**TO DO: Insert Link to argument-serializer app**

### Step 4: Create Outlaw

Now let's call into the `create` function that we deployed in Step-1. This will create our first Outlaw! Remember that for the CLI, we have to serialize our data-argument as bytes, so this:

`[ "Kyrie", "", "https://pbs.twimg.com/profile_images/1569727324081328128/7sUnJvRg_400x400.jpg", 65536u64, [ Background, White, Face, Wholesome ]`

turns into this:

`sui client call --package 0x973a1fc252d367ac06c66ee01c23cc8c713c5491 --module outlaw_sky --function create --args "[ [5, 75, 121, 114, 105, 101], [], [77, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [1, 0, 0, 0, 0, 0, 0, 0], [ 2, 10, 66, 97, 99, 107, 103, 114, 111, 117, 110, 100, 5, 87, 104, 105, 116, 101, 4, 70, 97, 99, 101, 9, 87, 104, 111, 108, 101, 115, 111, 109, 101 ] ]" 0xa26589d8c49a8f0ee5f70ad34025198b008ea493 --gas-budget 9000`

This transaction will return a result that looks like this:

> ----- Transaction Effects ----
>
> Status : Success
>
> Created Objects:
>
> - ID: 0x1ca3c86fed5ad637143f15a81d2cc31a9ddb4144 , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
> - ID: 0x3137d76eaeefe7e396d1315eb47356aa7c271ce1 , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
> - ID: 0x5d7934cd96ad89586bdeb6d33589c863de23981f , Owner: Shared
> - ID: 0x51673c014cf020f331982096c68c7e29a4e958d4 , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
> - ID: 0x68e194c2373109a10bb36f569080647f64e71b4f , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
> - ID: 0x85af2fe01dfaa623eeeb34a5388de932efe5675c , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
> - ID: 0x952260e682f3ec20944d75518cd6b46fffa5c611 , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
> - ID: 0xa153e1aba646baa0e4c210d5b2e7c7de63aa42c3 , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
> - ID: 0xf41403d7706f796b2b9fba8d6ac825bc48196b28 , Owner: Object ID: ( 0x5d7934cd96ad89586bdeb6d33589c863de23981f )
>
>   Mutated Objects:
>
> - ID: 0x34b29facfdc4f34e97219d2a02e648b0f30b43de , Owner: Account Address ( 0xbb81965d327c51d42d1081e5d81909652f05a675 )

What are all these objects? For Sui, every dynamic field we add is its own 'object'; as you can see, all of these objects are owned by one object: `0x5d7934cd96ad89586bdeb6d33589c863de23981f`; that's our Outlaw! And all of the other objects are its dynamic fields.

Notice that our Outlaw is owned by `Shared`. This means it's not owned by us _directly_ within Sui, but rather, it's a shared-object other people and programs can call into. For owned objects, only we can construct transactions that use them, but for shared objects, other people can use them as transaction inputs too! That doesn't mean we have _no_ control over our Outlaw at all though. In fact, Capsules was created to _specifically to define **shared ownership**_; you have primary control of your Outlaw, but other programs and people can control it too. The amount of control you have over an asset, versus the control that other people / programs have over your asset can be thought of as a "contract"; not a legal one in the sense you'll get sued and the government will seize your Outlaw, but a contract as computer-code, where your ownership rights are enfroced as immutable, shared programs running on a globally distributed permissionless computer network! You know, that thing we like to call `Sui`.

Note also that all our metadata is on-chain, and our Outlaw occupies about 900 bytes of on-chain storage. You can inspect your outlaw on devnet using the Sui explorer:

[https://explorer.sui.io/object/0x5d7934cd96ad89586bdeb6d33589c863de23981f?network=devnet]()

### Step 5: Read Outlaw

Okay next lets read the metadata of our Outlaw from the perspective of an off-chain application. Imagine we're a wallet or an explorer that wants to display our Outlaw-object to users; how do we query the blockchain? First, we assume that the client-application already has our Outlaw's Object-ID; Sui is a _biggggg_ place, so finding our Outlaw's Object-ID in the first place is an **indexing** problem, and something we'll look into later.

For now, let's introduce Sui **view functions**; these are done using `DevInspect` transactions, which are read-only transactions submitted to the same Sui Fullnodes we use to write to the blockchain. Again, these transactions do not modify state, and do not cost any gas to execute. View-functions are writtenin Move, and are stored immutably on the Sui blockchain, right alongside the rest of our module code, meaning all of our reading / writing logic is written in the same language, stored in the same place, and accessible with the same API; easy-peasy! I bet other blockchains wish they were this cool!

Because view functions are just Move code, we can write our own arbitrary, complex custom queries and run them on-chain! Our Outlaw module we deployed actually contains _no_ view function of its own, because Capsule's Metadata program is sufficiently generalized that it can query _any_ object metadata directly, without having to write our own custom queries in our Outlaw module, and without the client-application needing any specialized knowledge about what an Outlaw is.

Okay, let's run our query:

### View functions are currently broken; will redo this section when they're fixed again

**TO DO:** The Sui CLI does not currently support devInspect queries yet; use a direct curl command instead for now!

**TO DO:** UIDs cannot be constructed directly as arguments yet, meaning we still need to use our own custom view function within Outlaw sky! Lame.

We might need this to make it work as well: https://github.com/MystenLabs/sui/pull/7720

**Ooops** Sui RPC _used_ to support convenient devInspect calls, but now it no longer does; it now requires us to serialize our entire transaction prior. We use the RPC to first serialize our transaction, and then we submit our serialized transaction. If this seems kind of dumb and roundabout; that's because it is.

`export SUI_RPC_HOST='https://fullnode.devnet.sui.io:443'`

```
curl --location --request POST $SUI_RPC_HOST \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "sui_batchTransaction",
    "params": [
        "0xbb81965d327c51d42d1081e5d81909652f05a675",
        [
            {
                "moveCallRequestParams": {
                    "packageObjectId": "0x973a1fc252d367ac06c66ee01c23cc8c713c5491",
                    "module": "outlaw_sky",
                    "function": "view_all",
                    "typeArguments": [],
                    "arguments": ["0x5d7934cd96ad89586bdeb6d33589c863de23981f", "0xa26589d8c49a8f0ee5f70ad34025198b008ea493"]
                }
            }
        ],
        "0x6b816d23fc88eca23c8923b9a8460c2481891c51",
        2000,
        "DevInspect"
    ]
}'
```

This gives us back our transaction serialized as base64:

`AQECNM9Ln7Sl3OAqfKAD8sxhndDJxU4Kb3V0bGF3X3NreQh2aWV3X2FsbAACAQEg3vdy66OCN7Mx+qKHARPwWrvtQg8EAAAAAAAAAQBr0K9n5WNNyjCPRnS553C7Kx8LxuYDAAAAAAAAIJ8YEJOB+5tYkjBCphC3OwVHuBxxS+/mJ5iAuOnHdVUtu4GWXTJ8UdQtEIHl2BkJZS8FpnVrgW0j/IjsojyJI7moRgwkgYkcUdMDAAAAAAAAILSrnRGoe6Jjai+zuFJjz3cf4jwFUp9kumbajATXmnyoAQAAAAAAAADQBwAAAAAAAA==`

```
curl --location --request POST $SUI_RPC_HOST \
--header 'Content-Type: application/json' \
--data-raw '{
"jsonrpc": "2.0",
"id": 1,
"method": "sui_devInspectTransaction",
"params": [
    "0xbb81965d327c51d42d1081e5d81909652f05a675",
"AQECNM9Ln7Sl3OAqfKAD8sxhndDJxU4Kb3V0bGF3X3NreQh2aWV3X2FsbAACAQEg3vdy66OCN7Mx+qKHARPwWrvtQg8EAAAAAAAAAQBr0K9n5WNNyjCPRnS553C7Kx8LxuYDAAAAAAAAIJ8YEJOB+5tYkjBCphC3OwVHuBxxS+/mJ5iAuOnHdVUtu4GWXTJ8UdQtEIHl2BkJZS8FpnVrgW0j/IjsojyJI7moRgwkgYkcUdMDAAAAAAAAILSrnRGoe6Jjai+zuFJjz3cf4jwFUp9kumbajATXmnyoAQAAAAAAAADQBwAAAAAAAA=="
]
}' | json_pp
```

```
curl --location --request POST $SUI_RPC_HOST \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "sui_devInspectTransaction",
    "params": [
        "0xbb81965d327c51d42d1081e5d81909652f05a675",
        "AQECNM9Ln7Sl3OAqfKAD8sxhndDJxU4Kb3V0bGF3X3NreQh2aWV3X2FsbAACAQEg3vdy66OCN7Mx+qKHARPwWrvtQg8EAAAAAAAAAQBr0K9n5WNNyjCPRnS553C7Kx8LxuYDAAAAAAAAIJ8YEJOB+5tYkjBCphC3OwVHuBxxS+/mJ5iAuOnHdVUtu4GWXTJ8UdQtEIHl2BkJZS8FpnVrgW0j/IjsojyJI7moRgwkgYkcUdMDAAAAAAAAILSrnRGoe6Jjai+zuFJjz3cf4jwFUp9kumbajATXmnyoAQAAAAAAAADQBwAAAAAAAA==",
        0,
        0,
        0
    ]
}' | json_pp
```

```
curl --location --request POST $SUI_RPC_HOST \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "sui_devInspectTransaction",
    "params": [
        {}
        "0xbb81965d327c51d42d1081e5d81909652f05a675",
        "AQECNM9Ln7Sl3OAqfKAD8sxhndDJxU4Kb3V0bGF3X3NreQh2aWV3X2FsbAACAQEg3vdy66OCN7Mx+qKHARPwWrvtQg8EAAAAAAAAAQBr0K9n5WNNyjCPRnS553C7Kx8LxuYDAAAAAAAAIJ8YEJOB+5tYkjBCphC3OwVHuBxxS+/mJ5iAuOnHdVUtu4GWXTJ8UdQtEIHl2BkJZS8FpnVrgW0j/IjsojyJI7moRgwkgYkcUdMDAAAAAAAAILSrnRGoe6Jjai+zuFJjz3cf4jwFUp9kumbajATXmnyoAQAAAAAAAADQBwAAAAAAAA=="
    ]
}' | json_pp
```

**To Do:** DevInspect transactions are currently useless and do not work. Will update this section when possible.

### Step 6: Ovewrite-Updates

Let's change our Outlaw by adding more attributes! Here's are our new set of attributes:

`[ Background, White, Face, Wholesome, Outfit, Paradise Green, Clothes, Summer Shirt, Head, Beanie (blackout), Eyewear, Melrose Bricks, 1/1, None ]`

After serializing these, they turn out to be:

`sui client call --package 0x973a1fc252d367ac06c66ee01c23cc8c713c5491 --module outlaw_sky --function update --args 0x5d7934cd96ad89586bdeb6d33589c863de23981f "[ \"attributes\" ]" "[ [ 7, 10, 66, 97, 99, 107, 103, 114, 111, 117, 110, 100, 5, 87, 104, 105, 116, 101, 4, 70, 97, 99, 101, 9, 87, 104, 111, 108, 101, 115, 111, 109, 101, 6, 79, 117, 116, 102, 105, 116, 14, 80, 97, 114, 97, 100, 105, 115, 101, 32, 71, 114, 101, 101, 110, 7, 67, 108, 111, 116, 104, 101, 115, 12, 83, 117, 109, 109, 101, 114, 32, 83, 104, 105, 114, 116, 4, 72, 101, 97, 100, 17, 66, 101, 97, 110, 105, 101, 32, 40, 98, 108, 97, 99, 107, 111, 117, 116, 41, 7, 69, 121, 101, 119, 101, 97, 114, 14, 77, 101, 108, 114, 111, 115, 101, 32, 66, 114, 105, 99, 107, 115, 3, 49, 47, 49, 4, 78, 111, 110, 101] ]" 0xa26589d8c49a8f0ee5f70ad34025198b008ea493 --gas-budget 3000`

Notice that took a little longer? But still <6 seconds to edit. That's because our Outlaw is a _shared object_, which means it needs to go through full consensus, which takes longer than it does for _owned objects_.

Also note that all of the metadata describing out Outlaw, the name, image url, and attributes, amount to only about 180 bytes of data. That's not bad!

### Step 7: Atomic Updates

---

### Step 8: Destroy Outlaw

Our Outlaw object itself is a shared object, meaning we cannot destroy it right now, although Sui will eventually support destroying shared objects! However we _can_ delete the metadata of our Outlaw! So let's do that:

`sui client call --package 0x973a1fc252d367ac06c66ee01c23cc8c713c5491 --module outlaw_sky --function delete_all --args 0xa26589d8c49a8f0ee5f70ad34025198b008ea493 --gas-budget 9000`

And viola! All our metadata is gone; we can now create completely new metadata with a completely new schema if we want.

## Sui Typescript SDK

-

### Addresses Used:

Transaction signer = 0xed2c39b73e055240323cf806a7d8fe46ced1cabb
Metadata package = 0xeb85c3c33d99df932bcb26ef59c963cae67fb1d1
Outlaw Sky package = 0x973a1fc252d367ac06c66ee01c23cc8c713c5491
Publish Receipt Object = 0x13e39a18ee4182b3e02ce1dfd724a1567404699a
Outlaw Object = 0x5d7934cd96ad89586bdeb6d33589c863de23981f
Schema Object = 0xa26589d8c49a8f0ee5f70ad34025198b008ea493
`Type<Outlaw> Object` = 0x5386dc0ffd2303a06529bff548c6b77a8fd49cfa
