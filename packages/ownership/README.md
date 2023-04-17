### Instructions

The most common use of this library in your module will be to check authority. These are the best most common ones to use:

```
    tx_authority::is_signed_by(addr: address, auth: &TxAuthority): bool
```

This checks to see if the specified address is an agent inside of the current transaction authority. Delegations do not count.

```
    tx_authority::is_allowed<T, Principal>(function: u8, auth: &TxAuthority): bool
```

This checks to see if the principal is either an agent inside of the current transaction authority, or if there is a delegation that has been added that allows for the calling the specified function on behalf of the principal.
`T` is merely used to specify a type from the module of the function that we're calling; there is no easy way to specify functions individually. Similarly `function` is a u8 specified by the module (0 - 15) that is a subset of functions in that module.

```
    delegation::is_allowed_by_owner<T>(uid: &UID, function: u8, auth: &TxAuthority): bool
```

This checks to see if the owner is an agent in this transaction, or if the owner has added a delegation to the current authority, or if there is a stored delegation waiting for one of our agents inside of the UID. These delegations will be imported into the `TxAuthority` for this function-call only. Essentially, the UID's owner acts as the principal.
The function-arguments are the same as above, with the addition of UID, which is where the owner and extra delegations are fetched from.

**Future:** once Sui adds the ability for multiple signers per transaction, this will have to be refactored.

**Future:** we might be able to add addresses directly using signatures? I.e., submit some bytes + signature
from some pubkey, so we treat that as a validation and then add that pubkey to our list of addresses

**TO DO:**

- Consummable authority? Peel off authority after being checked. Similar to a witness being consumed perhaps?
- Layered authority? As in pass auth from func1 -> func2 -> func3, but func1's authority only
  goes down to func2, not func3
- Proxy Authority: instead of directly owning an object, you set its ownership to be proxied in a different object. If Obj-A points to ownership of Obj-B, then you own Obj-A if and only if you own Obj-B.
- Tests: we definitely need tests

**Capability pattern:** you have the ability to acquire a reference (mutable or immutable) to:

- Type
- Object-id
- Custom: the object has the cap's id number stored in a field OR the cap has the object's id number stored in a field

**Witness pattern:** you can acquire an object by value. It is consumed after use and not returned; as a result it must have 'drop', meaning it cannot have ID, meaning Witnesses are all fungible; you bind authority to their type, not to an object-id. Some custom checking behavior could be built as well.

**Authority generally:**

- Keypair (or multisig)
- Ref to Object-ID
- Ref to Type
- Type by Value
- Custom
- Proxy
- (You can also store, but this is related to dyamic_field / Sui-System-Layer access)

### Important

TxAuthority uses the convention that modules can sign for themselves using a struct named `Witness`, i.e., 0x899::my_module::Witness.

Modules should always define a Witness struct, like:

`struct Witness has drop { }`

Carefully guard its access, as it represents the authority of the module at runtime.

### Default

If the ownership fields are undefined, this is how they will resolve:

- Module: false (no permission granted)
- Transfer: false (no permission granted)
- Owner: true (all permissions granted)

### Default Addresses

- Module: set address to @0x1 to make all module-checks pass
- Transfer: set address to @0x0 to make all transfer-checks fail (I might remove this later; we could just migrate the transfer module to a null-transfer module).
- Owner: set address to @0x1 to make all ownership-checks pass

### Exernal Understanding of On-Chain Contract's Rights and Stipulations

For clarity, we should add metadata that specifies what the module and transfer-authority is on an object, otherwise you just have an address, and unless you cross-reference some database it's not clear what that means.

Additionally, owners should be able to easily see who has rights to edit their object's metadata (if anyone).
