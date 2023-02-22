

#[test_only]
module dispenser::data_dispenser_test {
    use std::option::{Self, Option};
    use std::vector;

    use sui::test_scenario::{Self, Scenario};
    use sui::bcs;

    use dispenser::data_dispenser::{Self, DataDispenser};

    const ADMIN: address = @0xFAEC;

    fun initialize_scenario(schema: Option<vector<vector<u8>>>): Scenario {
        let scenario = test_scenario::begin(ADMIN);

        let ctx = test_scenario::ctx(&mut scenario);
        let dispenser = data_dispenser::initialize(option::none(), 5, true, schema, ctx);

        data_dispenser::publish(dispenser);
        test_scenario::next_tx(&mut scenario, ADMIN);

        scenario
    }

    fun get_dispenser_test_data(): vector<vector<u8>> {
        vector[
            bcs::to_bytes(&b"Sui"), 
            bcs::to_bytes(&b"Move"), 
            bcs::to_bytes(&b"Capsule"), 
            bcs::to_bytes(&b"Object"), 
            bcs::to_bytes(&b"Metadata")
        ]
    }

    fun load_dispenser(scenario: &mut Scenario, dispenser: &mut DataDispenser, data: vector<vector<u8>>) {
        data_dispenser::load(dispenser, data, test_scenario::ctx(scenario));
    }

    fun sequential_dispense(dispenser: &mut DataDispenser): vector<u8> {
       data_dispenser::sequential_dispense(dispenser)
    }

    fun set_dispenser_schema(scenario: &mut Scenario, dispenser: &mut DataDispenser, schema: vector<vector<u8>>) {
       data_dispenser::set_schema(dispenser, schema, test_scenario::ctx(scenario))
    }

    #[test]
    fun test_sequential_data_dispenser() {
        let scenario = initialize_scenario(option::some(vector[b"String"]));
        let data = get_dispenser_test_data();

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);
            let (i, len) = (0, vector::length(&data));

            while (i < len) {
                let item = sequential_dispense(&mut dispenser);
                assert!(&item == vector::borrow(&data, i), 0);

                i = i + 1;
            };

            test_scenario::return_shared(dispenser);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::EInvalidAuth)]
    fun test_invalid_dispenser_auth_failure() {
        let scenario = initialize_scenario(option::some(vector[b"String"]));
        let data = get_dispenser_test_data();

        test_scenario::next_tx(&mut scenario, @0xABCE);
        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::ELoadEmptyItems)]
    fun test_empty_dispenser_data_failure() {
        let scenario = initialize_scenario(option::some(vector[b"String"]));

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, vector::empty());
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::ESchemaNotSet)]
    fun test_unset_dispenser_schema_failure() {
        let scenario = initialize_scenario(option::none());
        let data = get_dispenser_test_data();

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::EAvailableCapacityExceeded)]
    fun test_dispenser_capacity_exceeded_failure() {
        let scenario = initialize_scenario(option::none());
        let data = get_dispenser_test_data();

        // add more data to the test data
        vector::push_back(&mut data, bcs::to_bytes(&b"Dispenser"));

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::schema::EUnspportedType)]
    fun test_dispenser_unsupported_type_failure() {
        let scenario = initialize_scenario(option::some(vector[b"int8"]));
        let data = get_dispenser_test_data();

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::EDispenserAlreadyLoaded)]
    fun test_set_schema_already_loaded_failure() {
        let scenario = initialize_scenario(option::some(vector[b"String"]));
        let data = get_dispenser_test_data();

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            set_dispenser_schema(&mut scenario, &mut dispenser, vector[b"String"]);

            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::ESchemaAlreadySet)]
    fun test_set_schema_already_set_failure() {
        let scenario = initialize_scenario(option::some(vector[b"String"]));

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            set_dispenser_schema(&mut scenario, &mut dispenser, vector[b"String"]);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::EDispenserEmpty)]
    fun test_sequential_empty_data_dispenser_failure() {
        let scenario = initialize_scenario(option::some(vector[b"String"]));
        let data = get_dispenser_test_data();

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);
            let (i, len) = (0, vector::length(&data));

            while (i < len) {
                let item = sequential_dispense(&mut dispenser);
                assert!(&item == vector::borrow(&data, i), 0);

                i = i + 1;
            };

            sequential_dispense(&mut dispenser);

            test_scenario::return_shared(dispenser);
        };

        test_scenario::end(scenario);
    }
}