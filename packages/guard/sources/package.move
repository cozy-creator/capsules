module guard::package {
    use sui::dynamic_field;
    use sui::object::ID;

    use sui_utils::encode;

    use guard::guard::{Self, Key, Guard};

    struct Package has store {
        value: ID
    }

    const PACKAGE_GUARD_ID: u64 = 3;

    const EKeyNotSet: u64 = 0;
    const EInvalidPackage: u64 = 1;

    public fun create<T, W>(guard: &mut Guard<T>) {
        let id = encode::package_id<W>();
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

    public fun validate<T, W>(guard: &Guard<T>) {
        let key = guard::key(PACKAGE_GUARD_ID);
        let uid = guard::uid(guard);
        
        let id = encode::package_id<W>();

        assert!(dynamic_field::exists_with_type<Key, Package>(uid, key), EKeyNotSet);
        let package = dynamic_field::borrow<Key, Package>(uid, key);

        assert!(package.value == id, EInvalidPackage)
    }

   public fun update<T, W>(guard: &mut Guard<T>) {
        let key = guard::key(PACKAGE_GUARD_ID);
        let uid = guard::extend(guard);
        
        let id = encode::package_id<W>();

        assert!(dynamic_field::exists_with_type<Key, Package>(uid, key), EKeyNotSet);
        let package = dynamic_field::borrow_mut<Key, Package>(uid, key);

        package.value = id;
    }
}


#[test_only]
module guard::package_test {
    use sui::test_scenario::{Self, Scenario};

    use guard::guard::Guard;
    use guard::package;

    use guard::guard_test;

    struct Witness has drop {}

    struct FakeWitness has drop {}


    fun initialize_scenario(sender: address): Scenario {
       let scenario = guard_test::initialize_scenario(&Witness {}, sender);      

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            package::create<Witness, Witness>(&mut guard);
            test_scenario::return_shared(guard);
        };

        scenario
    }

    #[test]
    fun test_validate_package() {
        let sender = @0xFEAC;
        let scenario = initialize_scenario(sender);

        test_scenario::next_tx(&mut scenario, sender);

        {
            let guard = test_scenario::take_shared<Guard<Witness>>(&scenario);
            package::validate<Witness, Witness>(&guard);
            test_scenario::return_shared(guard);
        };

        test_scenario::end(scenario);
    }
}