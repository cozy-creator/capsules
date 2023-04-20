module serializer::attach {
    use std::vector;
    use std::option;
    use std::string::{String};
    
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;

    use attach::data;
    use ownership::tx_authority;

    struct TestObject has key {
        id: UID
    }

    struct Witness has drop {}

    public fun create_object(ctx: &mut TxContext) {
        let object = TestObject { id: object::new(ctx) };
        transfer::share_object(object)
    }

    public entry fun set_field(obj: &mut TestObject, key: String, value: vector<u8>, _ctx: &mut TxContext) {
        let w = Witness {};
        data::set(w, &mut obj.id, vector::singleton(key), vector::singleton(value))
    }

    public entry fun set_fields(obj: &mut TestObject, keys: vector<String>, values: vector<vector<u8>>, _ctx: &mut TxContext) {
        let w = Witness {};
        data::set(w, &mut obj.id, keys, values)
    }

    public fun view(obj: &TestObject, keys: vector<String>): vector<u8> {
        data::view(&obj.id, option::some(tx_authority::type_into_address<Witness>()), keys)
    }

    public fun view_all(obj: &TestObject): vector<u8> {
        data::view_all(&obj.id, option::some(tx_authority::type_into_address<Witness>()))
    }

    public fun view_parsed(obj: &TestObject, keys: vector<String>): vector<vector<u8>> {
        data::view_parsed(&obj.id, option::some(tx_authority::type_into_address<Witness>()), keys)
    }

}