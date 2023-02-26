/// Data dispenser
/// 
/// Dispenser for data creation and distribution on the Sui network.

module dispenser::dispenser {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::randomness::{Self, Randomness};
    use sui::event::emit;

    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use dispenser::schema::{Self, Schema};


    // ========== Storage structs ==========

    struct Dispenser<phantom T> has key {
        id: UID,
        /// Number of available items in the dispenser
        available_items: u64,
        /// Number of loaded items, including dispensed items
        loaded_items: u64,
        /// Vector of available items; bcs encoded
        items: vector<vector<u8>>, 
        /// ID of the randomness object, if dispenser is non sequential 
        randomness_id: Option<ID>,
        /// Dispenser configuration
        config: DispenserConfig, 

        // there is ownership metadata which is be attached to this object by the capsule's ownership package
        // this enables us to make the dispenser accessible to everyone but still owned
    }

    struct DispenserConfig has store {
        /// Capacity of the dispenser i.e maximum number of items the dispenser can hold
        capacity: u64,
        /// Indicates whether items are dispensed sequentially or not
        is_sequential: bool,
        /// Indicates whether the dispenser can be reloaded after fully loaded or not
        is_reloadable: bool,
        /// Schema of the items the dispenser should hold
        schema: Option<Schema>
    }


    // ========= Event structs ==========

    struct DispenserCreated has copy, drop {
        id: ID,
        owner: address
    }

    struct DispenserLoaded has copy, drop {
        id: ID,
        items_count: u64
    }

    struct ItemDispensed has copy, drop {
        id: ID,
        item: vector<u8>
    }


    // ========== Witness structs =========

    struct RANDOMNESS_WITNESS has drop {}
    struct Witness has drop {}


    // ========== Error constants ==========

    const EInvalidAuth: u64 = 0;
    const ELoadEmptyItems: u64 = 1;
    const ECapacityExceeded: u64 = 2;
    const ESchemaNotSet: u64 = 3;
    const EDispenserEmpty: u64 = 4;
    const EInvalidDispenserType: u64 = 5;
    const ERandomnessMismatch: u64 = 6;
    const EMissingRandomness: u64 = 7;
    const ESchemaAlreadySet: u64 = 8;

    // ========== Public functions ==========
    
    /// Initializes the dispenser and returns it by value
    public fun initialize<T: drop>(
        witness: &T,
        owner: Option<address>,
        capacity: u64,
        is_sequential: bool,
        is_reloadable: bool, 
        schema: Option<vector<vector<u8>>>,
        ctx: &mut TxContext
    ): Dispenser<T> {
        let dispenser = Dispenser<T> {
            id: object::new(ctx),
            available_items: 0, 
            loaded_items: 0,
            items: vector::empty(),
            randomness_id: option::none(),
            config: DispenserConfig {
                capacity,
                is_sequential,
                is_reloadable,
                schema: option::none(),
            }
        };

        let owner = if(option::is_some(&owner)) option::extract(&mut owner) else tx_context::sender(ctx);
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        let proof = ownership::setup(&dispenser);

        // initialize the dispenser ownership, using the capsule standard
        ownership::initialize(&mut dispenser.id, proof, &auth);

        // set the dispenser data schema if provided
        if(option::is_some(&schema)) {
            set_schema(&mut dispenser, witness, option::extract(&mut schema), ctx);
        };

        // fill randomness if the dispenser is not sequential
        if(!is_sequential) { 
            fill_randomness(&mut dispenser, ctx); 
        };
        
        ownership::initialize_owner_and_transfer_authority<SimpleTransfer>(&mut dispenser.id, owner, &auth);

        emit(DispenserCreated {
            id: object::id(&dispenser),
            owner
        });

        dispenser
    }

    /// Sets the schema of the dispenser item. aborts if schema is already set
    public fun set_schema<T>(
        self: &mut Dispenser<T>, 
        _witness: &T, 
        schema: vector<vector<u8>>, 
        ctx: &mut TxContext
    ) {
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), EInvalidAuth);
        assert!(option::is_none(&self.config.schema), ESchemaAlreadySet);

        option::fill(&mut self.config.schema, schema::create(schema));
    }

    /// Loads items into the dispenser
    public fun load<T>(
        self: &mut Dispenser<T>, 
        _witness: &T, 
        items: vector<vector<u8>>, 
        ctx: &mut TxContext
    ) {
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), EInvalidAuth);
        assert!(!vector::is_empty(&items), ELoadEmptyItems);
        assert!((option::is_some(&self.config.schema)), ESchemaNotSet);

        let (i, items_count) = (0, vector::length(&items));

        if(!self.config.is_reloadable) {
            // assert that the number of loaded items is less than the dispenser capacity
            assert!(self.loaded_items < self.config.capacity, ECapacityExceeded);

            // assert that the number of loaded items combined with the items to be loaded does not exceed the dispenser capacity
            assert!(self.loaded_items + items_count <= self.config.capacity, ECapacityExceeded);
        };

        let available_capacity = self.config.capacity - self.available_items;
        assert!(items_count <= available_capacity, ECapacityExceeded);

        while (i < items_count) {
            let value = vector::pop_back(&mut items);
            let schema = option::borrow(&self.config.schema);

            // validate the items being loaded into the dispenser against the set schema to 
            // ensure the items validity and integrity
            schema::validate(schema, value);
            vector::push_back(&mut self.items, value);

            i = i + 1;
        };

        vector::destroy_empty(items);

        self.loaded_items = self.loaded_items + items_count;
        self.available_items = self.available_items + items_count;

        emit(DispenserLoaded {
             id: object::id(self),
            items_count
        });
    }

    /// Dispenses the dispenser items randomly after collecting the required payment from the transaction sender
    /// It uses the Sui randomness module to generate the random value
    public fun random_dispense<T>(
        self: &mut Dispenser<T>,
        _witness: &T,
        randomness: &mut Randomness<RANDOMNESS_WITNESS>,
        signature: vector<u8>,
        ctx: &mut TxContext
    ): vector<u8> {
        assert!(!self.config.is_sequential, EInvalidDispenserType);
        assert!(option::is_some(&self.randomness_id), EMissingRandomness);
        assert!(option::borrow(&self.randomness_id) == object::borrow_id(randomness), ERandomnessMismatch);
        assert!(self.available_items != 0, EDispenserEmpty);

        // set the randomness signature which is generated from the client
        randomness::set(randomness, signature);
        let random_bytes = option::borrow(randomness::value(randomness));

        // select a random number based on the number items available. 
        // the selected random number is the index of the item to be dispensed
        let index = randomness::safe_selection((self.available_items), random_bytes);

        // randomness objects can only be set and consumed once, so we extract the previous randomess and fill it with a new one
        refill_randomness(self, ctx);

        self.available_items = self.available_items - 1;

        // swap the item at the index with the last item and pops it, so the items order is not preserved. 
        // this is ideal because it's O(1) and order preservation is not disired because the selection is random
        let item = vector::swap_remove(&mut self.items, index);
        
        emit(ItemDispensed {
             id: object::id(self),
            item
        });

        item
    }

    /// Dispenses the dispenser items sequentially after collecting the required payment from the transaction sender
    public fun sequential_dispense<T>(self: &mut Dispenser<T>, _witness: &T): vector<u8> {
        assert!(self.config.is_sequential, EInvalidDispenserType);
        assert!(self.available_items != 0, EDispenserEmpty);

        self.available_items = self.available_items - 1;

        // pops the last item in the vector (corresponds to the original first item). items order is preserved.
        let item = vector::pop_back(&mut self.items);
        
        emit(ItemDispensed {
             id: object::id(self),
            item
        });

        item
    }

    /// Makes the dispenser a shared object
    public fun publish<T>(self: Dispenser<T>) {
        transfer::share_object(self);
    }

    /// Returns the mutable reference of the dispenser id
    public fun extend<T>(self: &mut Dispenser<T>, _witness: &T, ctx: &mut TxContext): &mut UID {
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), EInvalidAuth);

        &mut self.id
    }

    // ========== Helper Functions ==========

    fun fill_randomness<T>(self: &mut Dispenser<T>, ctx: &mut TxContext) {
        let randomness = randomness::new(RANDOMNESS_WITNESS {}, ctx);
        let randomness_id = object::id(&randomness);

        option::fill(&mut self.randomness_id, randomness_id);
        randomness::share_object(randomness);
    }

    fun refill_randomness<T>(self: &mut Dispenser<T>, ctx: &mut TxContext) {
        option::extract(&mut self.randomness_id);
        fill_randomness(self, ctx);
    }
}
