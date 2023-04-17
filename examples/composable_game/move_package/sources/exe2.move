module composable_game::exe2 {
    use attach::data::{Self, SET};

    struct Skin has key, store {
        id: UID
    }

    struct Character has key, store {
        id: UID
    }

    struct Currency has key, store {
        id: UID,
        balance: u64
    }

    struct Witness has drop {}

    // Our `Witness` must be the owner of this Account, or have INSERT permission from the owner for this to work
    // This works identically for foreign and native owned accounts
    public entry fun create(account: &mut Account, owner: address, ctx: &mut TxContext) {
        let skin = Skin { id: object::new(ctx) };
        let auth = tx_authority::begin_with_type(&Witness {});

        account::insert(account, skin, owner, &auth);
    }

    public fun retrieve<T: store>(account: &mut GameAccount, id: ID): T {
        let auth = tx_authority::begin_with_type(&Witness {});

        account::eject(account, id, &auth)
    }

    // For shared objects (??? - how does this work?)
    // The problem is that we need to allow module + transfer the ability to use it
    public fun skin_uid_mut_shared(skin: &mut Skin, auth: &TxAuthority): &mut UID {
        assert!(delegation::has_module_permission<Witness>(EXTEND, auth), ENO_OWNER_PERMISSION);

        &mut skin.id
    }

    // For owned objects; because getting a reference to it signifies ownership
    public fun skin_uid_mut(skin: &mut Skin): &mut UID {
        &mut skin.id
    }
}

// These are examples of script transactions
module composable_game::script_transactions {
    use account::account::{Self, INSERT};
    use attach::data::{Self, SET};
    use composable_game::exe2;

    // A 4 step process
    // For this to work, the sender must have (1) BORROW_MUT permission in that account, and (2) UID_MUT for the resulting object.
    public entry fun example_modify_data(
        account: &mut GameAccount,
        id: ID,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        // This makes sure the sender (ctx) is on the list of approved accounts to do this
        let auth = account::claim_delegations(account, ctx);
        let object = account::borrow_mut_<Skin>(account, id, &auth);
        let uid = skin_uid_mut(object);
        data::deserialize_and_set<Witness>(uid, data, fields, &auth);
    }

    // 
    public entry fun example_add_delegation(account: &mut GameAccount, addr: address, ctx: &mut TxContext) {
        let auth = tx_context::claim_delegation(account, ctx);
        let uid = account::uid_mut(account, &auth);

        delegation::add_permission<account::Witness>(uid, addr, INSERT, &auth);
        delegation::add_permission<data::Witness>(uid, addr, SET, &auth);
    }
}