With ownership system:
`sui client call --package 0x3a02eaccaba0cf9f552dabdaf8a82210baff022f --module glb_asset --function create --gas-budget 6000`
cost: 5,859

Without ownership:
`sui client call --package 0xadbdc206997dd49f21899d51d06412acc80bf017 --module glb_asset --function create --gas-budget 6000`
cost: 671

Without ownership, but struct tag:
`sui client call --package 0x6a47951a158e0ed1b32d94e4c236b87aa8b15487 --module glb_asset --function create --gas-budget 6000`
cost: 2,462
(generating a single struct-tag cost 1,791 nanoSUI!)
(What did the other 3,397?)

without ownership, but tx_authority and typed-id
`sui client call --package 0xb46f46130468d6c48465a11435ce91d59af66534 --module glb_asset --function create --gas-budget 6000`
cost: 806
(typed_id and tx_authority only add 135 gas; no biggie)

creating a fake-ownership, but not attaching it. Also with tx_authority and typed_id. No struct-tag is used
`sui client call --package 0xf771565d9dcf40c95ee34c996f47411451e410fc --module glb_asset --function create --gas-budget 6000`
cost: 811
(What? packing an empty struct was basically free apparently)

Same as above, except we add it to a dynamic field
`sui client call --package 0x60be4a07895b0ef770b029ad471b7db5bc15db5b --module glb_asset --function create --gas-budget 6000`
cost: 863
(storing was basically free)

Same as above, but with 3 ownership assertions
`sui client call --package 0xd8ed980eba151398aa760b3bc2696d412ea5668a --module glb_asset --function create --gas-budget 6000`
cost: 2,429
(holy crap, these 3 assertions cost 1,566!)

Same as above, but just with the is_signed_by_module assertion
`sui client call --package 0xe76db564a4a1ae0ffead50f3ea604d6ccf3a139b --module glb_asset --function create --gas-budget 6000`
cost: 2,407
(that single assertion is costing 1,544)
1,544 x2 + 1,791 = 4879 just for those 3 operations
The remaining 980 are accounted for by literally everything else

Same as above, but with newly revised sui_utils (removed ascii, add utf8)
`sui client call --package 0x8e46b2e094084df50aa63dda7d51caea142de20f --module glb_asset --function create --gas-budget 6000`
cost: 1,168

Same as the original (first) call, but with more efficient:
`sui client call --package 0xd7d903fe3ce8db1f0d943339f3f93a10231ddbbf --module glb_asset --function create --gas-budget 6000`
cost: 1,981
We went from 5,859 to 1,981; a 66% reduction in gas cost!

New command:
`sui client call --package 0x1159c0f222353153c4c75592c73d3dd86806920c --module glb_asset --function create --gas-budget 3000`
cost: 2,390
