module dispenser::dispenser {
    use std::vector;
    use std::type_name;
    use std::ascii::string;
    use std::option::{Self, Option};

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::transfer;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use sui_utils::typed_id;
    use sui_utils::rand;

    use dispenser::schema::{Self, Schema};


    // ========== Storage structs ==========

    struct Dispenser<phantom T> has key, store {
        id: UID,
        /// The address of the package that originated or created this dispenser
        origin: address,
        /// The dispenser configuration information
        config: Config,
        /// The number of items available in the dispenser
        items_count: u64,
        /// Schema used to validate every items if the `is_serialized` config is set to `true`
        schema: Option<Schema>

        // There's an `ownership::ownership::Key { }` attached to the dispenser. 
        // This contains the information about the ownership, module authority of the dispenser.

        // The items of the dispenser are attached the dispenser with a `dispenser::dispenser::Key { slot: u64 }` key
    }

    struct Config has store, copy, drop {
        /// Indicates whether the dispenser items are serialized (BCS encoded)
        is_serialized: bool,
        /// Indicates whether the dispenser should dispense sequentially or randmomly
        is_sequential: bool,
        /// Maximum number of items that can be loaded into the dispenser
        maximum_capacity: u64,
    }

    // key used to store a given item in the dispenser
    struct Key has store, copy, drop { slot: u64 }

    // ========== Witness structs =========
    struct Witness has drop {}


    // ========== Error constants ==========

    const EINVALID_OWNER_AUTH: u64 = 0;
    const EINVALID_MODULE_AUTH: u64 = 1;
    const ELOAD_EMPTY_ITEMS: u64 = 2;
    const ECAPACITY_EXCEEDED: u64 = 3;
    const ESCHEMA_NOT_SET: u64 = 4;
    const EDISPENSER_EMPTY: u64 = 5;
    const ESCHEMA_ALREADY_SET: u64 = 6;
    const EDISPENSER_TYPE_MISMATCH: u64 = 7;
    const EMAXIMUM_CAPACITY_EXCEEDED: u64 = 8;

    // ========== Public functions ==========

    public fun create<W: drop, T: copy + store + drop>(
        witness: &W,
        owner_maybe: Option<address>,
        maximum_capacity: u64,
        is_serialized: bool,
        is_sequential: bool,
        schema_maybe: Option<vector<vector<u8>>>,
        ctx: &mut TxContext
    ) {
        let dispenser = create_<W, T>(witness, owner_maybe, maximum_capacity, is_serialized, is_sequential, schema_maybe, ctx);
        transfer::share_object(dispenser)
    }
    
    /// Creates the dispenser and returns it by value
    public fun create_<W: drop, T: copy + store + drop>(
        _witness: &W,
        owner_maybe: Option<address>,
        maximum_capacity: u64,
        is_serialized: bool,
        is_sequential: bool,
        schema_maybe: Option<vector<vector<u8>>>,
        ctx: &mut TxContext
    ): Dispenser<T> {
        let origin = tx_authority::type_into_address<W>();

        let dispenser = Dispenser {
            id: object::new(ctx),
            origin,
            items_count: 0,
            schema: option::none(),
            config: Config {
                is_serialized,
                is_sequential,
                maximum_capacity,
            }
        };

        let owner = if(option::is_some(&owner_maybe)) {
            option::destroy_some(owner_maybe)
        } else {
            tx_context::sender(ctx)
        };

        let typed_id = typed_id::new(&dispenser);
        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        ownership::as_shared_object_(&mut dispenser.id, typed_id, vector[owner], vector::empty(), &auth);

        if(is_serialized) {
            assert!(type_name::into_string(type_name::get<T>()) == string(b"vector<u8>"), 0);
            assert!(option::is_some(&schema_maybe), 0);

            set_schema(&mut dispenser, option::destroy_some(schema_maybe), &auth);
        };

        dispenser
    }

    public fun load_serialized(self: &mut Dispenser<vector<u8>>, items: vector<vector<u8>>, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(self.config.is_serialized, EDISPENSER_TYPE_MISMATCH);
        assert!(option::is_some(&self.schema), ESCHEMA_NOT_SET);
        assert!(!vector::is_empty(&items), ELOAD_EMPTY_ITEMS);

        let schema = option::borrow(&self.schema);
        let (i, len) = (0, vector::length(&items));
        let items_count = self.items_count + len;

        assert!(items_count <= self.config.maximum_capacity, EMAXIMUM_CAPACITY_EXCEEDED);

        while (i < len) {
            let item = vector::pop_back(&mut items);
            schema::validate(schema, item);
            dynamic_field::add<Key, vector<u8>>(&mut self.id, Key { slot: i }, item);

            i = i + 1;
        };
     
        self.items_count = items_count;
    }

    public fun load<T: copy + store + drop>(self: &mut Dispenser<T>, items: vector<T>, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(!self.config.is_serialized, EDISPENSER_TYPE_MISMATCH);
        assert!(!vector::is_empty(&items), ELOAD_EMPTY_ITEMS);

        let (i, len) = (0, vector::length(&items));
        let items_count = self.items_count + len;

        assert!(items_count <= self.config.maximum_capacity, EMAXIMUM_CAPACITY_EXCEEDED);

        while (i < items_count) {
            let item = vector::pop_back(&mut items);
            dynamic_field::add<Key, T>(&mut self.id, Key { slot: i }, item);

            i = i + 1;
        };

        self.items_count =  items_count;
    }

    public fun dispense<W: drop, T: copy + store + drop>(self: &mut Dispenser<T>, _witness: &W, ctx: &mut TxContext): T {
        assert!(tx_authority::type_into_address<W>() == self.origin, EINVALID_MODULE_AUTH);

        if(self.config.is_sequential) {
            self.items_count = self.items_count - 1;
            dynamic_field::remove<Key, T>(&mut self.id, Key { slot: self.items_count })
        } else {
            let slot = rand::rng(0, self.items_count, ctx);
            self.items_count = self.items_count - 1;

            let selected_item = dynamic_field::remove<Key, T>(&mut self.id, Key { slot });

            // replace the selected item with the last item
            let last_item = dynamic_field::remove<Key, T>(&mut self.id, Key { slot: self.items_count });
            dynamic_field::add<Key, T>(&mut self.id, Key { slot }, last_item);

            selected_item
        }
    }

    /// Returns the mutable reference of the dispenser id
    public fun extend<T>(self: &mut Dispenser<T>, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);

        &mut self.id
    }

    /// Sets the schema of the dispenser item. aborts if schema is already set
    fun set_schema<T>(self: &mut Dispenser<T>, schema: vector<vector<u8>>, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), EINVALID_OWNER_AUTH);
        assert!(option::is_none(&self.schema), ESCHEMA_ALREADY_SET);

        option::fill(&mut self.schema, schema::create(schema));
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
    #[expected_failure(abort_code = dispenser::dispenser::ELOAD_EMPTY_ITEMS)]
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
    fun test_dispenser_maximum_capacity_failure() {
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