module composable_game::exe2 {
    use attach::data::{Self, SET};

    // error enums
    const ENO_PERMISSION: u64 = 0;

    // permission enums
    const ALL: u8 = 0;

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

    // For this to work, (1) Witness must have delegated permission to the caller, and (2) the caller
    // must have added that to TxAuthority previously
    // It is the MODULE that grants authority to the caller (agent) to modify its UID!
    // Note that the first Witness is just referring to this module, while the second Witness is referring
    // to it as an authority.
    public fun skin_uid_mut_shared(skin: &mut Skin, auth: &TxAuthority): &mut UID {
        assert!(tx_authority::is_allowed<Witness, Witness>(ALL, auth), ENO_PERMISSION);

        &mut skin.id
    }

    // In this iteration, we allow the UID to be accessed by anyone the owner wants to allow
    // This makes less sense, since this tx must be either signed by the owner, or the owner must
    // have explicitly created a permission for the signer of this transaction for this specific function,
    // and then stored that delegated permission either somewhere else, where the agent already claimed it,
    // or stored it within this UID.
    public fun skin_uid_mut_shared2(skin: &mut Skin, auth: &TxAuthority): &mut UID {
        assert!(delegation::is_allowed_by_owner<Witness>(skin.id, ALL, auth), ENO_OWNER_PERMISSION);

        &mut skin.id
    }

    // For owned objects; because getting a reference to it alone signifies ownership
    public fun skin_uid_mut(skin: &mut Skin): &mut UID {
        &mut skin.id
    }
}

// These are examples of script transactions
module composable_game::script_transactions {
    use account;
    use attach::data::{Self, SET};
    use composable_game::exe2::{Self, Witness as EXE2};

    // A 4 step process
    // For this to work, the sender must have (1) BORROW_MUT permission in that account, and (2) UID_MUT for the resulting object.
    public entry fun example_modify_data(
        account: &mut GameAccount,
        id: ID,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        // There must be an RBAC stored in account for principal + our keypair for this to work
        // We need the BORROW_MUT permission from account::account, and SET permission from attach::data
        // Note that we are using exe2::Witness because that type is the owner of our account
        let auth = account::script_tx::claim_delegation<EXE2>(account, ctx);
        let object = account::borrow_mut_<Skin>(account, id, &auth);
        let uid = exe2::skin_uid_mut(object);
        data::deserialize_and_set<EXE2>(uid, data, fields, &auth);
    }

    // 
    public entry fun example_add_delegation(account: &mut GameAccount, addr: address, ctx: &mut TxContext) {
        let auth = account::script_tx::claim_delegation<EXE2>(account, ctx);
        // EXE2 (module witness) is the owner, so this will work because we got its authority above
        let uid = account::uid_mut(account, &auth);

        delegation::add_permission<account::Witness>(uid, addr, INSERT, &auth);
        delegation::add_permission<data::Witness>(uid, addr, SET, &auth);
    }
}