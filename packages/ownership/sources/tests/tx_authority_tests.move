#[test_only]
module ownership::tx_authority_tests {
    use std::vector;

    use sui::vec_map;
    use sui::test_scenario;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    use ownership::tx_authority;
    use ownership::permission::ADMIN;
    use sui_utils::encode;

    const SENDER: address = @0xFACE;

    struct Witness has drop {}

    struct TestObject has key {
        id: UID
    }

    fun create_test_object(ctx: &mut TxContext): TestObject {
        TestObject {
            id: object::new(ctx)
        }
    }

    fun delete_test_object(object: TestObject) {
        let TestObject { id } = object;
        object::delete(id)
    }

    #[test]
    public fun empty_tx_authority() {
        let scenario = test_scenario::begin(SENDER);

        {
            let auth = tx_authority::empty();

            assert!(vector::is_empty(&tx_authority::agents(&auth)), 0);
            assert!(vec_map::is_empty(&tx_authority::organizations(&auth)), 0);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun begin_tx_authority() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let witness = Witness { };

            let auth_ctx = tx_authority::begin(ctx);
            let auth_id = tx_authority::begin_with_id(&test_object);
            let auth_type = tx_authority::begin_with_type(&witness);
            let auth_witness = tx_authority::begin_with_package_witness(witness);

            assert!(tx_authority::has_permission<ADMIN>(SENDER, &auth_ctx), 0);
            assert!(tx_authority::has_permission<ADMIN>(object::id_address(&test_object), &auth_id), 0);
            assert!(tx_authority::has_permission<ADMIN>(encode::type_into_address<Witness>(), &auth_type), 0);
            assert!(tx_authority::has_permission<ADMIN>(object::id_to_address(&encode::package_id<Witness>()), &auth_witness), 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }

    #[test]
    public fun add_tx_authority() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let witness = Witness { };

            let auth = tx_authority::begin(ctx);
            auth = tx_authority::add_type(&witness, &auth);
            auth = tx_authority::add_id(&test_object, &auth);
            auth = tx_authority::add_package_witness(witness, &auth);

            assert!(tx_authority::has_permission<ADMIN>(SENDER, &auth), 0);
            assert!(tx_authority::has_permission<ADMIN>(object::id_address(&test_object), &auth), 0);
            assert!(tx_authority::has_permission<ADMIN>(encode::type_into_address<Witness>(), &auth), 0);
            assert!(tx_authority::has_permission<ADMIN>(object::id_to_address(&encode::package_id<Witness>()), &auth), 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }

    #[test]
    public fun add_signer_to_tx_authority() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let witness = Witness { };

            let auth = tx_authority::begin_with_type(&witness);
            auth = tx_authority::add_signer(ctx, &auth);

            assert!(tx_authority::has_permission<ADMIN>(SENDER, &auth), 0);
            assert!(tx_authority::has_permission<ADMIN>(encode::type_into_address<Witness>(), &auth), 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }
    #[test]
    public fun copy_tx_authority() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let auth_1 = tx_authority::begin(ctx);
            let auth_2 = tx_authority::copy_(&auth_1);
            
            assert!(auth_1 == auth_2, 0);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun package_permission() {
        let scenario = test_scenario::begin(SENDER);

        {
            let witness = Witness { };
            let package_id = encode::package_id<Witness>();

            let auth = tx_authority::begin_with_package_witness(witness);
            assert!(tx_authority::has_package_permission<Witness, ADMIN>(&auth), 0);
            assert!(tx_authority::has_package_permission_<ADMIN>(package_id, &auth), 0);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun id_permission() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let auth = tx_authority::begin_with_id(&test_object);
            assert!(tx_authority::has_id_permission<TestObject, ADMIN>(&test_object, &auth), 0);
            assert!(tx_authority::has_id_permission_<ADMIN>(object::id(&test_object), &auth), 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }

    #[test]
    public fun type_permission() {
        let scenario = test_scenario::begin(SENDER);

        {
            let witness = Witness { };
            let auth = tx_authority::begin_with_type(&witness);
            assert!(tx_authority::has_type_permission<Witness, ADMIN>(&auth), 0);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun has_k_or_more_agents_with_permission() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let witness = Witness { };

            let auth = tx_authority::begin(ctx);
            auth = tx_authority::add_type(&witness, &auth);
            auth = tx_authority::add_id(&test_object, &auth);
            auth = tx_authority::add_package_witness(witness, &auth);

            let principals = vector[SENDER, object::id_address(&test_object), encode::type_into_address<Witness>()];

            // This should always pass
            assert!(tx_authority::has_k_or_more_agents_with_permission<ADMIN>(principals, 0, &auth), 0);
            assert!(tx_authority::has_k_or_more_agents_with_permission<ADMIN>(principals, 3, &auth), 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }

    #[test]
    public fun tally_agents_with_permission() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let witness = Witness { };

            let auth = tx_authority::begin(ctx);
            auth = tx_authority::add_type(&witness, &auth);
            auth = tx_authority::add_id(&test_object, &auth);
            auth = tx_authority::add_package_witness(witness, &auth);

            let principals = vector[SENDER, object::id_address(&test_object), encode::type_into_address<Witness>()];
            assert!(tx_authority::tally_agents_with_permission<ADMIN>(principals, &auth) == 3, 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::tx_authority_tests)]
    public fun begin_tx_authority_invalid() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let witness = Witness { };

            let auth_ctx = tx_authority::begin(ctx);
            let auth_id = tx_authority::begin_with_id(&test_object);
            let auth_type = tx_authority::begin_with_type(&witness);
            let auth_witness = tx_authority::begin_with_package_witness(witness);

            let fake_addr = @0xDEAD;

            assert!(tx_authority::has_permission<ADMIN>(fake_addr, &auth_ctx), 0);
            assert!(tx_authority::has_permission<ADMIN>(fake_addr, &auth_id), 0);
            assert!(tx_authority::has_permission<ADMIN>(fake_addr, &auth_type), 0);
            assert!(tx_authority::has_permission<ADMIN>(fake_addr, &auth_witness), 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::tx_authority_tests)]
    public fun has_k_or_more_agents_with_permission_failure() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let test_object = create_test_object(ctx);

        {
            let witness = Witness { };

            let auth = tx_authority::begin(ctx);
            auth = tx_authority::add_type(&witness, &auth);
            auth = tx_authority::add_id(&test_object, &auth);
            auth = tx_authority::add_package_witness(witness, &auth);

            let principals = vector[SENDER, object::id_address(&test_object), encode::type_into_address<Witness>()];
            assert!(tx_authority::has_k_or_more_agents_with_permission<ADMIN>(principals, 5, &auth), 0);
        };

        delete_test_object(test_object);
        test_scenario::end(scenario);
    }

    // #[test]
    // #[expected_failure(abort_code=0,location=ownership::tx_authority_tests)]
    // public fun has_org_permission_excluding_manager_no_org() {
    //     let scenario = test_scenario::begin(SENDER);
    //     let ctx = test_scenario::ctx(&mut scenario);
    //     let auth = tx_authority::begin(ctx);

    //     assert!(tx_authority::has_org_permission_excluding_manager<Witness, ADMIN>(&auth), 0);
    //     test_scenario::end(scenario);
    // }

    // #[test]
    // #[expected_failure(abort_code=0,location=ownership::tx_authority_tests)]
    // public fun has_org_permission_excluding_manager_no_principal() {
    //     let scenario = test_scenario::begin(SENDER);
    //     let ctx = test_scenario::ctx(&mut scenario);
    //     let auth = tx_authority::begin(ctx);

    //     assert!(tx_authority::has_org_permission_excluding_manager_<ADMIN>(@0xFADE, &auth), 0);
    //     test_scenario::end(scenario);
    // }

    #[test]
    #[expected_failure(abort_code=0,location=ownership::tx_authority_tests)]
    fun has_package_permission_invalid_package() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        assert!(tx_authority::has_package_permission<Witness, ADMIN>(&auth), 0);
        test_scenario::end(scenario);
    }
}