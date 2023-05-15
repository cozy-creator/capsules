#[test_only]
module ownership::publish_receipt_tests {
    use sui::object;
    use sui::test_scenario::{Self, Scenario};

    use sui_utils::encode;
    use ownership::publish_receipt::{Self, PublishReceipt};

    struct BAD_WITNESS has drop {}
    struct PUBLISH_RECEIPT_TESTS has drop {}

    const SENDER: address = @0xFAEC;

    #[test_only]
    public fun create_receipt(scenario: &mut Scenario): PublishReceipt {
        let ctx = test_scenario::ctx(scenario);
        publish_receipt::claim_for_testing(&PUBLISH_RECEIPT_TESTS { }, ctx)
    }

    public fun destroy_receipt(receipt: PublishReceipt) {
        publish_receipt::destroy_for_testing(receipt)
    }

    #[test]
    fun claim_receipt() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = create_receipt(&mut scenario);
        let package_id = encode::package_id<PUBLISH_RECEIPT_TESTS>();

        assert!(publish_receipt::into_package_id(&receipt) == package_id, 0);
        assert!(publish_receipt::did_publish<PUBLISH_RECEIPT_TESTS>(&receipt), 0);

        destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code=ownership::publish_receipt::EBAD_WITNESS)]
    fun claim_receipt_bad_witness() {
        let scenario = test_scenario::begin(SENDER);
        let ctx = test_scenario::ctx(&mut scenario);
        let receipt = publish_receipt::claim_for_testing(&BAD_WITNESS { }, ctx);

        destroy_receipt(receipt);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_uid() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = create_receipt(&mut scenario);

        let uid = publish_receipt::uid(&receipt);
        assert!(object::uid_to_inner(uid) == object::id(&receipt), 0);

        destroy_receipt(receipt);
        test_scenario::end(scenario);
    }
}