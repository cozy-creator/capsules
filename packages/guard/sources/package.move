/// Package guard
/// 
/// This guard can be used to restrict thirdparty packages call to your module functions. 
/// It leverages the witness pattern to ensure that a package calling a module function is allowed.
/// 
/// ```move
/// let guard = guard::initialize<Witness>(&Witness {}, ctx);
/// 
/// // create package guard by passing the allowed package witness
/// package::create<Witness, AllowedPackageWitness>(&mut guard);
/// 
/// // create package guard by passing the allowed package id
/// package::create_<Witness>(&mut guard, allowed_package_id);
/// 
/// // validate a the package calling a function is allowed
/// package::validate<Witness, ThirdPartyPackageWitness>(&guard);
/// ```


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

    /// Creates a new package guard using allowed package witness `W`
    public fun create<T, W>(guard: &mut Guard<T>) {
        let id = encode::package_id<W>();
        create_(guard, id);
    }

    /// Creates a new package guard using the allowed package id
    public fun create_<T>(guard: &mut Guard<T>, id: ID) {
        let package = Package {
            value: id
        };

        let key = guard::key(PACKAGE_GUARD_ID);
        let uid = guard::extend(guard);

        dynamic_field::add<Key, Package>(uid, key, package)
    }

    /// Validates that the package witness `W` against the guard type `T`
    public fun validate<T, W>(guard: &Guard<T>) {
        let key = guard::key(PACKAGE_GUARD_ID);
        let uid = guard::uid(guard);
        
        let id = encode::package_id<W>();

        assert!(dynamic_field::exists_with_type<Key, Package>(uid, key), EKeyNotSet);
        let package = dynamic_field::borrow<Key, Package>(uid, key);

        assert!(package.value == id, EInvalidPackage)
    }

   /// Updates the package guard with a new allowed package witness `W`
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