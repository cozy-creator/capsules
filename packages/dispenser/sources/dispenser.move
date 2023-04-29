module dispenser::dispenser {
    use std::vector;
    use std::type_name;
    use std::ascii::string;
    use std::option::{Self, Option};

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::bag::{Self, Bag};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::transfer;

    // use ownership::ownership;
    // use ownership::tx_authority::{Self, TxAuthority};

    // use sui_utils::typed_id;
    use sui_utils::rand;

    use dispenser::schema::{Self, Schema};


    // ========== Storage structs ==========

    struct Dispenser<phantom T, phantom C> has key {
        id: UID,
        /// `Bag` that holds the items available the dispenser
        items: Bag,
        /// The total number of items that have been loaded into the dispenser
        items_loaded: u64,
        /// The balance of coin `C` collected when an item is dispensed
        balance: Balance<C>,
        /// The dispenser configuration, determines how the dispenser behaves
        config: DispenserConfig,

        // There's an `ownership::ownership::Key { }` attached to the dispenser. 
        // This contains the information about the ownership, module authority of the dispenser.
    }

    struct DispenserConfig has copy, store {
        /// The price or cost of dispensing each item
        price: u64,
        /// The maximum number of items that can be loaded into the dispenser
        max_items: u64,
        /// Indicates whether the dispenser is paused or not
        is_paused: bool,
        /// Indicates whether the dispenser items are serialized using BCS encoding
        is_serialized: bool,
        /// Indicates whether the dispenser should dispense items in a sequential or random order
        is_sequential: bool,
        /// The schema is used to validate each item if items are serialized
        schema: Option<Schema>,
        /// The time from which the dispenser should start dispensing items
        start_time: Option<u64>,
        /// The time from which the dispenser should stop dispensing items
        end_time: Option<u64>,
    }
 
    // ========== Witness structs =========
    struct Witness has drop {}
    struct NOT_COIN {}


    // ========== Error constants ==========

    const EINVALID_OWNER_AUTH: u64 = 0;
    const EINVALID_MODULE_AUTH: u64 = 1;
    const ECANNOT_LOAD_EMPTY_ITEMS: u64 = 2;
    const ECAPACITY_EXCEEDED: u64 = 3;
    const ESCHEMA_NOT_SET: u64 = 4;
    const EDISPENSER_EMPTY: u64 = 5;
    const ESCHEMA_ALREADY_SET: u64 = 6;
    const EINVALID_DISPENSER_SERIALIZATION: u64 = 7;
    const EMAXIMUM_CAPACITY_EXCEEDED: u64 = 8;
    const EINVALID_START_TIME: u64 = 0;
    const EINVALID_END_TIME: u64 = 0;
    const EINVALID_PRICE: u64 = 0;
    const EINVALID_ITEM_TYPE: u64 = 0;
    const ESTART_TIME_NOT_REACHED: u64 = 0;
    const EEND_TIME_ELAPSED: u64 = 0;
    const EINSUFFICIENT_COIN_PAYMENT: u64 = 0;
    const EDISPENSER_PAUSED: u64 = 0;
    const EDISPENSER_NOT_PAUSED: u64 = 0;

    // ========== Public functions ==========

    public fun create_<T: copy + store + drop>(
        clock: &Clock,
        max_items: u64,
        start_time: Option<u64>,
        end_time: Option<u64>,
        owner_maybe: Option<address>,
        schema_maybe: Option<vector<vector<u8>>>,
        is_serialized: bool,
        is_sequential: bool,
        ctx: &mut TxContext
    ): Dispenser<T, NOT_COIN> {
        let price = 0;

        create<T, NOT_COIN>(
            clock,
            price,
            max_items,
            start_time,
            end_time,
            owner_maybe,
            schema_maybe,
            is_serialized,
            is_sequential,
            ctx
        )
    }

    public fun create<T: copy + store + drop, C>(
        clock: &Clock,
        price: u64,
        max_items: u64,
        start_time: Option<u64>,
        end_time: Option<u64>,
        owner_maybe: Option<address>,
        schema_maybe: Option<vector<vector<u8>>>,
        is_serialized: bool,
        is_sequential: bool,
        ctx: &mut TxContext
    ): Dispenser<T, C> {
        let now = clock::timestamp_ms(clock);

        if(type_name::get<C>() == type_name::get<NOT_COIN>()) {
            assert!(price == 0, EINVALID_PRICE);
        };

        if(option::is_some(&start_time)) {
            assert!(*option::borrow(&start_time) >= now, EINVALID_START_TIME);

            if(option::is_some(&end_time)) {
                assert!(*option::borrow(&end_time) > *option::borrow(&start_time), EINVALID_END_TIME);
            };
        };

        let dispenser = Dispenser {
            id: object::new(ctx),
            items: bag::new(ctx),
            balance: balance::zero<C>(),
            items_loaded: 0,
            config: DispenserConfig {
                price,
                end_time,
                max_items,
                start_time,
                is_serialized,
                is_sequential,
                is_paused: false,
                schema: option::none(),
            }
        };

        let _owner = if(option::is_some(&owner_maybe)) {
          option::destroy_some(owner_maybe)
        } else {
            tx_context::sender(ctx)
        };

        // let typed_id = typed_id::new(&dispenser);
        // let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        // ownership::as_shared_object_(&mut dispenser.id, typed_id, vector[owner], vector::empty(), &auth);

        if(is_serialized) {
            assert!(type_name::into_string(type_name::get<T>()) == string(b"vector<u8>"), EINVALID_ITEM_TYPE);
            assert!(option::is_some(&schema_maybe), 0);

            set_schema(&mut dispenser, option::destroy_some(schema_maybe), /* &auth */);
        };

        dispenser
    }

    public fun return_and_share<T, C>(self: Dispenser<T, C>) {
        transfer::share_object(self)
    }

    public fun load_<C>(self: &mut Dispenser<vector<u8>, C>, items: vector<vector<u8>>, /* auth: &TxAuthority */) {
        // assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(!vector::is_empty(&items), ECANNOT_LOAD_EMPTY_ITEMS);
        assert!(self.config.is_serialized, EINVALID_DISPENSER_SERIALIZATION);
        assert!(option::is_some(&self.config.schema), ESCHEMA_NOT_SET);

        let (i, len) = (0, vector::length(&items));
        let items_loaded = self.items_loaded + len;
        let schema = option::borrow(&self.config.schema);

        assert!(items_loaded <= self.config.max_items, EMAXIMUM_CAPACITY_EXCEEDED);

        while (i < len) {
            let item = vector::pop_back(&mut items);
            schema::validate(schema, item);

            let index = bag::length(&self.items);
            bag::add(&mut self.items, index, item);

            i = i + 1;
        };
     
        self.items_loaded = items_loaded;
    }

    public fun load<T: copy + store + drop, C>(self: &mut Dispenser<T, C>, items: vector<T>, /* auth: &TxAuthority */) {
        // assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(!vector::is_empty(&items), ECANNOT_LOAD_EMPTY_ITEMS);
        assert!(!self.config.is_serialized, EINVALID_DISPENSER_SERIALIZATION);

        let (i, len) = (0, vector::length(&items));
        let items_loaded = self.items_loaded + len;

        assert!(items_loaded <= self.config.max_items, EMAXIMUM_CAPACITY_EXCEEDED);

        while (i < len) {
            let item = vector::pop_back(&mut items);
            let index = bag::length(&self.items);

            bag::add(&mut self.items, index, item);

            i = i + 1;
        };

        self.items_loaded = items_loaded;
    }

    public fun dispense_<W: drop, T: copy + store + drop>(
        self: &mut Dispenser<T, NOT_COIN>,
        witness: &W,
        clock: &Clock,
        ctx: &mut TxContext
    ): T {
        dispense_internal(self, witness, clock, ctx)
    }

    public fun dispense<W: drop, T: copy + store + drop, C>(
        self: &mut Dispenser<T, C>,
        witness: &W,
        clock: &Clock,
        coin: Coin<C>,
        ctx: &mut TxContext
    ): T {
        let coin_value = coin::value(&coin);
        assert!(coin_value >= self.config.price, EINSUFFICIENT_COIN_PAYMENT);

        let payment = if(coin_value > self.config.price) {
            let payment = coin::split(&mut coin, self.config.price, ctx);
            transfer::public_transfer(coin, tx_context::sender(ctx));
            payment
        } else {
            coin
        };

        balance::join(&mut self.balance, coin::into_balance(payment));
        dispense_internal(self, witness, clock, ctx)
    }
    
    public fun set_schema<T, C>(self: &mut Dispenser<T, C>, schema: vector<vector<u8>>, /* auth: &TxAuthority */) {
        // assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(option::is_none(&self.config.schema), ESCHEMA_ALREADY_SET);

        option::fill(&mut self.config.schema, schema::create(schema));
    }

    public fun resume<T, C>(self: &mut Dispenser<T, C>, /* auth: &TxAuthority */) {
        // assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(self.config.is_paused, EDISPENSER_NOT_PAUSED);

        self.config.is_paused = false
    }

    public fun pause<T, C>(self: &mut Dispenser<T, C>, /* auth: &TxAuthority */) {
        // assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(!self.config.is_paused, EDISPENSER_PAUSED);

        self.config.is_paused = true
    }

    public fun extend<T, C>(self: &mut Dispenser<T, C>, /* auth: &TxAuthority */): &mut UID {
        // assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        &mut self.id
    }


    fun dispense_internal<W: drop, T: copy + store + drop, C>(
        self: &mut Dispenser<T, C>,
        _witness: &W,
        clock: &Clock,
        ctx: &mut TxContext
    ): T {
        // TODO: verify module auth when the ownership module is properly working
        assert!(!self.config.is_paused, EDISPENSER_PAUSED);

        let now = clock::timestamp_ms(clock);

        if(option::is_some(&self.config.start_time)) {
            assert!(now >= *option::borrow(&self.config.start_time), ESTART_TIME_NOT_REACHED)
        };

        if(option::is_some(&self.config.end_time)) {
            assert!(now <= *option::borrow(&self.config.end_time), EEND_TIME_ELAPSED)
        };

        let total_available = bag::length(&self.items); 
        if(self.config.is_sequential) {
            let index = total_available - 1;
            bag::remove<u64, T>(&mut self.items, index)
        } else {
            let index = rand::rng(0, total_available, ctx);
            let selected_item = bag::remove<u64, T>(&mut self.items, index);

            // // replace the selected item with the last item
            let last_item = bag::remove<u64, T>(&mut self.items, total_available - 1);
            bag::add<u64, T>(&mut self.items, index, last_item);

            selected_item
        }
    }

}

#[test_only]
module dispenser::dispenser_test {
    use std::option::{Self, Option};
    use std::string::{String, utf8};
    use std::vector;

    use sui::test_scenario::{Self, Scenario};
    use sui::bcs;

    use ownership::tx_authority;

    use dispenser::dispenser::{Self, Dispenser};

    const ADMIN: address = @0xFAEC;

    struct Witness has drop {}

    struct DispenserData has copy, store, drop {
        value: String
    }

    fun create_dispenser<T: copy + store + drop>(
        scenario: &mut Scenario,
        owner: Option<address>,
        is_serialized: bool,
        is_sequential: bool,
        schema: Option<vector<vector<u8>>>
    ) {
        let ctx = test_scenario::ctx(scenario);
        dispenser::create<Witness, T>(&Witness { },owner, 5, is_serialized, is_sequential, schema, ctx);
    }

    fun get_dispenser_serialized_items(): vector<vector<u8>> {
        vector[
            bcs::to_bytes(&b"Sui"), 
            bcs::to_bytes(&b"Move"), 
            bcs::to_bytes(&b"Capsule"), 
            bcs::to_bytes(&b"Object"), 
            bcs::to_bytes(&b"Metadata")
        ]
    }

    fun get_dispenser_items(): vector<String> {
        vector[
            utf8(b"Sui"), 
            utf8(b"Move"), 
            utf8(b"Capsule"), 
            utf8(b"Object"), 
            utf8(b"Metadata")
        ]
    }


    #[test]
    fun test_sequential_dispenser() {
        let scenario = test_scenario::begin(ADMIN);
        create_dispenser<DispenserData>(&mut scenario, option::none(), false, true, option::none());
        test_scenario::next_tx(&mut scenario, ADMIN);
        
        let items = get_dispenser_items();

        {
            let dispenser = test_scenario::take_shared<Dispenser<DispenserData>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            let load_items = vector[];
            let (i, len) = (0, vector::length(&items));

            while(i < len) {
                let item = DispenserData { value: vector::pop_back(&mut items) };
                vector::push_back(&mut load_items, item);
                i = i + 1;
            };

            dispenser::load(&mut dispenser, load_items, &auth);
            
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        {
            let dispenser = test_scenario::take_shared<Dispenser<DispenserData>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let (i, len) = (0, vector::length(&items));

            while (i < len) {
                let item = dispenser::dispense(&mut dispenser, &Witness {}, ctx);
                assert!(&item ==  &DispenserData { value: *vector::borrow(&items, i) }, 0);

                i = i + 1;
            };

            test_scenario::return_shared(dispenser);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_serialized_sequential_dispenser() {
        let scenario = test_scenario::begin(ADMIN);
        create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
        test_scenario::next_tx(&mut scenario, ADMIN);

        let items = get_dispenser_serialized_items();

        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            dispenser::load_serialized(&mut dispenser, items, &auth);
            
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let (i, len) = (0, vector::length(&items));

            while (i < len) {
                let item = dispenser::dispense(&mut dispenser, &Witness {}, ctx);
                assert!(&item == vector::borrow(&items, i), 0);

                i = i + 1;
            };

            test_scenario::return_shared(dispenser);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_random_dispenser() {
        let scenario = test_scenario::begin(ADMIN);
        create_dispenser<vector<u8>>(&mut scenario, option::none(), true, false, option::some(vector[b"String"]));
        test_scenario::next_tx(&mut scenario, ADMIN);

        let items = get_dispenser_serialized_items();

        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            dispenser::load_serialized(&mut dispenser, items, &auth);
            
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
            let _ctx = test_scenario::ctx(&mut scenario);
            let (i, len) = (0, vector::length(&items));

            while (i < len) {
                // let item = dispenser::dispense(&mut dispenser, Witness {}, ctx);
                // std::debug::print(&utf8(item));
                // assert!(&item == vector::borrow(&items, i), 0);

                i = i + 1;
            };

            test_scenario::return_shared(dispenser);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::dispenser::EINVALID_OWNER_AUTH)]
    fun test_invalid_dispenser_auth_failure() {
        let scenario = test_scenario::begin(ADMIN);
        create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
        test_scenario::next_tx(&mut scenario, @0xABCE);

        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);

            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let items = get_dispenser_serialized_items();

            dispenser::load_serialized(&mut dispenser, items, &auth);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::dispenser::ECANNOT_LOAD_EMPTY_ITEMS)]
    fun test_empty_dispenser_failure() {
        let scenario = test_scenario::begin(ADMIN);
        create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
        test_scenario::next_tx(&mut scenario, ADMIN);
        
        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            dispenser::load_serialized(&mut dispenser, vector::empty(), &auth);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::schema::EUNRECOGNIZED_TYPE)]
    fun test_dispenser_unrecognized_type_failure() {
        let scenario = test_scenario::begin(ADMIN);
        create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"int8"]));
        test_scenario::next_tx(&mut scenario, ADMIN);
        
        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);
            let items = get_dispenser_serialized_items();

            dispenser::load_serialized(&mut dispenser, items, &auth);
            test_scenario::return_shared(dispenser);
        } ;

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = dispenser::dispenser::EMAXIMUM_CAPACITY_EXCEEDED)]
    fun test_dispenser_max_items_failure() {
        let scenario = test_scenario::begin(ADMIN);
        create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
        test_scenario::next_tx(&mut scenario, ADMIN);

        let items = get_dispenser_serialized_items();

        {
            let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::begin(ctx);

            vector::push_back(&mut items, bcs::to_bytes(&b"Test"));
            dispenser::load_serialized(&mut dispenser, items, &auth);
            
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        } ;

        test_scenario::end(scenario);
    }

}