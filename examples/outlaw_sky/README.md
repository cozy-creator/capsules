This is a walkthrough demonstrating how to create assets on Sui using Capsule-tools. We demonstrate two methods: (1) [using the Sui CLI](#sui-cli), and (2) [using the Sui Typescript SDK](#sui-typescript-sdk). The CLi is useful for developers performing their own ad-hoc operations, while the Typescript SDK is useful for webapps and Node.js servers.

---

## Sui CLI

This assumes you have the [Sui CLI installed](https://docs.sui.io/build/install), a keypair generated to submit transactions from, some gas from the faucet to pay for transactions, and that Sui devnet currently isn't broken (lol).

### Step 1: Publish Your Module

Inside of the ./package folder, run the command:

`sui client publish --gas-budget 3000`

This will return two UIDs, looking something like:

> Created Objects:
> ID: 0xeb946f63986f20318253be4da8966667a524695d , Owner: Immutable
> ID: 0x2fdd358c069400c61b3134a7e1feb092c230d8d6 , Owner: Account Address ( 0xbb81965d327c51d42d1081e5d81909652f05a675 )

The first ID is the package-id you just deployed, which is an immutable object, and the second ID is the package's publish-receipt, which is owned by whatever keypair you used to deploy the package.

### Step 2: Create a Metadata Schema (optional)

Schemas are immutable root-level owned objects used to enforce `(field-name, type)` pairings, making (de)serialization of on-chain metadata possible. Because schema-objects are immutable, they can never change or be deleted; if you want to change something about a schema, you'll have to create a new schema object. Normally you'd select some standard schema, such as `0x6bd0af67e5634dca308f4674b9e770bb2b1f0bc6 `, but if you want to write and deploy your own custom schema, use the following command:

`sui client call --package 0xa7b5d34fd01c30201076521b6feb2b4b5e0c7532 --module schema --function define --args "[ [\"name\", \"string\"], [ \"description\", \"Option<string>\" ], [ \"image\", \"string\" ], [ \"power_level\", \"u64\" ] ]" --gas-budget 2000`

This defines 4 fields; `name`, `description`, `image`, and `power level`, which are are three utf8 strings followed by a u64. Only `description` is optional, while the other 3 fields are required.

### Step 3: Create Type Metadata (optional)

Our module is going to create a new type of object; an Outlaw. Our Outlaw type will be `<package-id>::outlaw_sky::Outlaw`; all Move types consist of the declaring package-id, module-name, and struct-name. Sometimes rather than defining metadata _per object_ we want to define metadata _per type_; suppose we have a field in our schema whose value doesn't vary per object, like `description`; if we create 10,000 outlaws, it would be rather redundant to duplicate the _same_ description value 10,000 times (once per object); what a waste of space! I mean who do you think we are here, _Metaplex_??? No! We can define our type metadata once, and then this acts as all of our Outlaw's 'default' metadata.

All we need is our publish receipt! But first, we have to define our default arguments:

`[ "Outlaw", "These are demo Outlaws created by CapsuleCreator for our tutorial", "https://pbs.twimg.com/profile_images/1569727324081328128/7sUnJvRg_400x400.jpg", 199u64 ]`

Unfortunately, if we supply this as an argument to the Sui CLI, it won't know how to serialize this hetergenous array as an array of arrays of bytes (`vector<vector<u8>>`). At some point the Sui CLI will hopefully support this, but for now we have a simple app that serializes your arguments for you. Putting the above arguments arguments in yields the serialized `vector<vector<u8>>` format:

`[ [79, 117, 116, 108, 97, 119], [84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], [104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [199, 0, 0, 0, 0, 0, 0, 0] ]`

which we then put into our command as the third argument:

`sui client call --package 0xa7b5d34fd01c30201076521b6feb2b4b5e0c7532 --module type --function define --type-args 0x311fba79f29e8ce8c5fb755a00e322aa813e456a::outlaw_sky::Outlaw --args 0x10682ea4abe4481ceb837fc5526e4a29e7989ae0 0x6bd0af67e5634dca308f4674b9e770bb2b1f0bc6  "[ [79, 117, 116, 108, 97, 119], [84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], [104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [199, 0, 0, 0, 0, 0, 0, 0] ]" --gas-budget 8000`

The first argument is our publish receipt; do you remember the object we got back in step-1? That publish receipt proves that we are the ones who published the package, and hence we have special priviliges to define type metadata for the structs we defined in our package (we wouldn't want random people on the internet defining metadata for our own objects!). Also note that type metadata is a **singleton object**; there will only ever be _one_ `metadata::type::Type<<package-id>::outlaw_sky::Outlaw>` in existence. If you try to run the command above again, it will fail! That's because metadata::type leaves a record on your package receipt recording that you used it to create your type metadata object. The next time you try to use that publish receipt again, metadata::type will see the leftover record and abort!

The second argument is our schema object again that we created above. Note that here we will be using this schema for _both_ our type-metadata as we well as our outlaws (see below); but this needn't be the case! They can both be wildly different schemas. However, it's recommend you always use _compatible_ schemas in case you use two different schemas. Two schemas are "compatible" if they both define the same type, i.e., if our schema defines the field `name` to be of type `string` or `Option<string>` these two schemes are considered compatible, but if another schema defines `name` as the type `vector<string>`, then this schema is not compatible. Two schemas are compatible _if and only if_ all of their overlapping field-names are of the same type / `Option<<type>`.

Now for the fun of it, let's try editing our type metadata! Try the following command:

`sui client call --package 0xa7b5d34fd01c30201076521b6feb2b4b5e0c7532 --module type --function overwrite --type-args 0x311fba79f29e8ce8c5fb755a00e322aa813e456a::outlaw_sky::Outlaw --args 0x0f95b36764fa9618d114d4856f9b72cdab1a967f "[ \"description\", \"image\", \"power_level\" ]" "[ [84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], [104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [199, 0, 0, 0, 0, 0, 0, 0] ]" 0x6bd0af67e5634dca308f4674b9e770bb2b1f0bc6 true --gas-budget 2000`

Notice how fast and cheap that was? Our transaction was completed in <2 seconds, and cost a measly 893 nanoSUI to write 150 bytes; on mainnet that'll likely be around 90,000 nanoSUI, which works out to 0.00009 SUI, which is equivalent to 5k edit-transactions for $1. Oof.

**TO DO: Insert Link to argument-serializer app**

### Step 4: Create Outlaw

Now let's call into the `create` function that we deployed in Step-1. This will create our first Outlaw! Remember that for the CLI, we have to serialize our data-argument as bytes, so this:

`[ "Kyrie", "", "https://pbs.twimg.com/profile_images/1569727324081328128/7sUnJvRg_400x400.jpg", 65536u64 ]`

becomes this:

`sui client call --package 0x311fba79f29e8ce8c5fb755a00e322aa813e456a --module outlaw_sky --function create --args 0x6bd0af67e5634dca308f4674b9e770bb2b1f0bc6 "[ [75, 121, 114, 105, 101], [], [104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], [0, 0, 1, 0, 0, 0, 0, 0] ]" --gas-budget 9000`

We'll be returned a result that looks like this:

> ----- Transaction Effects ----
> Status : Success
> Created Objects:
>
> - ID: 0x1ca3c86fed5ad637143f15a81d2cc31a9ddb4144 , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
> - ID: 0x3137d76eaeefe7e396d1315eb47356aa7c271ce1 , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
> - ID: 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 , Owner: Shared
> - ID: 0x51673c014cf020f331982096c68c7e29a4e958d4 , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
> - ID: 0x68e194c2373109a10bb36f569080647f64e71b4f , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
> - ID: 0x85af2fe01dfaa623eeeb34a5388de932efe5675c , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
> - ID: 0x952260e682f3ec20944d75518cd6b46fffa5c611 , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
> - ID: 0xa153e1aba646baa0e4c210d5b2e7c7de63aa42c3 , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
> - ID: 0xf41403d7706f796b2b9fba8d6ac825bc48196b28 , Owner: Object ID: ( 0x3fcd6d18b440acc67d2a40afc40357b29681fb51 )
>   Mutated Objects:
> - ID: 0x34b29facfdc4f34e97219d2a02e648b0f30b43de , Owner: Account Address ( 0xbb81965d327c51d42d1081e5d81909652f05a675 )

What is this? For Sui, every dynamic field we add is its own 'object'; as you can see, all of these objects are owned by one object: `0x3fcd6d18b440acc67d2a40afc40357b29681fb51`; that's our Outlaw! And all of the other objects are its dynamic fields.

Notice that our Outlaw is owned by `Shared`. This means it's not owned by us _directly_ within Sui, but rather, it's a shared-object other people and programs can call into. For owned objects, only we can construct transactions that use them, but for shared objects, other people can use them as transaction inputs too! That doesn't mean we have _no_ control over our Outlaw at all though. In fact, Capsules was created to _specifically to define **shared ownership**_; you have primary control of your Outlaw, but other programs and people can control it too. The amount of control you have over an asset, versus the control that other people / programs have over your asset can be thought of as a "contract"; not a legal one in the sense you'll get sued and the government will seize your Outlaw, but a contract as computer-code, where your ownership rights are enfroced as immutable, shared programs running on a globally distributed permissionless computer network! You know, that thing we like to call `Sui`.

Note also that all our metadata is on-chain, and our Outlaw occupies about 900 bytes of on-chain storage.

### Step 5: Read Outlaw

Okay next lets read data from Outlaw, from the perspective of an off-chain application call into Sui to learn about this Outlaw. (We call these **client applications** to distinguish them from **on chain programs**).

-

### Step 6: Edit Outlaw

-

### Step 7: Destroy Outlaw

stuff

---

## Sui Typescript SDK

-
