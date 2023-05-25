#[test_only]
module ownership::delegation_tests {
 use sui::test_scenario;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    use ownership::ownership;
    use ownership::delegation;
    use ownership::tx_authority;
    // use ownership::permission::ADMIN;

    // use sui_utils::encode;
    use sui_utils::typed_id;

    const SENDER: address = @0xFACE;
    const AGENT: address = @0xBABE;

    struct Witness has drop {}
    struct EDITOR {}

    struct TestObject has key {
        id: UID
    }

    fun create_test_object(owner: address, ctx: &mut TxContext): TestObject {
        let object = TestObject { 
            id: object::new(ctx) 
        };
        
        let tid = typed_id::new(&object);
        let auth = tx_authority::begin_with_package_witness(Witness { });
        ownership::as_shared_object_(&mut object.id, tid, owner, owner, &auth);

        object
    }

    fun delete_test_object(object: TestObject) {
        let TestObject { id } = object;
        object::delete(id)
    }

    #[test]
    fun create_delegation_and_store_and_destroy_() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let auth = tx_authority::begin(ctx);
            let store = delegation::create_(SENDER, &auth, ctx);

            delegation::destroy(store, &auth);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun create_delegation_and_store() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun create_delegation_and_store_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let auth = tx_authority::begin_with_type(&Witness {});
            let store = delegation::create_(SENDER, &auth, ctx);

            delegation::destroy(store, &auth);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun add_permission_to_store() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission<EDITOR>(&mut store, AGENT, &auth);
            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    // #[test]
    // fun add_permission_to_store() {
    //     let scenario = test_scenario::begin(SENDER);
    //     let ctx = test_scenario::ctx(&mut scenario);

    //     {
    //         let store = delegation::create(ctx);
    //         let auth = tx_authority::begin(ctx);

    //         delegation::add_permission<EDITOR>(&mut store, AGENT, &auth);
    //         delegation::return_and_share(store);
    //     };

    //     test_scenario::end(scenario);
    // }

}