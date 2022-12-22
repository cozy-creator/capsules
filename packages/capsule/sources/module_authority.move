module capsule::module_authority {
    use std::string::String;
    use std::option::{Self, Option};
    use sui::object::UID;
    use sui::dynamic_field;
    use sui_utils::encode;
    
    // Error constants
    const ENO_AUTHORITY: u64 = 0;

    struct Key has store, copy, drop {}

    // Note that modules can bind authority to a witness type without actually being able to produce
    // that witness type; this effectively allows modules to create objects, and then 'delegate' the
    // authority of that object to another module entirely 
    public fun bind<World: drop>(id: &mut UID) {
        dynamic_field::add(id, Key {}, encode::type_name<World>());
    }

    public fun unbind<World: drop>(_witness: World, id: &mut UID) {
        assert!(is_valid<World>(id), ENO_AUTHORITY);

        dynamic_field::remove<Key, String>(id, Key {});
    }

    public fun into_witness_type(id: &UID): Option<String> {
        if (dynamic_field::exists_(id, Key {})) {
            option::some(*dynamic_field::borrow<Key, String>(id, Key {}))
        } else {
            option::none()
        }
    }

    // Returns false if no module is bound
    public fun is_valid<World: drop>(id: &UID): bool {
        let module_maybe = into_witness_type(id);

        if (option::is_none(&module_maybe)) { 
            false
        } else {
            encode::type_name<World>() == option::destroy_some(module_maybe)
        }
    }
}