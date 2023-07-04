#[test_only]
module ownership::delegation_tests {
    use std::option;
    use std::vector;

    use sui::vec_map;
    use sui::test_scenario;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    use ownership::ownership;
    use ownership::delegation;
    use ownership::permission;
    use ownership::tx_authority;
    use ownership::permission_set;

    use sui_utils::struct_tag;
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
            let general = permission_set::general(&delegation::agent_permissions(&store, AGENT));

            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *general, 0);
            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun add_permission_to_store_for_type() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission_for_type<Witness, EDITOR>(&mut store, AGENT, &auth);
            let types_map = permission_set::types(&delegation::agent_permissions(&store, AGENT));

            let type = vec_map::get(types_map, &struct_tag::get<Witness>());
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *type, 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun add_permission_to_store_for_types() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);
            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];

            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);

            let types_map_1 = permission_set::types(&delegation::agent_permissions(&store, AGENT));
            let type_1 = vec_map::get(types_map_1, &struct_tag::get<Witness>());
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *type_1, 0);

            let types_map_2 = permission_set::types(&delegation::agent_permissions(&store, AGENT));
            let type_2 = vec_map::get(types_map_2, &struct_tag::get<Witness>());
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *type_2, 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun add_permission_to_store_for_objects() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);
            let objects = vector[object::id_from_address(@0xFAE)];

            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);
            
            let objects_map = permission_set::objects(&delegation::agent_permissions(&store, AGENT));
            let object = vec_map::get(objects_map, &object::id_from_address(@0xFAE));
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *object, 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun add_permission_to_store_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        let store = delegation::create(ctx);
        {
            test_scenario::next_tx(&mut scenario, @0xFABE);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission<EDITOR>(&mut store, AGENT, &auth);
        };

        delegation::return_and_share(store);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun add_permission_to_store_for_type_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        let store = delegation::create(ctx);
        {
            test_scenario::next_tx(&mut scenario, @0xFABE);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission_for_type<Witness, EDITOR>(&mut store, AGENT, &auth);
        };

        delegation::return_and_share(store);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun add_permission_to_store_for_types_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        let store = delegation::create(ctx);
        {
            test_scenario::next_tx(&mut scenario, @0xFABE);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];
            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);
        };

        delegation::return_and_share(store);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun add_permission_to_store_for_objects_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        let store = delegation::create(ctx);
        {
            test_scenario::next_tx(&mut scenario, @0xFABE);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xFAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);
        };

        delegation::return_and_share(store);
        test_scenario::end(scenario);
    }

    #[test]
    fun remove_general_permission_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission<EDITOR>(&mut store, AGENT, &auth);

            let general = permission_set::general(&delegation::agent_permissions(&store, AGENT));
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *general, 0);

            {
                delegation::remove_general_permission_from_agent<EDITOR>(&mut store, AGENT, &auth);
                let general = permission_set::general(&delegation::agent_permissions(&store, AGENT));
             
                assert!(vector::is_empty(general), 0);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_general_permission_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission<EDITOR>(&mut store, AGENT, &auth);

            let general = permission_set::general(&delegation::agent_permissions(&store, AGENT));
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *general, 0);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_general_permission_from_agent<EDITOR>(&mut store, AGENT, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_all_general_permissions_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission<EDITOR>(&mut store, AGENT, &auth);

            let general = permission_set::general(&delegation::agent_permissions(&store, AGENT));
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *general, 0);

            {
                delegation::remove_all_general_permissions_from_agent(&mut store, AGENT, &auth);
                let general = permission_set::general(&delegation::agent_permissions(&store, AGENT));
             
                assert!(vector::is_empty(general), 0);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_all_general_permissions_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission<EDITOR>(&mut store, AGENT, &auth);

            let general = permission_set::general(&delegation::agent_permissions(&store, AGENT));
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *general, 0);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_all_general_permissions_from_agent(&mut store, AGENT, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_permission_for_type_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission_for_type<Witness, EDITOR>(&mut store, AGENT, &auth);

            let types_map = permission_set::types(&delegation::agent_permissions(&store, AGENT));
            let type = vec_map::get(types_map, &struct_tag::get<Witness>());
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *type, 0);

            {
                delegation::remove_permission_for_type_from_agent<Witness, EDITOR>(&mut store, AGENT, &auth);

                let types_map = permission_set::types(&delegation::agent_permissions(&store, AGENT));
                let type = vec_map::get(types_map, &struct_tag::get<Witness>());
                assert!(vector::is_empty(type), 0);

            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_permission_for_type_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            delegation::add_permission_for_type<Witness, EDITOR>(&mut store, AGENT, &auth);

            let types_map = permission_set::types(&delegation::agent_permissions(&store, AGENT));
            let type = vec_map::get(types_map, &struct_tag::get<Witness>());
            assert!(vector::singleton(permission::new_for_testing<EDITOR>()) == *type, 0);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_permission_for_type_from_agent<Witness, EDITOR>(&mut store, AGENT, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_permission_for_types_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];
            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);

            delegation::remove_permission_for_types_from_agent<EDITOR>(&mut store, AGENT, types, &auth);

            let types_map = permission_set::types(&delegation::agent_permissions(&store, AGENT));
            assert!(vector::is_empty(vec_map::get(types_map, &struct_tag::get<Witness>())), 0);
            assert!(vector::is_empty(vec_map::get(types_map, &struct_tag::get<TestObject>())), 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_permission_for_types_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];
            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_permission_for_types_from_agent<EDITOR>(&mut store, AGENT, types, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_type_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];
            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);

            delegation::remove_type_from_agent<Witness>(&mut store, AGENT, &auth);
            let types_map = permission_set::types(&delegation::agent_permissions(&store, AGENT));
            assert!(option::is_none(&vec_map::try_get(types_map, &struct_tag::get<Witness>())), 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_type_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];
            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_type_from_agent<Witness>(&mut store, AGENT, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_types_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];
            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);

            delegation::remove_types_from_agent(&mut store, AGENT, types, &auth);

            let types_map = permission_set::types(&delegation::agent_permissions(&store, AGENT));
            assert!(option::is_none(&vec_map::try_get(types_map, &struct_tag::get<Witness>())), 0);
            assert!(option::is_none(&vec_map::try_get(types_map, &struct_tag::get<TestObject>())), 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_types_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let types = vector[struct_tag::get<Witness>(), struct_tag::get<TestObject>()];
            delegation::add_permission_for_types<EDITOR>(&mut store, AGENT, types, &auth);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_types_from_agent(&mut store, AGENT, types, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_permission_for_objects_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xEAE), object::id_from_address(@0xDAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);

            delegation::remove_permission_for_objects_from_agent<EDITOR>(&mut store, AGENT, objects, &auth);

            let objects_map = permission_set::objects(&delegation::agent_permissions(&store, AGENT));
            assert!(vector::is_empty(vec_map::get(objects_map, &object::id_from_address(@0xEAE))), 0);
            assert!(vector::is_empty(vec_map::get(objects_map, &object::id_from_address(@0xDAE))), 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_permission_for_objects_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xEAE), object::id_from_address(@0xDAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_permission_for_objects_from_agent<EDITOR>(&mut store, AGENT, objects, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_objects_from_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xEAE), object::id_from_address(@0xDAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);

            delegation::remove_objects_from_agent(&mut store, AGENT, objects, &auth);

            let objects_map = permission_set::objects(&delegation::agent_permissions(&store, AGENT));
            assert!(option::is_none(&vec_map::try_get(objects_map, &object::id_from_address(@0xEAE))), 0);
            assert!(option::is_none(&vec_map::try_get(objects_map, &object::id_from_address(@0xDAE))), 0);

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_objects_from_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xEAE), object::id_from_address(@0xDAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_objects_from_agent(&mut store, AGENT, objects, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun remove_agent() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xEAE), object::id_from_address(@0xDAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);

            delegation::remove_agent(&mut store, AGENT, &auth);

            let objects_map = permission_set::objects(&delegation::agent_permissions(&store, AGENT));
            assert!(vec_map::is_empty(objects_map), 0);


            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code=ownership::delegation::ENO_ADMIN_AUTHORITY)]
    fun remove_agent_invalid_auth() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xEAE), object::id_from_address(@0xDAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                let auth = tx_authority::begin(ctx);
                delegation::remove_agent(&mut store, AGENT, &auth);
            };

            delegation::return_and_share(store);
        };

        test_scenario::end(scenario);
    }


    #[test]
    fun claim_delegation() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let store = delegation::create(ctx);
            let auth = tx_authority::begin(ctx);

            let objects = vector[object::id_from_address(@0xEAE), object::id_from_address(@0xDAE)];
            delegation::add_permission_for_objects<EDITOR>(&mut store, AGENT, objects, &auth);

            test_scenario::next_tx(&mut scenario, @0xFABE);
            {
                let ctx = test_scenario::ctx(&mut scenario);
                delegation::claim_delegation(&store, ctx);
            };

            delegation::destroy(store, &auth);
        };

        test_scenario::end(scenario);
    }
}