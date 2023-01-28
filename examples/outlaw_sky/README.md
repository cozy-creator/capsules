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

Schemas are immutable root-level Sui objects that enforce <key-name, type> pairings, making (de)serialization of on-chain metadata possible. Because schema-objects are immutable, they can never change or be deleted; if you want to change a schema, you'd deploy a new scheam of your own. Normally you'd select some standard schema, such as `0x37cef7c69de4b1cea22f1ef445940432d6968ac6`, but if you want to write and deploy your own custom schema, try the following command:

`sui client call --package 0xc58218250eec94ee3241ac999dd564a6e267f107 --module schema --function define --args "[ \"name\", \"description\", \"image\", \"power_level\" ]" "[ \"ascii\", \"Option<ascii>\", \"ascii\", \"u64\" ]" [false,true,false,false] --gas-budget 1000`

This defines 3 keys (fields); `name`, `image`, and `power level`, which are two ascii-strings followed by a u64. They are not optional fields (meaning they're required).

### Step 3: Create Type Metadata (optional)

Our module is going to create a new type of object; an Outlaw. Our outlaw type will be `<package-id>::outlaw_sky::Outlaw`; all Move types consist of the declaring package-id, module-name, and struct-name. Sometimes rather than defining metadata _per object_ we want to define metadata _per type_; suppose we have a field in our schema whose value doesn't vary per object, like `creator`; if we create 10,000 outlaws, it would be rather redundant to duplicate the _same_ creator value 10,000 times (once per object); what a waste of space! I mean who do you think we are here, _Metaplex_??? No! We can define our Type-Metadata once, and then this acts as all of our Outlaw's 'default' Metadata.

All we need is our publish receipt, run this:

`sui client call --package 0x4f2801f232f4cd689e7d1791b74e7fad1dfa068c --module type --function define --type-args 0xeb946f63986f20318253be4da8966667a524695d::outlaw_sky::Outlaw --args 0x2fdd358c069400c61b3134a7e1feb092c230d8d6 0x814fb9ce94aa24af648ccc07c587ca73c4ce9a81 "[ \"Kyrie\", \"https://pilots-cdn.taiyopilots.com/pre/images/enforcers.png\", \"3\" ]" --gas-budget 3000`

### Step 4: Create Outlaw

Let's call into the `create` function that's part of the module we deployed:

`sui client call --package 0x2f1c9c3610d58f793e936821b797b9b63d9e602a --module outlaw_sky --function create --args 0xbf4a8f90818aad78cc5a10bc1f4f6d0067e2cca7 "[ \"Kyrie\", \"https://pilots-cdn.taiyopilots.com/pre/images/enforcers.png\", \"3\" ]" --gas-budget 3000`

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
