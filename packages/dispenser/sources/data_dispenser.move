// Data dispenser module
// Dispenser for data creation and distribution on the Sui network.

module dispenser::data_dispenser {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::randomness::{Self, Randomness};

    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use dispenser::schema::{Self, Schema};

    struct DataDispenser has key {
        id: UID,
        items_available: u64, // the number of items available
        items: vector<vector<u8>>, 
        randomness_id: Option<ID>, // id of the randomness object which will be used to select item for non sequential dispenser
        config: Config,
    }

    struct Config has store {
        capacity: u64, // capacity of the dispenser, i.e max number of items
        is_sequential: bool,
        schema: Option<Schema>
    }

    struct RANDOMNESS_WITNESS has drop {}
    struct Witness has drop {}

    const EInvalidAuth: u64 = 0;
    const ELoadEmptyItems: u64 = 1;
    const EDispenserAlreadLoaded: u64 = 2;
    const EAvailableCapacityExceeded: u64 = 3;
    const EInvalidData: u64 = 5;
    const ESchemaNotSet: u64 = 6;
    const EDispenserEmpty: u64 = 7;
    const EInvalidDispenserType: u64 = 8;
    const ERandomnessMismatch: u64 = 9;
    const EMissingRandomness: u64 = 10;
    const EDispenserAlreadyLoaded: u64 = 11;
    const ESchemaAlreadySet: u64 = 12;

    fun new(capacity: u64, is_sequential: bool, schema: Option<Schema>, ctx: &mut TxContext): DataDispenser {
         DataDispenser {
            id: object::new(ctx),
            items_available: 0, 
            items: vector::empty(),
            randomness_id: option::none(),
            config: Config {
                is_sequential,
                schema,
                capacity,
            }
        }
    }

    /// Initializes the dispenser and returns it by value
    public fun initialize(owner: Option<address>, capacity: u64, is_sequential: bool, schema: Option<vector<vector<u8>>>, ctx: &mut TxContext): DataDispenser {
        let dispenser = new(capacity, is_sequential, option::none(), ctx);

        let owner = if(option::is_some(&owner)) option::extract(&mut owner) else tx_context::sender(ctx);
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        let proof = ownership::setup(&dispenser);

        // initialize the dispenser ownership, using the capsule standard
        ownership::initialize(&mut dispenser.id, proof, &auth);

        // set the dispenser data schema if provided
        if(option::is_some(&schema)) {
            set_schema(&mut dispenser, option::extract(&mut schema), ctx);
        };

        // fill randomness if the dispenser is not sequential
        if(!is_sequential) { 
            fill_randomness(&mut dispenser, ctx); 
        };
        
        ownership::initialize_owner_and_transfer_authority<SimpleTransfer>(&mut dispenser.id, owner, &auth);

        dispenser
    }

    /// Sets the schema of the dispenser item. aborts if schema is already set
    public fun set_schema(self: &mut DataDispenser, schema: vector<vector<u8>>, ctx: &mut TxContext) {
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), EInvalidAuth);
        assert!(vector::is_empty(&self.items), EDispenserAlreadyLoaded);
        assert!(option::is_none(&self.config.schema), ESchemaAlreadySet);

        option::fill(&mut self.config.schema, schema::create(schema));
    }

    /// Loads items or data into the dispenser
    public fun load(self: &mut DataDispenser, data: vector<vector<u8>>, ctx: &mut TxContext) {
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), EInvalidAuth);
        assert!(!vector::is_empty(&data), ELoadEmptyItems);

        let available_capacity = self.config.capacity - self.items_available;

        let (i, len) = (0, vector::length(&data));
        assert!(len <= available_capacity, EAvailableCapacityExceeded);

        while (i < len) {
            let value = vector::pop_back(&mut data);

            if(option::is_some(&self.config.schema)) {
                let schema = option::borrow(&self.config.schema);

                // validate the data being loaded into the dispenser against the set schema to ensure the data validity and integrity
                schema::validate(schema, value);
            } else {
                abort ESchemaNotSet
            };

            vector::push_back(&mut self.items, value);

            i = i + 1;
        };

        vector::destroy_empty(data);

        self.items_available = self.items_available + len;
    }

    /// Dispenses the dispenser items randomly after collecting the required payment from the transaction sender
    /// It uses the Sui randomness module to generate the random value
    public fun random_dispense(self: &mut DataDispenser, randomness: &mut Randomness<RANDOMNESS_WITNESS>, signature: vector<u8>, ctx: &mut TxContext): vector<u8> {
        assert!(!self.config.is_sequential, EInvalidDispenserType);
        assert!(option::is_some(&self.randomness_id), EMissingRandomness);
        assert!(option::borrow(&self.randomness_id) == object::borrow_id(randomness), ERandomnessMismatch);
        assert!(self.items_available != 0, EDispenserEmpty);

        // set the randomness signature which is generated from the client
        randomness::set(randomness, signature);
        let random_bytes = option::borrow(randomness::value(randomness));

        // select a random number based on the number items available. 
        // the selected random number is the index of the item to be dispensed
        let index = randomness::safe_selection((self.items_available), random_bytes);

        // randomness objects can only be set and consumed once, so we extract the previous randomess and fill it with a new one
        refill_randomness(self, ctx);

        self.items_available = self.items_available - 1;

        // swap the item at the index with the last item and pops it, so the items order is not preserved. 
        // this is ideal because it's O(1) and order preservation is not disired because the selection is random
        vector::swap_remove(&mut self.items, index)
    }

    /// Dispenses the dispenser items sequentially after collecting the required payment from the transaction sender
    public fun sequential_dispense(self: &mut DataDispenser): vector<u8> {
        assert!(self.config.is_sequential, EInvalidDispenserType);
        assert!(self.items_available != 0, EDispenserEmpty);

        self.items_available = self.items_available - 1;

        // pops the last item in the vector (corresponds to the original first item). items order is preserved.
        vector::pop_back(&mut self.items)
    }

    /// Makes the dispenser a shared object
    public fun publish(self: DataDispenser) {
        transfer::share_object(self);
    }

    /// Returns the mutable reference of the dispenser id
    public fun extend(self: &mut DataDispenser, ctx: &mut TxContext): &mut UID {
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), EInvalidAuth);

        &mut self.id
    }

    // ========== Helper Functions ==========

    fun fill_randomness(self: &mut DataDispenser, ctx: &mut TxContext) {
        let randomness = randomness::new(RANDOMNESS_WITNESS {}, ctx);
        let randomness_id = object::id(&randomness);

        option::fill(&mut self.randomness_id, randomness_id);
        randomness::share_object(randomness);
    }

    fun refill_randomness(self: &mut DataDispenser, ctx: &mut TxContext) {
        option::extract(&mut self.randomness_id);
        fill_randomness(self, ctx);
    }
}


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
    #[expected_failure(abort_code = dispenser::data_dispenser::ELoadEmptyItems)]
    fun test_empty_dispenser_data_failure() {
        let scenario = initialize_scenario(option::some(vector[b"String"]));

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, vector::empty());
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::data_dispenser::EInvalidAuth)]
    fun test_invalid_dispenser_owner_failure() {
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
    #[expected_failure(abort_code = dispenser::data_dispenser::ESchemaNotSet)]
    fun test_unset_dispenser_schema_failure() {
        let scenario = initialize_scenario(option::none());
        let data = get_dispenser_test_data();

        {
            let dispenser = test_scenario::take_shared<DataDispenser>(&scenario);

            load_dispenser(&mut scenario, &mut dispenser, data);
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
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
            test_scenario::next_tx(&mut scenario, ADMIN);
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
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        test_scenario::end(scenario);
    }
}