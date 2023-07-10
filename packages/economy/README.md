This package extends sui::coin with new functionality by taking `Balance<T>` and locking it inside of a shared object called an `Account`.

This gives creators more control over their fungible assets:

- Creator can withdraw balances
- Creator can freeze balances
- Creator can disable transfers
- Creator can restrict DeFi to a white-listed set
- Creator can impose transfer-fees

This is intended to be used by Circle for USDC and for in-game economies. Note that we cannot enforce the above rules for balances that are exported from `Account` into a coin-object or some other balance-storing object.

We also adds new abilities for merchants:

- Recurring charges (rebill)
- Hold funds

---

*** TO DO: ***

- creation and destruction of balances with `Supply<T>`
- convenience entry functions
- figure out abstract display
- offers for NFT marketplaces
- broadcast memo-events on transfer
- Separate out into individual modules (potentially) instead of just 'Account'
- Consider changing the name to Coin23
- Consider being able to send to phone numbers, email addresses, and having single-use claim codes for funds


*** Notes ***

We did not add any market-confounding mechanisms, hence even without any export_auths, someone could create a secondary marketplace that swaps coin-type-A for coin-type-B on some marketplace, simply by using direct-transfer. If this is undesirable, we could add a market-confounder.
