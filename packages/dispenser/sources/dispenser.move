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
    use sui::dynamic_field;
    use sui::transfer;

    // use ownership::ownership;
    // use ownership::tx_authority::{Self, TxAuthority};

    // use sui_utils::typed_id;
    use sui_utils::rand;
    use sui_utils::counter::{Self, Counter};

    use dispenser::schema::{Self, Schema};

    // ========== Storage structs ==========


    struct Dispenser<phantom T, phantom C> has key {
        id: UID,
        /// Bag of items available in the dispenser.
        items: Bag,
        /// Price of each item in the dispenser.
        price: u64,
        /// Schema defining the structure of the items.
        schema: Schema,
        /// Time when the dispenser ends.
        end_time: u64,
        /// Time when the dispenser starts.
        start_time: u64,
        /// Flag indicating if the dispenser is active or not.
        is_active: bool,
        /// Flag indicating if the dispenser distributes items randomly or sequentially.
        is_random: bool,
        /// Total number of items in the dispenser.
        total_items: u64,
        /// Number of items currently loaded in the dispenser.
        items_loaded: u64,
        /// Optional configuration for the items.
        items_config: ItemsConfig,

        // There's an `ownership::ownership::Key { }` attached to the dispenser. 
        // This contains the information about the ownership, module authority of the dispenser.
    }

    struct ItemsConfig has copy, store, drop {
        /// Shared description of the items.
        description: String,
        /// Prefix for the URI of the items.
        uri_prefix: Option<String>,
        /// Prefix for the name of the items.
        name_prefix: Option<String>,
    }
 
    // ========== Witness structs =========
    struct Witness has drop {}
    struct Key has store, copy, drop { slot: vector<u8> }

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
    const EINVALID_START_TIME: u64 = 9;
    const EINVALID_END_TIME: u64 = 10;
    const EINVALID_PRICE: u64 = 11;
    const EINVALID_ITEM_TYPE: u64 = 12;
    const ESTART_TIME_NOT_REACHED: u64 = 13;
    const EEND_TIME_ELAPSED: u64 = 14;
    const EINSUFFICIENT_COIN_PAYMENT: u64 = 15;
    const EDISPENSER_PAUSED: u64 = 16;
    const EDISPENSER_NOT_PAUSED: u64 = 17;
    const EINSUFFICIENT_BALANCE: u64 = 18;

    const COUNTER_BYTES: vector<u8> = b"Counter";

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

        if(!is_sequential) {
            let key = Key { slot: COUNTER_BYTES };
            let counter = counter::new_<Witness>(Witness {}, ctx);
            dynamic_field::add<Key, Counter<Witness>>(&mut dispenser.id, key, counter)
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

    public fun withdraw<T, C>(self: &mut Dispenser<T, C>, amount: u64, ctx: &mut TxContext): Coin<C> {
        // assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(amount <= balance::value(&self.balance), EINSUFFICIENT_BALANCE);
        coin::take(&mut self.balance, amount, ctx)
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

    public fun balance<T, C>(self: &Dispenser<T, C>): u64 {
        balance::value(&self.balance)
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

        if(self.config.is_sequential) {
            let index = bag::length(&self.items) - 1;
            bag::remove<u64, T>(&mut self.items, index)
        } else {
            let last_index = bag::length(&self.items) - 1;
            let last_item = bag::remove<u64, T>(&mut self.items,  last_index);

            if(bag::is_empty(&self.items)) {
                last_item
            } else {
                let key = Key { slot: COUNTER_BYTES };
                let counter = dynamic_field::borrow_mut<Key, Counter<Witness>>(&mut self.id, key);
                let index = rand::rng_with_clock_and_counter(&Witness {}, 0, bag::length(&self.items), clock, counter, ctx);
                let selected_item = bag::remove<u64, T>(&mut self.items, index);

                bag::add<u64, T>(&mut self.items, index, last_item);
                selected_item
            }
        }
    }

}

#[test_only]
module dispenser::dispenser_test {
    use std::option::{Self, Option};
    use std::string::{String, utf8};
    use std::vector;

    use sui::test_scenario::{Self, Scenario};
    use sui::clock::{Self, Clock};
    use sui::bcs;

    // use ownership::tx_authority;

    use dispenser::dispenser::{Self, Dispenser, NOT_COIN};

    const ADMIN: address = @0xFAEC;

    struct Witness has drop {}

    struct DispenserData has copy, store, drop {
        value: String
    }

    fun create_dispenser<T: copy + store + drop, C>(
        scenario: &mut Scenario,
        clock: &Clock,
        price: Option<u64>,
        max_items: u64,
        start_time: Option<u64>,
        end_time: Option<u64>,
        owner_maybe: Option<address>,
        schema_maybe: Option<vector<vector<u8>>>,
        is_serialized: bool,
        is_sequential: bool
    ) {
        let ctx = test_scenario::ctx(scenario);
        if(option::is_some(&price)) {
            let dispenser = dispenser::create<T, C>(
                clock,
                option::destroy_some(price),
                max_items,
                start_time,
                end_time,
                owner_maybe,
                schema_maybe,
                is_serialized,
                is_sequential,
                ctx
            );

            dispenser::return_and_share(dispenser)
        } else {
            let dispenser = dispenser::create_<T>(
                clock,
                max_items,
                start_time,
                end_time,
                owner_maybe,
                schema_maybe,
                is_serialized,
                is_sequential,
                ctx
            );

            dispenser::return_and_share(dispenser)
        };
        
    }

    fun get_dispenser_serialized_items(): vector<vector<u8>> {
        vector[
            bcs::to_bytes(&b"Sui"), 
            bcs::to_bytes(&b"Move"), 
            bcs::to_bytes(&b"Capsule"), 
            bcs::to_bytes(&b"Object"), 
            bcs::to_bytes(&b"Metadata"),
        ]
    }

    fun get_dispenser_items(): vector<String> {
        vector[
            utf8(b"Sui"), 
            utf8(b"Move"), 
            utf8(b"Away"),
            utf8(b"Capsule"), 
            utf8(b"Heyye"),
            utf8(b"Object"), 
            utf8(b"Mesjjsjtadata"),
            utf8(b"Metadata"),
        ]
    }

    #[test]
    fun test_sequential_dispenser() {
        let scenario = test_scenario::begin(ADMIN);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        let (max, price, start, end, serialized, sequential) = (8, option::none(), option::none(), option::some(10), false, true);

        create_dispenser<DispenserData, NOT_COIN>(
            &mut scenario,
            &clock,
            price,
            max,
            start,
            end,
            option::none(),
            option::none(),
            serialized,
            sequential
        );

        test_scenario::next_tx(&mut scenario, ADMIN);
        
        let items = get_dispenser_items();

        {
            let dispenser = test_scenario::take_shared<Dispenser<DispenserData, NOT_COIN>>(&scenario);
            let _ctx = test_scenario::ctx(&mut scenario);
            // let auth = tx_authority::begin(ctx);

            let load_items = vector[];
            let (i, len) = (0, vector::length(&items));

            while(i < len) {
                let item = DispenserData { value: *vector::borrow(&items, i) };
                vector::push_back(&mut load_items, item);
                i = i + 1;
            };

            dispenser::load(&mut dispenser, load_items, /* &auth */);
            
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        };

        {
            let dispenser = test_scenario::take_shared<Dispenser<DispenserData, NOT_COIN>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let (i, len) = (0, vector::length(&items));

            while (i < len) {
                let item = dispenser::dispense_(&mut dispenser, &Witness {}, &clock, ctx);
                assert!(&item ==  &DispenserData { value: *vector::borrow(&items, i) }, 0);

                i = i + 1;
            };

            test_scenario::return_shared(dispenser);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_random_dispenser() {
        let scenario = test_scenario::begin(ADMIN);
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        let (max, price, start, end, serialized, sequential) = (8, option::none(), option::none(), option::some(10), false, false);

        create_dispenser<DispenserData, NOT_COIN>(
            &mut scenario,
            &clock,
            price,
            max,
            start,
            end,
            option::none(),
            option::none(),
            serialized,
            sequential
        );

        test_scenario::next_tx(&mut scenario, ADMIN);
        
        let items = get_dispenser_items();

        {
            let dispenser = test_scenario::take_shared<Dispenser<DispenserData, NOT_COIN>>(&scenario);
            let _ctx = test_scenario::ctx(&mut scenario);
            // let auth = tx_authority::begin(ctx);

            let load_items = vector[];
            let (i, len) = (0, vector::length(&items));

            while(i < len) {
                let item = DispenserData { value: *vector::borrow(&items, i) };
                vector::push_back(&mut load_items, item);
                i = i + 1;
            };

            dispenser::load(&mut dispenser, load_items, /* &auth */);
            
            test_scenario::return_shared(dispenser);
            test_scenario::next_tx(&mut scenario, ADMIN);
        };

        {
            let dispenser = test_scenario::take_shared<Dispenser<DispenserData, NOT_COIN>>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let (i, len) = (0, vector::length(&items));

            while (i < len) {
                clock::increment_for_testing(&mut clock, 1);

                let item = dispenser::dispense_(&mut dispenser, &Witness {}, &clock, ctx);
                std::debug::print(&item);
                // assert!(&item ==  &DispenserData { value: *vector::borrow(&items, i) }, 0);

                i = i + 1;
            };

            test_scenario::return_shared(dispenser);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // #[test]
    // fun test_serialized_sequential_dispenser() {
    //     let scenario = test_scenario::begin(ADMIN);
    //     create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
    //     test_scenario::next_tx(&mut scenario, ADMIN);

    //     let items = get_dispenser_serialized_items();

    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = tx_authority::begin(ctx);

    //         dispenser::load_serialized(&mut dispenser, items, &auth);
            
    //         test_scenario::return_shared(dispenser);
    //         test_scenario::next_tx(&mut scenario, ADMIN);
    //     } ;

    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let (i, len) = (0, vector::length(&items));

    //         while (i < len) {
    //             let item = dispenser::dispense(&mut dispenser, &Witness {}, ctx);
    //             assert!(&item == vector::borrow(&items, i), 0);

    //             i = i + 1;
    //         };

    //         test_scenario::return_shared(dispenser);
    //     };

    //     test_scenario::end(scenario);
    // }

    // #[test]
    // fun test_random_dispenser() {
    //     let scenario = test_scenario::begin(ADMIN);
    //     create_dispenser<vector<u8>>(&mut scenario, option::none(), true, false, option::some(vector[b"String"]));
    //     test_scenario::next_tx(&mut scenario, ADMIN);

    //     let items = get_dispenser_serialized_items();

    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = tx_authority::begin(ctx);

    //         dispenser::load_serialized(&mut dispenser, items, &auth);
            
    //         test_scenario::return_shared(dispenser);
    //         test_scenario::next_tx(&mut scenario, ADMIN);
    //     } ;

    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
    //         let _ctx = test_scenario::ctx(&mut scenario);
    //         let (i, len) = (0, vector::length(&items));

    //         while (i < len) {
    //             // let item = dispenser::dispense(&mut dispenser, Witness {}, ctx);
    //             // std::debug::print(&utf8(item));
    //             // assert!(&item == vector::borrow(&items, i), 0);

    //             i = i + 1;
    //         };

    //         test_scenario::return_shared(dispenser);
    //     };

    //     test_scenario::end(scenario);
    // }

    // #[test]
    // #[expected_failure(abort_code = dispenser::dispenser::EINVALID_OWNER_AUTH)]
    // fun test_invalid_dispenser_auth_failure() {
    //     let scenario = test_scenario::begin(ADMIN);
    //     create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
    //     test_scenario::next_tx(&mut scenario, @0xABCE);

    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);

    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = tx_authority::begin(ctx);
    //         let items = get_dispenser_serialized_items();

    //         dispenser::load_serialized(&mut dispenser, items, &auth);
    //         test_scenario::return_shared(dispenser);
    //     } ;

    //     test_scenario::end(scenario);
    // }

    // #[test]
    // #[expected_failure(abort_code = dispenser::dispenser::ECANNOT_LOAD_EMPTY_ITEMS)]
    // fun test_empty_dispenser_failure() {
    //     let scenario = test_scenario::begin(ADMIN);
    //     create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
    //     test_scenario::next_tx(&mut scenario, ADMIN);
        
    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = tx_authority::begin(ctx);

    //         dispenser::load_serialized(&mut dispenser, vector::empty(), &auth);
    //         test_scenario::return_shared(dispenser);
    //     } ;

    //     test_scenario::end(scenario);
    // }

    // #[test]
    // #[expected_failure(abort_code = dispenser::schema::EUNRECOGNIZED_TYPE)]
    // fun test_dispenser_unrecognized_type_failure() {
    //     let scenario = test_scenario::begin(ADMIN);
    //     create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"int8"]));
    //     test_scenario::next_tx(&mut scenario, ADMIN);
        
    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = tx_authority::begin(ctx);
    //         let items = get_dispenser_serialized_items();

    //         dispenser::load_serialized(&mut dispenser, items, &auth);
    //         test_scenario::return_shared(dispenser);
    //     } ;

    //     test_scenario::end(scenario);
    // }

    // #[test]
    // #[expected_failure(abort_code = dispenser::dispenser::EMAXIMUM_CAPACITY_EXCEEDED)]
    // fun test_dispenser_max_items_failure() {
    //     let scenario = test_scenario::begin(ADMIN);
    //     create_dispenser<vector<u8>>(&mut scenario, option::none(), true, true, option::some(vector[b"String"]));
    //     test_scenario::next_tx(&mut scenario, ADMIN);

    //     let items = get_dispenser_serialized_items();

    //     {
    //         let dispenser = test_scenario::take_shared<Dispenser<vector<u8>>>(&scenario);
    //         let ctx = test_scenario::ctx(&mut scenario);
    //         let auth = tx_authority::begin(ctx);

    //         vector::push_back(&mut items, bcs::to_bytes(&b"Test"));
    //         dispenser::load_serialized(&mut dispenser, items, &auth);
            
    //         test_scenario::return_shared(dispenser);
    //         test_scenario::next_tx(&mut scenario, ADMIN);
    //     } ;

    //     test_scenario::end(scenario);
    // }

}