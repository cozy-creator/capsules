module account::account {
    
    // Permission constants (for delegation)
    const INSERT: u8 = 0;
    const BORROW_MUT: u8 = 1;
    const EJECT: u8 = 2;
    const EXTEND: u8 = 3;

    // Error enums
    const ENO_OWNER_PERMISSION: u64 = 0;

    // To save gas, we use separate UIDs to store objects and owner-addresses, rather than key-addresses
    // That way accounts can still be extendable + safe + efficient
    struct GameAccount has key {
        id: UID,
        objects: UID,
        owners: UID
    }

    // Module authority
    struct Witness has drop {}

    struct Key has store, copy, drop { id: ID } // -> object
    struct KeyOwner has store, copy drop { id: ID } // -> owner address

    // ======== Create / Destroy Accounts ========

    public entry fun create<Owner>(ctx: &mut TxContext) {
        let owner = tx_context::type_into_address<Owner>();
        create_(owner, ctx);
    }

    public entry fun create_(owner: address, ctx: &mut TxContext) {
        let account = GameAccount { 
            id: object::new(ctx),
            objects: object::new(ctx),
            owners: object::new(ctx)
        };

        let typed_id = typed_id::new(&account);
        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<SimpleTransfer>(&mut account.id, typed_id, owner, &auth);

        transfer::share_object(account);
    }

    // ======== Primary API ======== 

    // Requires insert authority. We could make this permissionless, which wouldn't cause any harm other than
    // lots of spam.
    public fun insert<T: store>(account: &mut GameAccount, object: T, owner: address, auth: &TxAuthority) {
        assert!(delegation::has_permission<Witness>(&account.id, INSERT, auth), ENO_OWNER_PERMISSION);
        // assert!(tx_authority::is_signed_by(account.owner, auth), ENOT_OWNER);

        let id = object::id(&object);
        dynamic_field::add(&mut account.owners, id, owner);
        dynamic_field::add(&mut account.objects, id, object);
    }

    public fun eject<T: store>(account: &mut GameAccount, id: ID, auth: &TxAuthority): (T, address) {
        assert!(delegation::has_permission<Witness>(&account.id, EJECT, auth), ENO_OWNER_PERMISSION);

        (
            dynamic_field::remove<ID, T>(&mut account.objects, id), 
            dynamic_field::remove<ID, address>(&mut account.owners, id)
        )
    }

    // Requires eject authority from account-1, and insert authority from account-2
    public fun transfer<T: store>(from: &mut GameAccount, into &mut GameAccount, id: ID, auth: &TxAuthority) {
        let (obj, owner) = eject(from, id, auth);
        insert(into, obj, owner, auth);
    }

    // Requires no authority
    public fun borrow<T: store>(account: &mut GameAccount, id: ID): &T {
        dynamic_field::borrow<ID, T>(&account.objects, id)
    }

    public fun borrow_mut<T: store>(account: &mut GameAccount, id: ID, auth: &TxAuthority): &mut T {
        assert!(delegation::has_owner_permission<Witness>(&account.id, BORROW_MUT, auth), ENO_OWNER_PERMISSION);

        dynamic_field::borrow_mut<ID, T>(&mut account.objects, id)
    }

            let (object, auth) = account::borrow_mut_<Skin>(account, id, ctx);

    public fun borrow_mut_<T: store>(account: &mut GameAccount, id: ID, auth: &TxAuthority): (&mut T, auth) {
        assert!(delegation::has_owner_permission<Witness>(&account.id, BORROW_MUT, auth), ENO_OWNER_PERMISSION);
        let auth = tx_authority::add_to_scope(auth);

        dynamic_field::borrow_mut<ID, T>(&mut account.objects, id)
    }

    // ======== Getter Functions ======== 

    // Aborts if the ID doesn't exist
    public fun owner(account: &GameAccount, id: ID): address {
        *dynamic_field::borrow<ID, address>(&account.owners, id)
    }

    public fun exists(account: &GameAccount, id: ID): bool {
        dynamic_field::exists_(&account.objects, id)
    }

    public fun exists_with_type<T: store>(account: &GameAccount, id: ID): bool {
        dynamic_field::exists_with_type<ID, T>(&account.objects, id)
    }

    // ======== Extend Pattern ========

    public fun uid(account: &GameAccount): &UID {
        &account.id
    }

    public fun uid_mut(account: &mut GameAccount, auth: &TxAuthority): &mut UID {
        assert!(delegation::has_owner_permission<Witness>(&account.id, EXTEND, auth), ENO_OWNER_PERMISSION);

        &mut account.id
    }

    // View function ??? 
}

// These are convenience functions to make everything easier
module account::script_tx {
    use ownership::delegation;

    use account::account;

    public fun claim_delegation<T>(account: &GameAccount, ctx: &TxContext): TxAuthority {
        let uid = account::uid(account);
        delegation::claim<T>(uid, ctx)
    }

    public fun claim_delegation_(account: &GameAccount, principal: address, ctx: &TxContext): TxAuthority {
        let uid = account::uid(account);
        delegation::claim_(uid, principal, ctx)
    }
}