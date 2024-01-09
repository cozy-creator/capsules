This package extends sui::coin with new functionality by taking `Balance<T>` and locking it inside of a shared object called an `Coin23`.

This gives creators more control over their fungible assets:

- Creator can withdraw balances
- Creator can freeze balances
- Creator can disable transfers
- Creator can restrict DeFi to a white-listed set
- Creator can impose transfer-fees

This is intended to be used by Circle for USDC and for in-game economies. Note that we cannot enforce the above rules for balances that are exported from `Coin23` into a coin-object or some other balance-storing object.

We also adds new abilities for merchants:

- Recurring charges (rebill)
- Hold funds

---

*** TO DO: ***

- creation and destruction of balances with `Supply<T>` (grant and burn functions)
- broadcast memo-events on transfer
- add pay and send pay-memo to coin23 convenience function
- consider making payments idempotent (when you access the other person's account to deposit, you also register a reference-id)
- convenience entry functions
- figure out abstract display
- Integrate claim and offer for NFT marketplaces
- Consider being able to send to phone numbers, email addresses, and having single-use claim codes for funds
- Add events so that merchants can know when their rebill-authority has been revoked
- Allow import of coin using treasury cap to claim registration
- Is registration of a new coin already implemented? Create an example of registering a new coin type
- Add the ability to cancel item offers
- Add convenience function to easily create item offers (entry)
- allow turning on and off creator control flags (currency can be more restrictive)
- implement example of a game spending a player's non-transferable currency
- payment memo needs to be implemented better
- create organization spending balance delegation example


*** Notes ***

We did not add any market-confounding mechanisms, hence even without any export_auths, someone could create a secondary marketplace that swaps coin-type-A for coin-type-B on some marketplace, simply by using direct-transfer. If this is undesirable, we could add a market-confounder.

*** Scope: ***
- Balance can be frozen by the coin-creator
- Rebilling
- Funded holds
- Fees on send
- Non-transferable

*** Out of scope: ***
- Privacy at some point later (confidential + anonymous transfers)
- Consumer protection (guardian system)
- Creator protection (infinite money glitch)
- Crank (Chronos), fan-out account (hydra on Solana), joint-accounts
- Market-confounding (fixed price sale)
- Inbound and outbound funnels (pay day loans)
