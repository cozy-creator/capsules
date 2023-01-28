This is a walkthrough demonstrating how to create assets on Sui using Capsule-tools. We demonstrate two methods: (1) [using the Sui CLI](#sui-cli), and (2) [using the Sui Typescript SDK](#sui-typescript-sdk). The CLi is useful for developers performing their own ad-hoc operations, while the Typescript SDK is useful for webapps and Node.js servers.

---

## Sui CLI

This assumes you have the [Sui CLI installed](https://docs.sui.io/build/install), a keypair generated to submit transactions from, some gas from the faucet to pay for transactions, and that the devnet currently isn't broken (lol).

### Step 1: Publish Your Module

Inside of the ./package folder, run the command:

`sui client publish --gas-budget 3000`

This will return two UIDs, looking something like:

> Created Objects:
> ID: 0xeb946f63986f20318253be4da8966667a524695d , Owner: Immutable
> ID: 0x2fdd358c069400c61b3134a7e1feb092c230d8d6 , Owner: Account Address ( 0xbb81965d327c51d42d1081e5d81909652f05a675 )

The first ID is the package-id you just deployed, and the second ID is the package's publish-receipt.

### Step 2: Select or Create a Metadata Schema

Schemas are immutable root-level Sui objects that enforce <key-name, type> pairings, making (de)serialization of on-chain metadata possible. Because schema-objects are immutable, they can never change or be deleted; if you want to change a schema, you'd deploy a new scheam of your own. Normally you'd select some standard schema, such as `0xed6154cf3cee249872897048342f87bd9eb0b13d`, but if you want to write and deploy your own custom schema, try the following command:

`sui client call --package 0x62e1355a57ff4f07434166e519e5e71e13e9d999 --module schema --function define --args "[ [\"name\", \"string\"], [ \"description\", \"Option<string>\" ], [ \"image\", \"string\" ], [ \"power_level\", \"u64\" ] ]" --gas-budget 2000`

This defines 34 keys (fields); `name`, `description`, `image`, and `power level`, which are are three utf8 strings followed by a u64. Only `description` is optional, while the rest are not (meaning they're required).

### Step 3: Create Type Metadata (optional)

Our module is going to create a new type of object; an Outlaw. Our outlaw type will be `<package-id>::outlaw_sky::Outlaw`; all Move types consist of the declaring package-id, module-name, and struct-name. Sometimes rather than defining metadata _per object_ we want to define metadata _per type_; suppose we have a field in our schema whose value doesn't vary per object, like `creator`; if we create 10,000 outlaws, it would be rather redundant to duplicate the _same_ creator value 10,000 times (once per object); what a waste of space! I mean who do you think we are here, _Metaplex_??? No! We can define our Type-Metadata once, and then this acts as all of our Outlaw's 'default' Metadata.

All we need is our publish receipt, run this:

`sui client call --package 0x62e1355a57ff4f07434166e519e5e71e13e9d999 --module type --function define --type-args 0xad10acb641b8d2581f105c4e6dad061470518468::outlaw_sky::Outlaw --args 0x237bb79378aef2c477638f0000ee8e0c32b762d0 0xed6154cf3cee249872897048342f87bd9eb0b13d "[ \"Kyrie\", \"great description\", \"https://pilots-cdn.taiyopilots.com/pre/images/enforcers.png\", \"1999\" ]" --gas-budget 3000`

### Step 4: Create Outlaw

Let's call into the `create` function that's part of the module we deployed:

`sui client call --package 0xad10acb641b8d2581f105c4e6dad061470518468 --module outlaw_sky --function create --args 0xed6154cf3cee249872897048342f87bd9eb0b13d "[ \"Kyrie\", \"description here\", \"https://pilots-cdn.taiyopilots.com/pre/images/enforcers.png\", \"[0, 1, 2, 3, 4, 5, 6, 7]\" ]" --gas-budget 10000`

We now have an outlaw with the metadata we've defined!

### Step 5: Read Outlaw

-

### Step 6: Edit Outlaw

-

### Step 7: Destroy Outlaw

stuff

---

## Sui Typescript SDK

-
