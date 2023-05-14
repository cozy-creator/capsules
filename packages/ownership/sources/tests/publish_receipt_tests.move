#[test_only]
module ownership::publish_receipt_tests {
    use sui::test_scenario::{Self, Scenario};

    use sui_utils::encode;
    use ownership::publish_receipt::{Self, PublishReceipt};

    struct RECEIPT_GENESIS has drop {}

    const SENDER: address = @0xFAEC;

    public fun create_receipt(scenario: &mut Scenario): PublishReceipt {
        let ctx = test_scenario::ctx(scenario);
        publish_receipt::claim_for_testing(&RECEIPT_GENESIS { }, ctx)
    }

    public fun destroy_receipt(receipt: PublishReceipt) {
        publish_receipt::destroy_for_testing(receipt)
    }

    #[test]
    fun claim_receipt() {
        let scenario = test_scenario::begin(SENDER);
        let receipt = create_receipt(&mut scenario);
        let package_id = encode::package_id<RECEIPT_GENESIS>();

        assert!(publish_receipt::into_package_id(&receipt) == package_id, 0);
        assert!(publish_receipt::did_publish<RECEIPT_GENESIS>(&receipt), 0);

        destroy_receipt(receipt);
        test_scenario::end(scenario);
    }
}