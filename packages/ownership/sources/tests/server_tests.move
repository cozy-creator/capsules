#[test_only]
module ownership::server_tests {
    use std::option;
    use std::string;

    use sui::test_scenario::{Self, Scenario};

    use ownership::server;
    use ownership::tx_authority;
    use ownership::permission::ADMIN;
    use ownership::publish_receipt_tests;
    use ownership::publish_receipt::PublishReceipt;
    use ownership::organization::{Self, Organization};

    use sui_utils::encode;

    const SENDER: address = @0xFACE;
    const AGENT: address = @0xCAFE;

    struct Witness has drop {}

    struct EDITOR {}

    public fun create_organization(scenario: &mut Scenario, receipt: &mut PublishReceipt) {
        let ctx = test_scenario::ctx(scenario);
        organization::create_from_receipt_(receipt, ctx)
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
            let auth = server::assert_login<EDITOR>(&mut organization, ctx);

            assert!(tx_authority::has_permission<EDITOR>(AGENT, &auth), 0);
        };

        organization::return_and_share(organization);
        publish_receipt_tests::destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun has_package_permission() {
        let auth = tx_authority::begin_with_package_witness(Witness { });
        assert!(server::has_package_permission_<ADMIN>(encode::package_id<Witness>(), &auth), 0);
    }

    #[test]
    fun has_package_permission_opt() {
        let auth = tx_authority::begin_with_package_witness(Witness { });
        let package_id = encode::package_id<Witness>();

        assert!(server::has_package_permission_opt<ADMIN>(option::none(), &auth), 0);
        assert!(server::has_package_permission_opt<ADMIN>(option::some(package_id), &auth), 0);
    }
}