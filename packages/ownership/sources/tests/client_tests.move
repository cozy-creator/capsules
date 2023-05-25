#[test_only]
module ownership::client_tests {
    use sui::test_scenario;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    use ownership::client;
    use ownership::ownership;
    use ownership::tx_authority;
    use ownership::permission::ADMIN;

    use sui_utils::encode;
    use sui_utils::typed_id;

    const SENDER: address = @0xFACE;
    const NAMESPACE: address = @0xDEED;

    struct Witness has drop {}

    struct TestObject has key {
        id: UID
    }

    fun create_test_object(owner: address, tf: address, ctx: &mut TxContext): TestObject {
        let object = TestObject { id: object::new(ctx) };
        let typed_id = typed_id::new(&object);
        let auth = tx_authority::begin_with_package_witness(Witness { });
        ownership::as_shared_object_(&mut object.id, typed_id, owner, tf, &auth);

        object
    }

    fun delete_test_object(object: TestObject) {
        let TestObject { id } = object;
        object::delete(id)
    }

    #[test]
    fun test_has_owner_permission() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        let auth = tx_authority::begin(ctx);
        assert!(client::has_owner_permission<ADMIN>(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_has_transfer_permission() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        let tf_auth = encode::type_into_address<Witness>();
        let object = create_test_object(SENDER, tf_auth, ctx);

        let auth = tx_authority::begin_with_type(&Witness {});
        assert!(client::has_transfer_permission<ADMIN>(&object.id, &auth), 0);

        let auth = tx_authority::begin_with_type(&Witness {});
        assert!(client::has_transfer_permission<ADMIN>(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_has_package_permission() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        let auth = tx_authority::begin_with_package_witness(Witness {});
        assert!(client::has_package_permission<ADMIN>(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_can_borrow_uid_mut() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        let tf_auth = encode::type_into_address<Witness>();
        let object = create_test_object(SENDER, tf_auth, ctx);

        let auth = tx_authority::begin(ctx);
        assert!(client::can_borrow_uid_mut(&object.id, &auth), 0);

        let auth = tx_authority::begin_with_type(&Witness {});
        assert!(client::can_borrow_uid_mut(&object.id, &auth), 0);

        let auth = tx_authority::begin_with_package_witness(Witness {});
        assert!(client::can_borrow_uid_mut(&object.id, &auth), 0);

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_provision_namespace() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        test_scenario::next_tx(&mut scenario, NAMESPACE);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            client::provision(&mut object.id, NAMESPACE, &auth);

            assert!(client::is_provisioned(&object.id, NAMESPACE), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_deprovision_namespace() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        test_scenario::next_tx(&mut scenario, NAMESPACE);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            client::provision(&mut object.id, NAMESPACE, &auth);
            assert!(client::is_provisioned(&object.id, NAMESPACE), 0);

            client::deprovision(&mut object.id, NAMESPACE, &auth);
            assert!(!client::is_provisioned(&object.id, NAMESPACE), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_can_borrow_uid_mut_with_namespace() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        test_scenario::next_tx(&mut scenario, NAMESPACE);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            client::provision(&mut object.id, NAMESPACE, &auth);
            assert!(client::can_borrow_uid_mut(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_cannot_borrow_uid_mut() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        test_scenario::next_tx(&mut scenario, @0xCADE);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            assert!(!client::can_borrow_uid_mut(&object.id, &auth), 0);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::client::ENO_PROVISION_AUTHORITY)]
    fun test_provision_with_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        {
            let auth = tx_authority::begin(ctx);

            client::provision(&mut object.id, NAMESPACE, &auth);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::client::ENO_PROVISION_AUTHORITY)]
    fun test_deprovision_with_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let object = create_test_object(SENDER, @0x0, ctx);

        test_scenario::next_tx(&mut scenario, NAMESPACE);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            client::provision(&mut object.id, NAMESPACE, &auth);
        };

        test_scenario::next_tx(&mut scenario, SENDER);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            client::deprovision(&mut object.id, NAMESPACE, &auth);
        };

        delete_test_object(object);
        test_scenario::end(scenario);
    }
}