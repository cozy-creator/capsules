// Capsule dispenser module
// Dispenser for objects creation and distribution on the Sui network.

module dispenser::dispenser {
    use std::vector;
    use std::option::{Self, Option};
    use std::type_name;
    use std::ascii;

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::address;
    use sui::hex;
    use sui::transfer;
    use sui::randomness::{Self, Randomness};

    use dispenser::schema::{Self, Schema};

    struct Dispenser has key {
        id: UID,
        module_id: ID,
        balance: Balance<SUI>,
        total_dispensed: u64,
        items: vector<vector<u8>>,
        config: Config,
        randomness_id: Option<ID>
    }

    struct Config has store {
        payment: u64,
        total_dispensable: u64,
        is_sequential: bool,
        schema: Option<Schema>
    }

    struct AdminCap has key {
        id: UID,
        dispenser_id: ID,
    }

    struct Key has store, drop {
        slot: vector<u8>
    }
    
    struct RANDOMNESS_WITNESS has drop {}

    const EDispenserMismatch: u64 = 0;
    const ELoadEmptyItems: u64 = 1;
    const EDispenserAlreadLoaded: u64 = 2;
    const EInvalidItemsCount: u64 = 3;
    const EInvalidData: u64 = 5;
    const ESchemaNotFound: u64 = 6;
    const EDispenserEmpty: u64 = 7;

    public fun initialize<W: drop>(_: W, admin: Option<address>, payment: u64, total_dispensable: u64, is_sequential: bool, schema: Option<vector<vector<u8>>>, ctx: &mut TxContext): Dispenser {
        let module_id = extract_module_id<W>();
        let (dispenser, admin_cap) = initialize_(module_id, payment, total_dispensable, is_sequential, schema, ctx);

        if(!is_sequential) {
            fill_randomness(&mut dispenser, ctx);
        };

        if(option::is_some(&admin)) {
            transfer::transfer(admin_cap, option::extract(&mut admin));
        } else {
            transfer::transfer(admin_cap, tx_context::sender(ctx));
        };

        dispenser
    }

    public fun initialize_(module_id: ID, payment: u64, total_dispensable: u64, is_sequential: bool, schema: Option<vector<vector<u8>>>, ctx: &mut TxContext): (Dispenser, AdminCap) {
        let schema = if (option::is_some(&schema)) {
            let schema = schema::create(option::extract(&mut schema));
            option::some(schema)
        } else {
            option::none<Schema>()
        };

        let dispenser = Dispenser {
            id: object::new(ctx),
            balance: balance::zero(),
            total_dispensed: 0,
            items: vector::empty(),
            randomness_id: option::none(),
            module_id,
            config: Config {
                payment,
                is_sequential,
                schema,
                total_dispensable,
            }
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
            dispenser_id: object::id(&dispenser)
        };

        (dispenser, admin_cap)
    }

    public fun set_schema(self: &mut Dispenser, admin_cap: &AdminCap, schema: vector<vector<u8>>) {
        assert!(object::id(self) == admin_cap.dispenser_id, EDispenserMismatch);
        
        self.config.schema = option::some(schema::create(schema));
    }

    public fun load_data(self: &mut Dispenser, admin_cap: &AdminCap, data: vector<vector<u8>>, _ctx: &mut TxContext) {
        assert!(object::id(self) == admin_cap.dispenser_id, EDispenserMismatch);
        assert!(!vector::is_empty(&data), ELoadEmptyItems);

        let (i, len) = (0, vector::length(&data));
        assert!(len == self.config.total_dispensable, EInvalidItemsCount);

        while (i < len) {
            let value = vector::pop_back(&mut data);

            if(option::is_some(&self.config.schema)) {
                let schema = option::borrow(&self.config.schema);
                schema::validate(schema, value);
            } else {
                abort ESchemaNotFound
            };

            vector::push_back(&mut self.items, value);

            i = i + 1;
        };

        vector::destroy_empty(data);
    }

    public fun random_dispense(self: &mut Dispenser, randomness: &mut Randomness<RANDOMNESS_WITNESS>, coins: vector<Coin<SUI>>, sig: vector<u8>, ctx: &mut TxContext): vector<u8> {
        assert!(!self.config.is_sequential, 229);
        assert!(option::is_some(&self.randomness_id), 230);
        assert!(option::borrow(&self.randomness_id) == object::borrow_id(randomness), 231);

        let payment = collect_payment(coins, self.config.payment, ctx);
        balance::join(&mut self.balance, coin::into_balance(payment));

        let available = self.config.total_dispensable - self.total_dispensed;
        assert!(available != 0, EDispenserEmpty);

        randomness::set(randomness, sig);
        let random_bytes = option::borrow(randomness::value(randomness));
        let index = randomness::safe_selection((available), random_bytes);

        self.total_dispensed = self.total_dispensed + 1;

        refill_randomness(self, ctx);

        vector::swap_remove(&mut self.items, index)
    }

    public fun sequential_dispense(self: &mut Dispenser, coins: vector<Coin<SUI>>, ctx: &mut TxContext): vector<u8> {
        assert!(self.config.is_sequential, 228);

        let payment = collect_payment(coins, self.config.payment, ctx);
        balance::join(&mut self.balance, coin::into_balance(payment));

        let available = self.config.total_dispensable - self.total_dispensed;
        assert!(available != 0, EDispenserEmpty);

        self.total_dispensed = self.total_dispensed + 1;
        vector::pop_back(&mut self.items)
    }

    public fun withdraw_payment(self: &mut Dispenser, admin_cap: &AdminCap, amount: u64, recipient: Option<address>, ctx: &mut TxContext) {
        assert!(object::id(self) == admin_cap.dispenser_id, EDispenserMismatch);

        let coin = coin::take(&mut self.balance, amount, ctx);

        let recipient = if(option::is_some(&recipient)) {
            option::extract(&mut recipient)
        } else {
            tx_context::sender(ctx)
        };

        transfer::transfer(coin, recipient);
    }

    public fun publish(self: Dispenser) {
        transfer::share_object(self);
    }

    public fun extend(self: &mut Dispenser, admin_cap: &AdminCap): &mut UID {
        assert!(object::id(self) == admin_cap.dispenser_id, EDispenserMismatch);

        &mut self.id
    }

    fun fill_randomness(self: &mut Dispenser, ctx: &mut TxContext) {
        let randomness = randomness::new(RANDOMNESS_WITNESS {}, ctx);
        let randomness_id = object::id(&randomness);

        option::fill(&mut self.randomness_id, randomness_id);
        randomness::share_object(randomness);
    }

    fun refill_randomness(self: &mut Dispenser, ctx: &mut TxContext) {
        option::extract(&mut self.randomness_id);
        fill_randomness(self, ctx);
    }

    fun extract_module_id<W: drop>(): ID {
        let type_address = type_name::get_address(&type_name::get<W>());
        let decoded = hex::decode(ascii::into_bytes(type_address));
        let address_bytes = address::from_bytes(decoded);

        object::id_from_address(address_bytes)
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