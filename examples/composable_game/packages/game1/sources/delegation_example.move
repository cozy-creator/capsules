module composable_game::rbac_example {
    use sui::object::{Self, UID};

    use ownership::rbac;
    use ownership::ownership;

    use attach::data;

    struct MyObject has key {
        id: UID
    }

    struct Witness has drop {}

    // agent = 0x1234 can now write to any_object[Witness].data namespace
    // We have given this keypair the ability to write to our data-namespace
    // This is useful if 0x1234 is a server of ours; it can now access the attach::data APIs directly
    // without having to go through whatever APIs we have exposed with our Witness {}
    //
    // We could also make agent = type_into_address<ForeignWitness>
    // In that case any transaction signed by ForeignWitness can access our data-namespace
    //
    // We could also make agent = object-id
    // In that case, any transaction that can get a ref to object-id can access our data-namespace
    public fun delegate_to_our_agent(agent: address, ctx: &mut TxContext) {
        // Change this to publish-receipt instead
        let store = rbac::create(Witness {}, tx_context::sender(ctx), ctx);
        let auth = tx_authority::begin(ctx);
        rbac::add_store<data::Key>(&mut store, agent, &auth);
        rbac::return_and_share(store);
    }

    // Now this other address (whatever it is; keypair, type, or object-id) can borrow_mut our object's UID
    public fun delegate_to_other_owner(uid: &mut UID, agent: address) {
        rbac::add_uid<ownership::Key>(uid, agent, &auth);
    }

    public fun uid_mut(object: &mut MyObject, auth: &TxAuthority): &mut UID {
        assert!(rbac::has_permission_from_owner<ownership::Key>(uid, auth), ENO_OWNER_PERMISSION);

        &mut object.id
    }
}

// Scenario 1: Overwatch gives authority to one of its own servers to write on it behalf
// Scenario 2: Overwatch writes a custom API that allows Mario Party to write to its save-data
// Scenario 3: Overwatch gives Mario Party authority to write to its own save-data arbitrarily

// Scenario 4: Mario Party asks the owner of an Overwatch-native item to provision a Mario Party namespace
// Scenario 5: Mario Party gives authority to one of its own servers
// Scenario 6: Mario Party writes to its own namespace
// Scenario 7: Mario Party removes authority from a server