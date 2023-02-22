module guard::package {
    use std::type_name;
    use std::ascii;

    use sui::dynamic_field;
    use sui::object::{Self, ID};

    use guard::guard::{Self, Key, Guard};

    struct Package has store {
        value: ID
    }

    const PACKAGE_GUARD_ID: u64 = 3;

    fun new(value: ID): Package {
        Package { value }
    }

    public fun set<W: drop>(guard: &mut Guard) {
        let addr_string = type_name::get_address(&type_name::get<W>());
        let package = Package {
            value: object::id_from_bytes(ascii::into_bytes(addr_string))
        };

        let key = guard::key(PACKAGE_LIST_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Package>(uid, key, package);
    }

    public fun validate<W: drop>(guard: &Guard) {
        let key = guard::key(PACKAGE_LIST_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Package>(uid, key), 0);
        let package = dynamic_field::borrow<Key, Package>(uid, key);


        let addr_string = type_name::get_address(&type_name::get<W>());
        let id = object::id_from_bytes(ascii::into_bytes(addr_string));

        assert!(package.value == id, 0)
    }  
}