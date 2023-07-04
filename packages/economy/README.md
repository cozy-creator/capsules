This package extends sui::coin with new functionality, giving creators more control over their fungible assets:

- Freezing balances
- Rebilling
- Custom Coin transfer rules, such as non-transferable
- Tranfer fees
- Preventing coins from being resold on secondary

This is intended to be used by Circle for USDC and for in-game economies. This works by taking a `Balance<T>` and locking it inside of a shared object called an `Account`.

Note that we cannot enforce the above rules for balances that are exported from `Account` into a coin-object or some other balance-storing object.