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

    const EKeyNotSet: u64 = 0;
    const EInvalidPackage: u64 = 1;

    public fun create<T, W: drop>(guard: &mut Guard<T>) {
        let addr_string = type_name::get_address(&type_name::get<W>());
        let id = object::id_from_bytes(ascii::into_bytes(addr_string));

        create_(guard, id);
    }

    public fun create_<T>(guard: &mut Guard<T>, id: ID) {
        let package = Package {
            value: id
        };

        let key = guard::key(PACKAGE_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Package>(uid, key, package)
    }

    public fun validate<T, W: drop>(guard: &Guard<T>) {
        let key = guard::key(PACKAGE_GUARD_ID);
        let uid = guard::uid(guard);

        assert!(dynamic_field::exists_with_type<Key, Package>(uid, key), EKeyNotSet);
        let package = dynamic_field::borrow<Key, Package>(uid, key);


        let addr_string = type_name::get_address(&type_name::get<W>());
        let id = object::id_from_bytes(ascii::into_bytes(addr_string));

        assert!(package.value == id, EInvalidPackage)
    }
}