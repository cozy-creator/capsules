// Sui's Ownership System For Shared Objects
//
// For owned-objects, Sui defines the owner at the system-level, hence there is no need for us to
// store an owner here. Owned-objects have 'referential authority'; if you can obtain a reference to an
// object, you own it. This is the basis of Sui Ownership.
// Furthermore, we do not add a transfer-authority because transferring authority is also handled by
// Sui's system-level transfer rules.
// All this function does is store a struct tag so you can assert later who the native module is and
// what the type the object is just from its UID.

module ownership::ownership {
    use std::option::{Self, Option};
    use std::vector;

    use sui::object::{Self, UID, ID};
    use sui::dynamic_field;

    use sui_utils::encode;
    use sui_utils::typed_id::{Self, TypedID};
    use sui_utils::struct_tag::{Self, StructTag};
    
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::permissions::MANAGER;

    // error enums
    const ENO_MODULE_AUTHORITY: u64 = 0;
    const ENO_OWNER_AUTHORITY: u64 = 1;
    const ENO_TRANSFER_AUTHORITY: u64 = 2;
    const EUID_DOES_NOT_BELONG_TO_OBJECT: u64 = 3;
    const EOBJECT_NOT_INITIALIZED: u64 = 4;
    const EOBJECT_ALREADY_INITIALIZED: u64 = 5;
    const EOWNER_ALREADY_INITIALIZED: u64 = 6;

    // Is it safe to have 'copy' and 'drop' here? Probably
    // Do we need to store 'type'? Probably
    // TO DO: it might be possible to initialize an owner, transfer auth, then drop both of them, and
    // then have the module re-initialize with a new owner and transfer auth. This isn't desired behavior;
    // see if it's possible.
    struct Ownership has store, copy, drop {
        owner: Option<address>,
        transfer_auth: vector<address>,
        type: StructTag
    }

    // Dynamic field key for storing the Ownership struct
    struct Key has store, copy, drop { }

    // Permission type allowing access to the UID
    struct UID_MUT {} // Used to access UID_MUT
    struct TRANSFER {} // Used to perform a transfer (change the owner)
    struct MIGRATE {} // Used to change (migrate) the transfer-authority

    // ======= Initialize Ownership =======
    // The caller needs to supply a 'typed-id' here because `as_owned_object(&mut object.id, &object)`
    // gives the error `Invalid borrow of variable, it is still being mutably borrowed by another reference`.
    // This allows the caller to prove that the UID belongs to the specified object-type, allowing us to
    // figure out what module produced this object.

    public fun as_owned_object<T: key>(
        uid: &mut UID,
        typed_id: TypedID<T>,
        auth: &TxAuthority
    ) {
        assert_valid_initialization(uid, typed_id, auth);

        let ownership = Ownership {
            owner: option::none(),
            transfer_auth: vector::empty(),
            type: struct_tag::get<T>()
        };

        dynamic_field::add(uid, Key { }, ownership);
    }
    
    // Convenience function
    public fun as_shared_object<T: key, Transfer>(
        uid: &mut UID,
        typed_id: TypedID<T>,
        owner: address,
        auth: &TxAuthority
    ) {
        let transfer = encode::type_into_address<Transfer>();
        as_shared_object_(uid, typed_id, owner, vector[transfer], auth);
    }

    public fun as_shared_object_<T: key>(
        uid: &mut UID,
        typed_id: TypedID<T>,
        owner: address,
        transfer_auth: vector<address>,
        auth: &TxAuthority
    ) {
        assert_valid_initialization(uid, typed_id, auth);

        let ownership = Ownership {
            owner: option::some(owner),
            transfer_auth,
            type: struct_tag::get<T>()
        };

        dynamic_field::add(uid, Key { }, ownership);
    }

    // ======= Authority Checkers =======

    public fun assert_valid_initialization<T: key>(uid: &UID, typed_id: TypedID<T>, auth: &TxAuthority) {
        assert!(!is_initialized(uid), EOBJECT_ALREADY_INITIALIZED);
        assert!(object::uid_to_inner(uid) == typed_id::to_id(typed_id), EUID_DOES_NOT_BELONG_TO_OBJECT);
        assert!(tx_authority::has_package_permission<T, MANAGER>(auth), ENO_MODULE_AUTHORITY);
    }

    public fun is_initialized(uid: &UID): bool {
        dynamic_field::exists_(uid, Key { })
    }

    // Defaults to `true` if the owner does not exist
    public fun has_owner_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let owner = get_owner(uid);
            if (option::is_none(&owner)) true
            else {
                let owner = option::destroy_some(owner);
                tx_authority::has_permission<Permission>(owner, auth)
            }
        }
    }

    // If this is initialized, module authority exists and is always the native module (the module
    // declaring the object's type). I.e., the hash-address corresponding to `0x599::my_module::Witness`.
    public fun has_package_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let package_id = option::destroy_some(get_package_authority(uid));
            tx_authority::has_package_permission_<Permission>(package_id, auth)
        }
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun has_transfer_permission<Permission>(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let transfer = get_transfer_authority(uid);
            if (vector::is_empty(&transfer)) false
            else {
                tx_authority::has_k_or_more_agents_with_permission<Permission>(transfer, 1, auth)
            }
        }
    }

    // Checks all instances of why an agent needs mutable access to a UID
    public fun validate_uid_mut(uid: &UID, auth: &TxAuthority): bool {
        if (has_owner_permission<UID_MUT>(uid, auth)) { return true }; // Owner type added
        if (has_package_permission<UID_MUT>(uid, auth)) { return true }; // Witness type added
        if (has_transfer_permission<UID_MUT>(uid, auth)) { return true }; // Transfer type added

        false
    }

    // ========== Getter Functions =========

    public fun get_owner(uid: &UID): Option<address> {
        if (!is_initialized(uid)) { return option::none() };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        ownership.owner
    }

    public fun get_package_authority(uid: &UID): Option<ID> {
        if (!is_initialized(uid)) { return option::none() };
        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        option::some(struct_tag::package_id(&ownership.type))
    }

    // public fun get_module_authority(uid: &UID): Option<address> {
    //     if (!is_initialized(uid)) { return option::none() };

    //     let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
    //     let addr = tx_authority::witness_addr_from_struct_tag(&ownership.type);
    //     option::some(addr)
    // }

    public fun get_transfer_authority(uid: &UID): vector<address> {
        if (!is_initialized(uid)) { return vector::empty() };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        ownership.transfer_auth
    }

    public fun get_type(uid: &UID): Option<StructTag> {
        if (!is_initialized(uid)) { return option::none() };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        option::some(ownership.type)
    }

    // ======== Transfer Function ========
    // Used by the assigned transfer module

    // Requires transfer authority. Does NOT require ownership or module authority.
    // This means the specified transfer authority can change ownership unilaterally, without the current
    // owner being the sender of the transaction.
    // This is useful for marketplaces, reclaimers, and collateral-repossession.
    public fun transfer(uid: &mut UID, new_owner: Option<address>, auth: &TxAuthority) {
        assert!(has_transfer_permission<TRANSFER>(uid, auth), ENO_TRANSFER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.owner = new_owner;
    }

    // Requires module, owner, and transfer authorities all to sign off on this migration
    // This is a difficult operation to do!
    // TO DO: create an example implementation of this. We might choose to ignore module authority, or perhaps
    // allow for unilateral changes by the module-authority.
    public fun migrate_transfer_auth(uid: &mut UID, new_transfer_auths: vector<address>, auth: &TxAuthority) {
        assert!(has_package_permission<MIGRATE>(uid, auth), ENO_OWNER_AUTHORITY);
        assert!(has_owner_permission<MIGRATE>(uid, auth), ENO_OWNER_AUTHORITY);
        assert!(has_transfer_permission<MIGRATE>(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.transfer_auth = new_transfer_auths;
    }

    // This ejects all transfer authority, and it can never be set again, meaning the owner can never be
    // changed again.
    public fun make_owner_immutable(uid: &mut UID, auth: &TxAuthority) {
        migrate_transfer_auth(uid, vector::empty(), auth);
    }
}

#[test_only]
module ownership::ownership_tests {
    use sui::object::{Self, UID};
    use sui::test_scenario::{Self, Scenario};
    use sui::transfer;

    use sui_utils::typed_id;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    struct Witness has drop {}

    struct TestObject has key {
        id: UID
    }

    const ADDR1: address = @0xBACE;
    const ADDR2: address = @0xFAAE;

    const ENOT_OWNER: u64 = 0;

    public fun uid(object: &TestObject): &UID {
        &object.id
    }

    public fun uid_mut(object: &mut TestObject, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&object.id, auth), ENOT_OWNER);

        &mut object.id
    }

    fun create_test_object(scenario: &mut Scenario, owner: vector<address>, transfer_auth: vector<address>) {
        let ctx = test_scenario::ctx(scenario);
        let object = TestObject { 
            id: object::new(ctx) 
        };

        let typed_id = typed_id::new(&object);
        let auth = tx_authority::begin_with_type(&Witness {});

        ownership::as_shared_object_(&mut object.id, typed_id, owner, transfer_auth, &auth);
        transfer::share_object(object)
    }

    #[test]
    fun test_transfer_ownership() {
        let scenario = test_scenario::begin(ADDR1);
        
        {
            let owner = vector[ADDR1];
            create_test_object(&mut scenario, owner, owner);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let uid = uid_mut(&mut object, &auth);
            let new_owner = vector[ADDR2];
            
            ownership::transfer(uid, new_owner, &auth);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ownership::ownership::ENO_TRANSFER_AUTHORITY)]
    fun test_unauthorized_transfer_ownership_failure() {
        let scenario = test_scenario::begin(ADDR1);

        {
            let owner = vector[ADDR1];
            create_test_object(&mut scenario, owner, owner);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let uid = uid_mut(&mut object, &auth);

            test_scenario::next_tx(&mut scenario, ADDR2);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                let new_owner = vector[ADDR2];

                ownership::transfer(uid, new_owner, &auth);
            };

            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_migrate_transfer_auth() {
        let scenario = test_scenario::begin(ADDR1);
        
        {
            let owner = vector[ADDR1];
            create_test_object(&mut scenario, owner, owner);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type<Witness>(&Witness {}, &tx_authority::begin(ctx));
            let uid = uid_mut(&mut object, &auth);
            let new_owner = vector[ADDR2];
            
            ownership::migrate_transfer_auth(uid, new_owner, &auth);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ownership::ownership::ENO_MODULE_AUTHORITY)]
    fun test_migrate_transfer_module_auth_failue() {
        let scenario = test_scenario::begin(ADDR1);
        
        {
            let owner = vector[ADDR1];
            create_test_object(&mut scenario, owner, owner);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let uid = uid_mut(&mut object, &auth);
            let new_owner = vector[ADDR2];
            
            ownership::migrate_transfer_auth(uid, new_owner, &auth);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ownership::ownership::ENO_OWNER_AUTHORITY)]
    fun test_migrate_transfer_owner_auth_failue() {
        let scenario = test_scenario::begin(ADDR1);
        
        {
            let owner = vector[ADDR1];
            create_test_object(&mut scenario, owner, owner);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let uid = uid_mut(&mut object, &auth);

            {
                let new_owner = vector[ADDR2];
                let auth = tx_authority::begin_with_type(&Witness {});
                ownership::migrate_transfer_auth(uid, new_owner, &auth);
            };

            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ownership::ownership::ENO_TRANSFER_AUTHORITY)]
    fun test_migrate_transfer_transfer_auth_failue() {
        let scenario = test_scenario::begin(ADDR1);
        
        {
            let owner = vector[ADDR1];
            let transfer_auth = vector[ADDR2];
            create_test_object(&mut scenario, owner, transfer_auth);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let uid = uid_mut(&mut object, &auth);

            {
                let new_owner = vector[ADDR2];
                let auth = tx_authority::add_type(&Witness {}, &auth);
                ownership::migrate_transfer_auth(uid, new_owner, &auth);
            };

            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_immutable_ownership() {
        let scenario = test_scenario::begin(ADDR1);
        
        {
            let owner = vector[ADDR1];
            create_test_object(&mut scenario, owner, owner);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type<Witness>(&Witness {}, &tx_authority::begin(ctx));
            let uid = uid_mut(&mut object, &auth);
            
            ownership::make_owner_immutable(uid, &auth);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ownership::ownership::ENO_TRANSFER_AUTHORITY)]
    fun test_immutable_ownership_transfer_failue() {
        let scenario = test_scenario::begin(ADDR1);
        
        {
            let owner = vector[ADDR1];
            create_test_object(&mut scenario, owner, owner);
            test_scenario::next_tx(&mut scenario, ADDR1);
        };

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type<Witness>(&Witness {}, &tx_authority::begin(ctx));
            let uid = uid_mut(&mut object, &auth);
            let new_owner = vector[ADDR2];
            
            ownership::make_owner_immutable(uid, &auth);
            ownership::transfer(uid, new_owner, &auth);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }
}

    // ======= Delegation System =======
    // Coming... eventually!

    // ownership::add_owner_delegation<Witness>(&mut display.id, &auth);

    // public fun add_owner_delegation<T>(uid: &mut UID, auth: &TxAuthority) {
    //     assert!(tx_authority::is_authorized_by_type<T>(auth), ENO_MODULE_AUTHORITY);

    //     let from = tx_authority::type_into_address<T>();

    //     dynamic_field2::set(uid, DelegationKey { from }, Delegation { 
    //         from,
    //         to: get_owner(uid)
    //     });
    // }

    // public fun add_delegation() {

    // }

    // public fun remove_delegation() {

    // }