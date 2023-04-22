module serializer::attach {
    use std::vector;
    use std::option;
    use std::string::{String};
    
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::transfer;
    use sui::bcs;

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

    public entry fun deserialize_set_field(obj: &mut TestObject, key: String, type: String, value: vector<u8>, _ctx: &mut TxContext) {
        let w = Witness {};
        data::deserialize_and_set(w, &mut obj.id, vector::singleton(value), vector::singleton(vector[key, type]))
    }

    public entry fun set_field<T: copy + store + drop>(obj: &mut TestObject, key: String, value: T, _ctx: &mut TxContext) {
        let w = Witness {};
        data::set(w, &mut obj.id, vector::singleton(key), vector::singleton(value))
    }

    public entry fun remove_field(obj: &mut TestObject, key: String, _ctx: &mut TxContext) {
        let w = Witness {};
        data::remove(w, &mut obj.id, vector::singleton(key))
    }

    public fun view_all(obj: &TestObject): vector<u8> {
        data::view_all(&obj.id, option::some(tx_authority::type_into_address<Witness>()))
    }

    public fun view_parsed(obj: &TestObject, keys: vector<String>): vector<vector<u8>> {
        data::view_parsed(&obj.id, option::some(tx_authority::type_into_address<Witness>()), keys)
    }

    public fun serialize(): vector<u8> {
        bcs::to_bytes<u8>(&50)
    }
}