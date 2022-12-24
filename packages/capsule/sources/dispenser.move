module capsule::dispenser {
    use std::string::String;
    use std::vector;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use metadata::schema::Schema;

    // error codes
    const EITEM_AND_ATTRIBUTE_STACK_SIZE_MISMATCH: u64 = 0;

    // Stores objects to be dispensed later
    struct Dispenser has key, store {
        id: UID
    }

    struct Store<T> {
        item: T,
        attributes: vector<vector<u8>>
    }

    struct Key has store, copy, drop { type: String }

    public entry fun create(ctx: &mut TxContext) {
        transfer::transfer(create_(ctx), tx_context::sender(ctx));
    }

    public fun create_(ctx: &mut TxContext): Dispenser {
        Dispenser { id: object::new(ctx) }
    }

    public entry fun batch_load<T: store>(dispenser: &mut Dispenser, items: vector<T>, attribute_stack: vector<vector<vector<u8>>>, schema: &Schema) {
        assert!(vector::length(&items) == vector::length(&attribute_stack), EITEM_AND_ATTRIBUTE_STACK_SIZE_MISMATCH);

        let i = 0;
        while (vector::length(&attribute_stack) > 0) {
            let item = vector::remove(&mut items, i);
            let attributes = vector::remove(&mut attribute_stack, i);
            load(dispenser, item, attributes, schema);
        };
    }

    public entry fun load<T: store>(dispenser: &mut Dispenser, item: T, attributes: vector<vector<u8>>, schema: &Schema) {
        // TO DO: validate schema versus attributes
        let type = encode::type_name<T>();

        // If a stack for this type doesn't already exist, create one
        if (!dynamic_field::exists_(&dispenser.id, Key { type })) {
            dynamic_field::add(&mut dispenser.id, Key { type }, vector::empty<Store<T>>());
        };

        let store_stack = dynamic_field::borrow_mut(&mut dispenser.id, Key { type });
        vector::push_back(store_stack, Store { item, attributes });
    }

    public fun unload<T: store>() {

    }
}