![Move_VM](./static/move_vm_factory.png 'Sui Move Factory')

### Terminology:

- **Witness Pattern:** restricting a function to only be callable by a certain other module; any module that can produce the witness object.

- **Extension Pattern:** allowing a foreign-module to attach fields to your object by passing it a mutable reference to your object.id. These can be protected by using a local Key {}.

- **Plugin:** a module that operates on objects that it's attached to, rather on its own objects.

- **Cartridge Pattern:** a meta-asset that wraps any other asset, providing a set of rules regarding ownership and transfer of ownership.

- **Capability Pattern (Authority Object):** an object with Key to which ownership is tied. Used as a replacement for tx_context::sender(ctx) (the address of the sender of the transaction).

- ???: pass it down

### TO DO:

- Authority vector
- Quantity
- Save Data
- Inventory
- Authority Passer

### Default Behavior:

- If no module_authority is set, every call is invalid

- If no transfer_authority is set, every call is invalid

- If no owner is set, every call is valid
