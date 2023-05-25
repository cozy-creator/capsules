#[test_only]
module ownership::organizationn_tests {
    use std::vector;
    use std::string;

    use sui::object;
    use sui::test_scenario::{Self, Scenario};
    
    use ownership::tx_authority;
    use ownership::publish_receipt_tests;
    use ownership::organization::{Self, Organization};
    use ownership::publish_receipt::{Self, PublishReceipt};

    struct Witness has drop {}

    struct EDITOR {}
    struct FAKE_PERM {}

    const SENDER: address = @0xFACE;
    const AGENT: address = @0xCAFE;

    public fun create_organization(scenario: &mut Scenario, receipt: &mut PublishReceipt) {
        let ctx = test_scenario::ctx(scenario);
        organization::create_from_receipt_(receipt, ctx)
    }

    #[test]
    fun create_organization_from_package() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);
        let package_id = publish_receipt::into_package_id(&receipt);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            assert!(organization::packages(&organization) == vector::singleton(package_id), 0);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun create_organization_from_package_and_destroy() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);
        let package_id = publish_receipt::into_package_id(&receipt);

        {
            let ctx = test_scenario::ctx(&mut scenario);
            let organization = organization::create_from_receipt(&mut receipt, SENDER, ctx);

            organization::remove_package_(&mut organization, package_id, SENDER, ctx);
            organization::destroy(organization, &tx_authority::begin(ctx));
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun add_stored_package() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);
        let package_id = publish_receipt::into_package_id(&receipt);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            let stored_package = organization::remove_package(&mut organization, package_id, &auth);
            organization::add_package_from_stored(&mut organization, stored_package, &auth);

            assert!(organization::packages(&organization) == vector::singleton(package_id), 0);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun set_role_for_agent() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let role = string::utf8(b"Editor");

            organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);

            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun delete_agent() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            // let role = string::utf8(b"Editor");

            // organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);
            organization::delete_agent(&mut organization, AGENT, &auth);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun grant_permission_to_role() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun revoke_permission_from_role() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            // std::debug::print(&organization);
            organization::revoke_permission_from_role<EDITOR>(&mut organization, role, &auth);
            // std::debug::print(&organization);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun delete_role_and_agents() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            // organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            // std::debug::print(&organization);
            organization::delete_role_and_agents(&mut organization, role, &auth);
            // std::debug::print(&organization);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_claim_permissions() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        let organization = test_scenario::take_shared<Organization>(&scenario);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);
        };

        test_scenario::next_tx(&mut scenario, AGENT);
        {
            let ctx = test_scenario::ctx(&mut scenario);

            let auth = organization::claim_permissions(&mut organization, ctx);
            assert!(tx_authority::has_permission<EDITOR>(AGENT, &auth), 0);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_claim_permissions_() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        let organization = test_scenario::take_shared<Organization>(&scenario);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);
        };

        test_scenario::next_tx(&mut scenario, AGENT);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            let auth = organization::claim_permissions_(&mut organization, &auth);
            assert!(tx_authority::has_permission<EDITOR>(AGENT, &auth), 0);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_assert_login() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        let organization = test_scenario::take_shared<Organization>(&scenario);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);
        };

        test_scenario::next_tx(&mut scenario, AGENT);
        {
            let ctx = test_scenario::ctx(&mut scenario);

            let auth = organization::assert_login<EDITOR>(&mut organization, ctx);
            assert!(tx_authority::has_permission<EDITOR>(AGENT, &auth), 0);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_assert_login_() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        let organization = test_scenario::take_shared<Organization>(&scenario);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);
        };

        test_scenario::next_tx(&mut scenario, AGENT);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            let auth = organization::assert_login_<EDITOR>(&mut organization, &auth);
            assert!(tx_authority::has_permission<EDITOR>(AGENT, &auth), 0);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    // #[test]
    // fun test_create_single_use_permission() {
    //     let scenario = test_scenario::begin(SENDER);
    //     let receipt = publish_receipt_tests::create_receipt(&mut scenario);

    //     create_organization(&mut scenario, &mut receipt);
    //     test_scenario::next_tx(&mut scenario, SENDER);

    //     let organization = test_scenario::take_shared<Organization>(&scenario);
    //     {
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = tx_authority::begin(ctx);
    //         let role_1 = string::utf8(b"Editor");
    //         let role_2 = string::utf8(b"SuperAgent");

    //         organization::grant_permission_to_role<EDITOR>(&mut organization, role_1, &auth);
    //         organization::grant_permission_to_role<SINGLE_USE>(&mut organization, role_2, &auth);

    //         organization::set_role_for_agent_(&mut organization, AGENT, role_1, ctx);
    //         organization::set_role_for_agent_(&mut organization, AGENT, role_2, ctx);
    //     };

    //     test_scenario::next_tx(&mut scenario, AGENT);
    //     {
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = organization::claim_permissions(&organization, ctx);
            
    //         let single_use = organization::create_single_use_permission<EDITOR>(&auth, ctx);
    //         let auth = tx_authority::begin_with_single_use(single_use);
    //         std::debug::print(&auth);
    //         // assert!(tx_authority::has_permission<EDITOR>(AGENT, &auth), 0);
    //     };

    //     organization::return_and_share(organization);
    //     publish_receipt_tests::destroy_receipt(receipt);
    //     test_scenario::end(scenario);
    // }

    #[test]
    fun test_organization_uid() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        let organization = test_scenario::take_shared<Organization>(&scenario);
        let uid = organization::uid(&organization);
        assert!(object::uid_to_inner(uid) == object::id(&organization), 0);

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_organization_uid_mut() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        let organization = test_scenario::take_shared<Organization>(&scenario);

        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        
        organization::uid_mut(&mut organization, &auth);

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun create_organization_from_package_and_destroy_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);
        let package_id = publish_receipt::into_package_id(&receipt);

        let ctx = test_scenario::ctx(&mut scenario);
        let organization = organization::create_from_receipt(&mut receipt, SENDER, ctx);
        organization::remove_package_(&mut organization, package_id, SENDER, ctx);
        test_scenario::next_tx(&mut scenario, AGENT);

        {
            let ctx = test_scenario::ctx(&mut scenario);
            organization::destroy(organization, &tx_authority::begin(ctx));
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::EPACKAGES_MUST_BE_EMPTY)]
    fun create_organization_from_package_and_destroy_non_empty_packages() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        {
            let ctx = test_scenario::ctx(&mut scenario);
            let organization = organization::create_from_receipt(&mut receipt, SENDER, ctx);

            organization::destroy(organization, &tx_authority::begin(ctx));
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun remove_package_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);
        let package_id = publish_receipt::into_package_id(&receipt);

        let ctx = test_scenario::ctx(&mut scenario);
        let organization = organization::create_from_receipt(&mut receipt, SENDER, ctx);

        test_scenario::next_tx(&mut scenario, AGENT);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            organization::remove_package_(&mut organization, package_id, SENDER, ctx);
        };
        
        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun add_package_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, AGENT);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            organization::add_package(&mut receipt, &mut organization, &auth, ctx);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::EPACKAGE_ALREADY_CLAIMED)]
    fun add_package_already_claimed() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            organization::add_package(&mut receipt, &mut organization, &auth, ctx);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun add_stored_package_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);
        let package_id = publish_receipt::into_package_id(&receipt);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);
        
        let organization = test_scenario::take_shared<Organization>(&scenario);
        let stored_package;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            stored_package = organization::remove_package(&mut organization, package_id, &auth);
        };

        test_scenario::next_tx(&mut scenario, AGENT);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            organization::add_package_from_stored(&mut organization, stored_package, &auth);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun set_role_for_agent_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, AGENT);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let role = string::utf8(b"Editor");

            organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);

            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }


    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun delete_agent_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, AGENT);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            organization::delete_agent(&mut organization, AGENT, &auth);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun grant_permission_to_role_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, AGENT);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun revoke_permission_from_role_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, AGENT);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::revoke_permission_from_role<EDITOR>(&mut organization, role, &auth);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_OWNER_AUTHORITY)]
    fun delete_role_and_agents_invalid_owner() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, AGENT);

        {
            let organization = test_scenario::take_shared<Organization>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::delete_role_and_agents(&mut organization, role, &auth);
            organization::return_and_share(organization);
        };

        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_PERMISSION)]
    fun test_assert_login_fake_perm() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, SENDER);

        let organization = test_scenario::take_shared<Organization>(&scenario);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let role = string::utf8(b"Editor");

            organization::grant_permission_to_role<EDITOR>(&mut organization, role, &auth);
            organization::set_role_for_agent_(&mut organization, AGENT, role, ctx);
        };

        test_scenario::next_tx(&mut scenario, AGENT);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            organization::assert_login_<FAKE_PERM>(&mut organization, &auth);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }


    #[test]
    #[expected_failure(abort_code=ownership::organization::ENO_PERMISSION)]
    fun test_uid_mut_invalid_perm() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = publish_receipt_tests::create_receipt(&mut scenario);

        create_organization(&mut scenario, &mut receipt);
        test_scenario::next_tx(&mut scenario, AGENT);

        let organization = test_scenario::take_shared<Organization>(&scenario);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            organization::uid_mut(&mut organization, &auth);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }
}