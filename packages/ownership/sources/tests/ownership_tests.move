#[test_only]
module ownership::ownership_tests {
    use std::option;

    use sui::object::{Self, UID};
    use sui::test_scenario::{Self, Scenario};

    use sui_utils::encode;
    use sui_utils::typed_id;
    use sui_utils::struct_tag;

    use ownership::ownership;
    use ownership::permission::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};

    struct Witness has drop {}

    struct TestObject has key {
        id: UID
    }

    const SENDER: address = @0xFADE;
    const TF_ADDR: address = @0xFACE;

    const ENOT_OWNER: u64 = 0;

    public fun uid(object: &TestObject): &UID {
        &object.id
    }

    public fun uid_mut(object: &mut TestObject, auth: &TxAuthority): &mut UID {
        assert!(ownership::has_owner_permission<ADMIN>(&object.id, auth), ENOT_OWNER);
        &mut object.id
    }

    fun create_test_shared_object(owner: address, tf_auth: address, scenario: &mut Scenario): TestObject {
        let ctx = test_scenario::ctx(scenario);
        let object = TestObject { id: object::new(ctx) };
        let typed_id = typed_id::new(&object);

        let auth = tx_authority::begin_with_package_witness(Witness {});
        ownership::as_shared_object_(&mut object.id, typed_id, owner, tf_auth, &auth);

        object
    }

    fun create_test_owned_object(scenario: &mut Scenario): TestObject {
        let ctx = test_scenario::ctx(scenario);
        let object = TestObject { id: object::new(ctx) };
        let typed_id = typed_id::new(&object);

        let auth = tx_authority::begin_with_package_witness(Witness {});
        ownership::as_owned_object(&mut object.id, typed_id, &auth);

        object
    }

    fun delete_test_object(object: TestObject) {
        let TestObject { id } = object;
        object::delete(id)
    }

    #[test]
    fun create_owned_object() {
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_owned_object(&mut scenario);
        
        assert!(option::is_none(&ownership::get_owner(&object.id)), 0);
        assert!(option::is_none(&ownership::get_transfer_authority(&object.id)), 0);
        assert!(ownership::get_type(&object.id) == option::some(struct_tag::get<TestObject>()), 0);
        assert!(ownership::get_package_authority(&object.id) == option::some(encode::package_id<TestObject>()), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun create_shared_object() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        
        assert!(ownership::get_owner(&object.id) == option::some(SENDER), 0);
        assert!(ownership::get_transfer_authority(&object.id) == option::some(tf_auth), 0);
        assert!(ownership::get_type(&object.id) == option::some(struct_tag::get<TestObject>()), 0);
        assert!(ownership::get_package_authority(&object.id) == option::some(encode::package_id<TestObject>()), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::ownership::EOBJECT_ALREADY_INITIALIZED)]
    fun create_shared_object_already_initialized() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        
        let typed_id = typed_id::new(&object);
        let auth = tx_authority::begin_with_package_witness(Witness {});
        ownership::as_shared_object_(&mut object.id, typed_id, SENDER, tf_auth, &auth);

        delete_test_object(object);
        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::ownership::EUID_DOES_NOT_BELONG_TO_OBJECT)]
    fun create_shared_object_invalid_uid() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        
        let object = TestObject { id: object::new(ctx) };
        let fake_object = TestObject { id: object::new(ctx) };
        let typed_id = typed_id::new(&fake_object);

        let auth = tx_authority::begin_with_package_witness(Witness {});
        ownership::as_shared_object_(&mut object.id, typed_id, SENDER, tf_auth, &auth);

        delete_test_object(object);
        delete_test_object(fake_object);
        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::ownership::ENO_MODULE_AUTHORITY)]
    fun create_shared_object_invalid_package_permission() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        
        let object = TestObject { id: object::new(ctx) };
        let typed_id = typed_id::new(&object);

        let auth = tx_authority::begin_with_type(&Witness {});
        ownership::as_shared_object_(&mut object.id, typed_id, SENDER, tf_auth, &auth);

        delete_test_object(object);
        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun has_owner_permission_non_initialized_object() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = TestObject { id: object::new(ctx) };
        
        let auth = tx_authority::begin(ctx);
        assert!(ownership::has_owner_permission<ADMIN>(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun has_owner_permission_owned_object() {
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_owned_object(&mut scenario);
        
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        assert!(ownership::has_owner_permission<ADMIN>(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun has_owner_permission_shared_object_invalid_auth() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        
        test_scenario::next_tx(&mut scenario, TF_ADDR);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            assert!(ownership::has_owner_permission<ADMIN>(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun has_package_permission_non_initialized_object() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = TestObject { id: object::new(ctx) };
        
        let auth = tx_authority::begin_with_package_witness(Witness {});
        assert!(ownership::has_package_permission<ADMIN>(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun has_package_permission_shared_object_invalid_auth() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        
        test_scenario::next_tx(&mut scenario, TF_ADDR);
        {
            let auth = tx_authority::begin_with_type(&Witness {});
            assert!(ownership::has_package_permission<ADMIN>(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun has_transfer_permission_non_initialized_object() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = TestObject { id: object::new(ctx) };
        
        let auth = tx_authority::begin(ctx);
        assert!(ownership::has_transfer_permission<ADMIN>(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun has_transfer_permission_shared_object() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        
        test_scenario::next_tx(&mut scenario, TF_ADDR);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            assert!(ownership::has_transfer_permission<ADMIN>(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun has_transfer_permission_shared_object_invalid_auth() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            assert!(ownership::has_transfer_permission<ADMIN>(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun has_transfer_permission_shared_object_empty_transfer_auth() {
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, @0x0, &mut scenario);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            assert!(ownership::has_transfer_permission<ADMIN>(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun validate_uid_mut_owner() {
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, @0x0, &mut scenario);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            assert!(ownership::validate_uid_mut(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun validate_uid_mut_package() {
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, @0x0, &mut scenario);
        
        let auth = tx_authority::begin_with_package_witness(Witness {});
        assert!(ownership::validate_uid_mut(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun validate_uid_mut_transfer() {
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, TF_ADDR, &mut scenario);
        
        test_scenario::next_tx(&mut scenario, TF_ADDR);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            assert!(ownership::validate_uid_mut(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::ownership_tests)]
    fun validate_uid_mut_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, TF_ADDR, &mut scenario);
        
        let auth = tx_authority::begin_with_type(&Witness {});
        assert!(ownership::validate_uid_mut(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun get_properties_non_initialized_object() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = TestObject { id: object::new(ctx) };
        
        assert!(option::is_none(&ownership::get_type(&object.id)), 0);
        assert!(option::is_none(&ownership::get_owner(&object.id)), 0);
        assert!(option::is_none(&ownership::get_transfer_authority(&object.id)), 0);
        assert!(option::is_none(&ownership::get_package_authority(&object.id)), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun transfer_shared_object() {
        let new_owner = @0xBABE;
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        
        test_scenario::next_tx(&mut scenario, TF_ADDR);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            ownership::transfer(&mut object.id, option::some(new_owner), &auth);
            assert!(option::some(new_owner) == ownership::get_owner(&object.id), 0);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            ownership::transfer(&mut object.id, option::none(), &auth);
            assert!(option::is_none(&ownership::get_owner(&object.id)), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::ownership::ENO_TRANSFER_AUTHORITY)]
    fun transfer_shared_object_invalid_auth() {
        let new_owner = @0xBABE;
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);

        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            ownership::transfer(&mut object.id, option::some(new_owner), &auth);
            assert!(option::some(new_owner) == ownership::get_owner(&object.id), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }


    #[test]
    fun migrate_transfer_auth() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        let new_tf_auth = option::some(@0xBABE);
        
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        test_scenario::next_tx(&mut scenario, TF_ADDR);
        let ctx = test_scenario::ctx(&mut scenario);
        auth = tx_authority::add_signer(ctx, &auth);
        auth = tx_authority::add_package_witness(Witness {}, &auth);

        ownership::migrate_transfer_auth(&mut object.id, new_tf_auth, &auth);
        assert!(ownership::get_transfer_authority(&object.id) == new_tf_auth, 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::ownership::ENO_OWNER_AUTHORITY)]
    fun migrate_transfer_auth_invalid_owner() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        let new_tf_auth = option::some(@0xBABE);
        
        test_scenario::next_tx(&mut scenario, TF_ADDR);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        auth = tx_authority::add_package_witness(Witness { }, &auth);

        ownership::migrate_transfer_auth(&mut object.id, new_tf_auth, &auth);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::ownership::ENO_MODULE_AUTHORITY)]
    fun migrate_transfer_auth_invalid_package() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        let new_tf_auth = option::some(@0xBABE);
        
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        test_scenario::next_tx(&mut scenario, TF_ADDR);
        let ctx = test_scenario::ctx(&mut scenario);
        auth = tx_authority::add_signer(ctx, &auth);

        ownership::migrate_transfer_auth(&mut object.id, new_tf_auth, &auth);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::ownership::ENO_TRANSFER_AUTHORITY)]
    fun migrate_transfer_auth_invalid_transfer() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);
        let new_tf_auth = option::some(@0xBABE);
        
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        auth = tx_authority::add_package_witness(Witness { }, &auth);

        ownership::migrate_transfer_auth(&mut object.id, new_tf_auth, &auth);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun make_owner_immutable() {
        let tf_auth = TF_ADDR;
        let scenario = test_scenario::begin(SENDER);
        let object = create_test_shared_object(SENDER, tf_auth, &mut scenario);

        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        test_scenario::next_tx(&mut scenario, TF_ADDR);
        let ctx = test_scenario::ctx(&mut scenario);
        auth = tx_authority::add_signer(ctx, &auth);
        auth = tx_authority::add_package_witness(Witness {}, &auth);

        ownership::make_owner_immutable(&mut object.id, &auth);
        // assert!(ownership::get_transfer_authority(&object.id) == vector::empty(), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }
}