// 0: full owner (all permissions)
// 1: edit data
// 2: borrow private inventory
// 3: edit-mut inventory (including deposit and withdraw)
// 4: use transfer module (selling, collateralization)
// Transfer has to wipe all delegations

module ownership::delegation {
    // This is a key that stores the RBAC for the specified address.
    struct Delegation has store, copy, drop { from: address } // -> RBAC vector

    // Key for obtaining the list of all delegate addresses, so we can enumerate them
    struct DelegationList has store, copy, drop {} // -> vector<address>
}