// Bind a witness authority to an object. Useful for building custom APIs in your own module.
// For example, if you bind 0x59::module_name::Witness, 0x59::module_name can now construct Witness {} and pass it to
// make privileged calls over this object.

module capsule::witness_authority {
    use std::string::String;
    use std::option::{Self, Option};
    use sui::object::UID;
    use sui::dynamic_field;
    use sui_utils::encode;
    
    // Error constants
    const ENO_AUTHORITY: u64 = 0;

    struct Key has store, copy, drop {}

    // Note that in order to call this, you needn't be able to construct a `Witness` yourself. This allows modules to
    // delegate control to other modules.
    public fun bind<Witness: drop>(id: &mut UID) {
        dynamic_field::add(id, Key {}, encode::type_name<Witness>());
    }

    public fun unbind<Witness: drop>(_witness: Witness, id: &mut UID) {
        assert!(is_valid<Witness>(id), ENO_AUTHORITY);

        dynamic_field::remove<Key, String>(id, Key {});
    }

    public fun into_type(id: &UID): Option<String> {
        if (dynamic_field::exists_(id, Key {})) {
            option::some(*dynamic_field::borrow<Key, String>(id, Key {}))
        } else {
            option::none()
        }
    }

    // Returns false if no module is bound
    public fun is_valid<Witness: drop>(id: &UID): bool {
        let module_maybe = into_type(id);

        if (option::is_none(&module_maybe)) { 
            false
        } else {
            encode::type_name<Witness>() == option::destroy_some(module_maybe)
        }
    }
}