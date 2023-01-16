This is walkthrough on how to create assets on Sui using Capsule-tools. It assumes you have the [Sui CLI installed][https://docs.sui.io/build/install], a keypair generated, enough gas from the faucet to submit transactions, and that devnet is currently broken again.

### Step 1: Publish Your Module

`sui client publish --gas-budget 3000`

You'll get the UID of publish-receipt, which looks something like:

> Created Objects:
> ID: 0xeb946f63986f20318253be4da8966667a524695d , Owner: Immutable
> ID: 0x2fdd358c069400c61b3134a7e1feb092c230d8d6 , Owner: Account Address ( 0xbb81965d327c51d42d1081e5d81909652f05a675 )

The first address is the package-id you just deployed, and the second is the publish-receipt.

### Step 2: Create a Metadata Schema (optional)

Schemas are immutable root-level Sui objects that enforce (key-name, type) pairings, making (de)serialization of on-chain metadata possible. Normally you'd use some industry-standard schema, such as `0x814fb9ce94aa24af648ccc07c587ca73c4ce9a81`, but if you want to deploy your own custom schema, try the following command:

`sui client call --package 0x4f2801f232f4cd689e7d1791b74e7fad1dfa068c --module schema --function create --args "[ \"name\", \"image\", \"power level\" ]" "[ \"ascii\", \"ascii\", \"u64\" ]" [false,false,false] --gas-budget 1000`

This defines 3 keys; `name`, `image`, and `power level`, which must be ascii-strings followed by a u64. They are all required fields.

### Step 3: Create Type Metadata (optional)

Our module is going to create a new type of object; an Outlaw. Our outlaw type will be `<package-id>::outlaw_sky::Outlaw`; all Move types consist of the declaring package-id, module-name, and struct-name. Sometimes rather than defining metadata _per object_ we want to define metadata _per type_; suppose we have a field in our schema whose value doesn't vary per object, like `creator`; if we create 10,000 outlaws, it would be rather redundant to duplicate the _same_ creator value 10,000 times (once per object); what a waste of space! I mean who do you think we are here, _Metaplex_??? No! We can define our Type-Metadata once, and then this acts as all of our Outlaw's 'default' Metadata.

All we need is our publish receipt, run this:

`sui client call --package 0x4f2801f232f4cd689e7d1791b74e7fad1dfa068c --module type --function define --type-args 0xeb946f63986f20318253be4da8966667a524695d::outlaw_sky::Outlaw --args 0x2fdd358c069400c61b3134a7e1feb092c230d8d6 0x814fb9ce94aa24af648ccc07c587ca73c4ce9a81 "[ \"Kyrie\", \"https://pilots-cdn.taiyopilots.com/pre/images/enforcers.png\", \"3\" ]" --gas-budget 3000`

### Step 4: Create Outlaw

Let's call into the `create` function that's part of the module we deployed:

`sui client call --package 0xeb946f63986f20318253be4da8966667a524695d --module outlaw_sky --function create --args 0x814fb9ce94aa24af648ccc07c587ca73c4ce9a81 "[ \"Kyrie\", \"https://pilots-cdn.taiyopilots.com/pre/images/enforcers.png\", \"3\" ]" --gas-budget 3000`

We now have an outlaw with the metadata we've defined!

### Step 5: Read Outlaw

-

### Step 6: Edit Outlaw

-

### Step 7: Destroy Outlaw

-
