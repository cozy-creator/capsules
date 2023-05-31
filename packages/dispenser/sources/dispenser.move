module dispenser::dispenser {
    use std::vector;
    use std::option;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::transfer;

    use ownership::ownership;
    use ownership::permission::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};

    use sui_utils::rand;
    use sui_utils::typed_id;

    use dispenser::schema::{Self, Schema};

    // ========== Storage structs ==========

    struct Dispenser<phantom C> has key {
        id: UID,
        /// The price of each item in the dispenser.
        price: u64,
        /// The time when the dispenser ends.
        end_time: u64,
        /// The time when the dispenser starts.
        start_time: u64,
        /// Flag indicating if the dispenser distributes items randomly or sequentially.
        is_random: bool,
        /// THe balance currently available in the dispenser.
        balance: Balance<C>,
        /// Total number of items in the dispenser.
        total_items: u64,
        /// Number of items currently loaded in the dispenser.
        items_loaded: u64,
        /// Table of items available in the dispenser.
        items: Table<u64, vector<u8>>,
        /// The schema defining the structure of the items.
        schema: Schema,
        
        // There's an `ownership::ownership::Key { }` attached to the dispenser. 
        // This contains the information about the ownership, module authority of the dispenser.
    }

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
    const EMAXIMUM_CAPACITY_EXCEEDED: u64 = 8;
    const EINVALID_START_TIME: u64 = 9;
    const EINVALID_END_TIME: u64 = 10;
    const EINVALID_PRICE: u64 = 11;
    const EINVALID_ITEM_TYPE: u64 = 12;
    const ESTART_TIME_NOT_REACHED: u64 = 13;
    const EEND_TIME_ELAPSED: u64 = 14;
    const EINSUFFICIENT_COIN_PAYMENT: u64 = 15;
    const EDISPENSER_NOT_PROPERLY_LOADED: u64 = 16;
    const EINSUFFICIENT_DISPENSER_BALANCE: u64 = 18;

    // ========== Public functions ==========

    public fun create_(
        owner:address,
        end_time:u64,
        start_time:u64,
        total_items: u64,
        is_random: bool,
        schema:vector<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Dispenser<NOT_COIN> {
        create<NOT_COIN>(owner, 0u64, end_time, start_time, total_items, is_random, schema, clock, ctx)
    }

    public fun create<C>(
        owner:address,
        price: u64,
        end_time:u64,
        start_time:u64,
        total_items: u64,
        is_random: bool,
        schema:vector<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Dispenser<C> {
        let current_time = clock::timestamp_ms(clock);
        let schema = schema::create(schema);

        if(start_time != 0u64) { assert!(start_time >= current_time, EINVALID_START_TIME) };
        if(end_time != 0u64) { assert!(current_time < end_time, EINVALID_START_TIME) };

        let dispenser = Dispenser {
            id: object::new(ctx),
            price,
            schema,
            end_time,
            is_random,
            start_time,
            total_items,
            items_loaded: 0,
            items: table::new(ctx),
            balance: balance::zero()
        };

        let tid = typed_id::new(&dispenser);
        let auth = tx_authority::begin_with_package_witness(Witness {});
        ownership::as_shared_object_(&mut dispenser.id, tid, owner, owner, &auth);

        dispenser
    }

    public fun load_items<C>(
        self: &mut Dispenser<C>,
        items: vector<vector<u8>>,
        auth: &TxAuthority
    ) {
        assert!(ownership::has_owner_permission<ADMIN>(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(!vector::is_empty(&items), ECANNOT_LOAD_EMPTY_ITEMS);

        let (i, length) = (0, vector::length(&items));

        let total_loaded = self.items_loaded + length;
        assert!(total_loaded <= self.total_items, EMAXIMUM_CAPACITY_EXCEEDED);

        while (i < length) {
            let item = vector::pop_back(&mut items);
            schema::validate(&self.schema, item);

            let idx = table::length(&self.items);
            table::add(&mut self.items, idx, item);

            i = i + 1;
        };

        self.items_loaded = total_loaded;
    }

    public fun dispense_free_item(
        self: &mut Dispenser<NOT_COIN>,
        clock: &Clock,
        ctx: &mut TxContext
    ): (u64, vector<u8>) {
        dispense_internal(self, clock, ctx)
    }

    public fun dispense_item<C>(
        self: &mut Dispenser<C>,
        coin: Coin<C>,
        clock: &Clock,
        ctx: &mut TxContext
    ): (u64, vector<u8>) {
        assert!(coin::value(&coin) >= self.price, EINSUFFICIENT_COIN_PAYMENT);

        let payment = coin::split(&mut coin, self.price, ctx);
        balance::join(&mut self.balance, coin::into_balance(payment));

        destroy_or_return_coin(coin, ctx);
        dispense_internal(self, clock, ctx)
    }

    public fun return_and_share<C>(self: Dispenser<C>) {
        transfer::share_object(self)
    }

    public fun transfer_ownership<C>(
        self: &mut Dispenser<C>,
        new_owner: address,
        auth: &TxAuthority,
    ) {
        ownership::transfer(&mut self.id, option::some(new_owner), auth);
    }

    public fun withdraw_coin<C>(
        self: &mut Dispenser<C>,
        amount: u64,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Coin<C> {
        assert!(ownership::has_owner_permission<ADMIN>(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(amount <= balance::value(&self.balance), EINSUFFICIENT_DISPENSER_BALANCE);

        coin::take(&mut self.balance, amount, ctx)
    }


    // ========== Public view functions ==========

    public fun balance<C>(self: &Dispenser<C>): u64 {
        balance::value(&self.balance)
    }


    // ========== Internal helper functions ==========

    fun destroy_or_return_coin<C>(coin: Coin<C>, ctx: &mut TxContext) {
        if(coin::value(&coin) == 0){
            coin::destroy_zero(coin)
        } else {
            transfer::public_transfer(coin, tx_context::sender(ctx))
        }
    }

    fun dispense_internal<C>(
        self: &mut Dispenser<C>,
        clock: &Clock,
        ctx: &mut TxContext
    ): (u64, vector<u8>) {
        assert!(self.total_items == self.items_loaded, EDISPENSER_NOT_PROPERLY_LOADED);

        let current_time = clock::timestamp_ms(clock);
        if(self.start_time != 0u64) { assert!(current_time >= self.start_time, ESTART_TIME_NOT_REACHED) };
        if(self.end_time != 0u64) { assert!(current_time < self.end_time, EEND_TIME_ELAPSED) };

        let index = table::length(&self.items) - 1;
        let item = table::remove(&mut self.items, index);

        if(self.is_random && !table::is_empty(&self.items)) {
            index = rand::rng_with_clock(0, table::length(&self.items), clock, ctx);
            item = table::remove(&mut self.items, index);
            table::add(&mut self.items, index, item);
        };

        (index, item)
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
            let dispenser = dispenser::create<C>(
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