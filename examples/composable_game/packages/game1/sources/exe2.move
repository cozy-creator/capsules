module composable_game::exe2 {
    use attach::data::{Self, SET};

    use game2::game2::Foreign

    // error enums
    const ENO_PERMISSION: u64 = 0;

    struct Skin has key, store {
        id: UID
    }

    struct Character has key, store {
        id: UID,
        name: String, // client-endpoint
        power_level: u64, // server-endpoint
    }

    struct Currency has key, store {
        id: UID,
        balance: u64
    }

    // Our module authority
    struct Witness has drop {}

    // One time witness
    struct EXE2 has drop {}

    // Permission types
    struct CREATE {}

    // This can be an entry function by accepting the `Namespace` and `TxContext` directly
    // Because it doesn't accept an auth, it cannot be used via permission
    public entry fun create_character_0(owner: address, namespace: &Namespace, ctx: &mut TxContext) {
        let _auth = namespace::assert_login<CREATE>(namespace, ctx);

        let character = Character { id: object::new(ctx) };

        transfer::share_object(character);
    }

    // This can be an entry function by accepting the `Namespace` and `TxContext` directly
    public fun create_character_1(owner: address, namespace: &Namespace, auth: &TxAuthority, ctx: &mut TxContext) {
        let _auth = namespace::assert_login_<CREATE>(namespace, auth);

        let character = Character { id: object::new(ctx) };

        transfer::share_object(character);
    }

    // In this instance, the character can only be created if (1) you are this module's namespace authority, or
    // (2) you have the the `CREATE` permission from this module's namespace.
    // In the first case, you will have: auth.agents contain this module's namespace
    // In the second case, you will have: auth.permissions contain Permission { `<thispackage>::exe2::CREATE` },
    // which will be in a VecMap with the key being this module's namespace
    public fun create_character_2(owner: address, auth: &TxAuthority, ctx: &mut TxContext) {
        assert!(namespace::has_permission<CREATE>(&auth), ENO_NAMESPACE_PERMISSION);

        let character = Character { id: object::new(ctx) };

        transfer::share_object(character);
    }

    // In this instance, the character can only be created if (1) you are the foreign module's namespace authority,
    // or (2) the `CREATE` permission has been granted to you by the foreign module's namespace
    // Essentially, this means that this game cannot produce its own characters! Only the foreign game can
    // do that.
    public fun create_character_3(owner: address, auth: &TxAuthority, ctx: &mut TxContext) {
        assert!(namespace::has_permission_<Foreign, CREATE>(&auth), ENO_NAMESPACE_PERMISSION);

        let character = Character { id: object::new(ctx) };

        transfer::share_object(character);
    }

    // ===== Examples =====
    fun init(otw: EXE2, ctx: &mut TxContext) {
        let owner = tx_context::sender(ctx);
        let receipt = publish_receipt::claim(&otw, ctx);
        let namespace = namespace::claim_(receipt, owner, ctx);

        namespace::return_and_share(namespace);
    }

    public entry fun claim_namespace_example(receipt: &mut PublishReceipt, ctx: &mut TxContext) {
        namespace::claim_package(receipt, ctx);
    }

    public entry fun add_full(namespace: &mut Namespace, ctx: &mut TxContext) {
        let auth = tx_authority::begin_with_type(&Witness {});

        namespace::add_full(namespace, auth, ctx);
    }

    public fun uid_mut(character: &mut Character, auth: &TxAuthority): &mut UID {
        assert!(ownership::has_permission(&character.id, &auth), ENO_NAMESPACE_PERMISSION);

        &mut character.id
    }


    // Suppose I want the Foreign game to be able to call create_character_1 or 2.
    // I could add all of their agents to roles inside of my own Namespace, but that's too direct.
    // Instead what we want to do is have a PROXY for ForeignNamespace; i.e., anyone with
    // Permission: (ForeignNamespace, <thispackage>::exe2::CREATE) can call create_character_1 or 2.
    // So the pattern would be: (1) ForeignNamespace adds a record, saying 0x123 (their agent) has permission
    // to <thispackage)>::exe2::CREATE (or ALL / ADMIN), and (2) Namespace adds a record saying that
    // ForeignNamespace has permission to <thispackage>::exe2::CREATE
    // We could do an inbox-permission; i.e., add our permission to the ForeignNamespace's object,
    // but that wouldn't work for create_character_1, because we are only bringing our Namespace object
    // into scope.
    // What makes more sense is to use an outbox permission; i.e., the agent calls in with an auth giving
    // them access to the foreign namespace, and then they use the foreign-namespace to lookup the permission.

    // What if I own a cartridge, and I want to allow someone else to use it?
    //
    // 
    // The external application is going to simply be like 'okay, your keypair is 0x123, and there is a
    // cartridge owned by 0x123, which is you, so you own it'. This is simple and can all be verified
    // off-chain (inside of MongoDB, for example).
    // But how do we do delegation? This process is not going to know that, yes, you are the 'owner',
    // but you granted permission to 0x456 to use your cartridge.
    // We could create a devInspect function that does this, but that makes it more complicated for the
    // client; it has to know what to call. And it might be hard to find the delegation record.
    //
    // The simplest pattern would be to have a rental transfer module that allows you to change the
    // owner while retaining a receipt-object that lets you take it back.
}

// =========== Old Code ===========

// Our `Witness` must be the owner of this Account, or have INSERT permission from the owner for this to work
    // This works identically for foreign and native owned accounts
    // public entry fun create(account: &mut Account, owner: address, ctx: &mut TxContext) {
    //     let skin = Skin { id: object::new(ctx) };
    //     let auth = tx_authority::begin_with_type(&Witness {});

    //     account::insert(account, skin, owner, &auth);
    // }

    // public fun retrieve<T: store>(account: &mut GameAccount, id: ID): T {
    //     let auth = tx_authority::begin_with_type(&Witness {});

    //     account::eject(account, id, &auth)
    // }

    // // For this to work, (1) Witness must have delegated permission to the caller, and (2) the caller
    // // must have added that to TxAuthority previously
    // // It is the MODULE that grants authority to the caller (agent) to modify its UID!
    // // Note that the first Witness is just referring to this module, while the second Witness is referring
    // // to it as an authority.
    // public fun skin_uid_mut_shared(skin: &mut Skin, auth: &TxAuthority): &mut UID {
    //     assert!(tx_authority::is_allowed<Witness, Witness>(ALL, auth), ENO_PERMISSION);

    //     &mut skin.id
    // }

    // // In this iteration, we allow the UID to be accessed by anyone the owner wants to allow
    // // This makes less sense, since this tx must be either signed by the owner, or the owner must
    // // have explicitly created a permission for the signer of this transaction for this specific function,
    // // and then stored that delegated permission either somewhere else, where the agent already claimed it,
    // // or stored it within this UID.
    // public fun skin_uid_mut_shared2(skin: &mut Skin, auth: &TxAuthority): &mut UID {
    //     assert!(delegation::is_allowed_by_owner<Witness>(skin.id, ALL, auth), ENO_OWNER_PERMISSION);

    //     &mut skin.id
    // }

    // // For owned objects; because getting a reference to it alone signifies ownership
    // public fun skin_uid_mut(skin: &mut Skin): &mut UID {
    //     &mut skin.id
    // }

// These are examples of script transactions
// module composable_game::script_transactions {
//     use account;
//     use attach::data::{Self, SET};
//     use composable_game::exe2::{Self, Witness as EXE2};

//     // A 4 step process
//     // For this to work, the sender must have (1) BORROW_MUT permission in that account, and (2) UID_MUT for the resulting object.
//     public entry fun example_modify_data(
//         account: &mut GameAccount,
//         id: ID,
//         data: vector<vector<u8>>,
//         fields: vector<vector<String>>,
//         ctx: &mut TxContext
//     ) {
//         // There must be an RBAC stored in account for principal + our keypair for this to work
//         // We need the BORROW_MUT permission from account::account, and SET permission from attach::data
//         // Note that we are using exe2::Witness because that type is the owner of our account
//         let auth = account::script_tx::claim_delegation<EXE2>(account, ctx);
//         let object = account::borrow_mut_<Skin>(account, id, &auth);
//         let uid = exe2::skin_uid_mut(object);
//         data::deserialize_and_set<EXE2>(uid, data, fields, &auth);
//     }

//     use foreign_game::foreign;

//     public entry fun edit_foreign_game_data(
//         foreign_game: &mut GameAccount,
//         account: &mut GameAccount,
//         id: ID,
//         data: vector<vector<u8>>,
//         fields: vector<vector<String>>,
//         ctx: &mut TxContext
//     ) {
//         let auth = account::claim_delegation<foreign::Witness>(foreign_game, ctx);
//     }

//     // 
//     public entry fun example_add_delegation(account: &mut GameAccount, addr: address, ctx: &mut TxContext) {
//         let auth = account::script_tx::claim_delegation<EXE2>(account, ctx);
//         // EXE2 (module witness) is the owner, so this will work because we got its authority above
//         let uid = account::uid_mut(account, &auth);

//         delegation::add_permission<account::Witness>(uid, addr, INSERT, &auth);
//         delegation::add_permission<data::Witness>(uid, addr, SET, &auth);
//     }
// }