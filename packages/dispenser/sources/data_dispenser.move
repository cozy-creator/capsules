// Data dispenser module
// Dispenser for data creation and distribution on the Sui network.

module dispenser::data_dispenser {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::randomness::{Self, Randomness};

    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use dispenser::schema::{Self, Schema};

    struct DataDispenser has key {
        id: UID,
        items_available: u64, // the number of items available
        balance: Balance<SUI>,
        items: vector<vector<u8>>, 
        randomness_id: Option<ID>, // id of the randomness object which will be used to select item for non sequential dispenser
        config: Config,
    }

    struct Config has store {
        payment: u64,   // payment required to dispense an item
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

    fun new(payment: u64, capacity: u64, is_sequential: bool, schema: Option<Schema>, ctx: &mut TxContext): DataDispenser {
         DataDispenser {
            id: object::new(ctx),
            balance: balance::zero(),
            items_available: 0, 
            items: vector::empty(),
            randomness_id: option::none(),
            config: Config {
                payment,
                is_sequential,
                schema,
                capacity,
            }
        }
    }

    /// Initializes the dispenser and returns it by value
    public fun initialize(owner: Option<address>, payment: u64, capacity: u64, is_sequential: bool, schema: Option<vector<vector<u8>>>, ctx: &mut TxContext): DataDispenser {
        let dispenser = new(payment, capacity, is_sequential, option::none(), ctx);

        // declare dispenser owner, uses the transaction sender if it's not passed in an argument
        let owner = if(option::is_some(&owner)) {
            option::extract(&mut owner) 
        } else {
            tx_context::sender(ctx)
        };

        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        let proof = ownership::setup(&dispenser);

        // initialize the dispenser ownership, using the capsule standard
        ownership::initialize(&mut dispenser.id, proof, &auth);
        ownership::initialize_owner_and_transfer_authority<SimpleTransfer>(&mut dispenser.id, owner, &auth);

        // set the dispenser data schema if provided
        if(option::is_some(&schema)) {
            set_schema(&mut dispenser, option::extract(&mut schema), ctx);
        };

        // fill randomness if the dispenser is not sequential
        if(!is_sequential) { 
            fill_randomness(&mut dispenser, ctx); 
        };

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
    public fun random_dispense(self: &mut DataDispenser, randomness: &mut Randomness<RANDOMNESS_WITNESS>, coins: vector<Coin<SUI>>, signature: vector<u8>, ctx: &mut TxContext): vector<u8> {
        assert!(!self.config.is_sequential, EInvalidDispenserType);
        assert!(option::is_some(&self.randomness_id), EMissingRandomness);
        assert!(option::borrow(&self.randomness_id) == object::borrow_id(randomness), ERandomnessMismatch);
        assert!(self.items_available != 0, EDispenserEmpty);

        let payment = collect_payment(coins, self.config.payment, ctx);
        balance::join(&mut self.balance, coin::into_balance(payment));

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
    public fun sequential_dispense(self: &mut DataDispenser, coins: vector<Coin<SUI>>, ctx: &mut TxContext): vector<u8> {
        assert!(self.config.is_sequential, EInvalidDispenserType);
        assert!(self.items_available != 0, EDispenserEmpty);

        let payment = collect_payment(coins, self.config.payment, ctx);
        balance::join(&mut self.balance, coin::into_balance(payment));

        self.items_available = self.items_available - 1;

        // pops the last item in the vector (corresponds to the original first item). items order is preserved.
        vector::pop_back(&mut self.items)
    }

    /// Takes an amount from payment made to the dispenser and transfers it to the recipient
    /// If recipient is not provided, it's transfered to the transaction sender
    public fun withdraw(self: &mut DataDispenser, amount: u64, recipient: Option<address>, ctx: &mut TxContext) {
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), EInvalidAuth);

        let coin = coin::take(&mut self.balance, amount, ctx);

        let recipient = if (option::is_some(&recipient)) 
            option::extract(&mut recipient)  
            else  tx_context::sender(ctx);

        transfer::transfer(coin, recipient);
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

    fun collect_payment(coins: vector<Coin<SUI>>, amount: u64, ctx: &mut TxContext): Coin<SUI> {
        let coin = vector::pop_back(&mut coins);

        let (i, len) = (0, vector::length(&coins));
        while(i < len) {
            coin::join(&mut coin, vector::pop_back(&mut coins));
            i = i + 1;
        };
        vector::destroy_empty(coins);

        let payment = coin::split(&mut coin, amount, ctx);

        if(coin::value(&coin) == 0) {
            coin::destroy_zero(coin);
        } else {
            transfer::transfer(coin, tx_context::sender(ctx));
        };

        payment
    }
}