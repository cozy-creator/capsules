module capsule::dispenser {
    use sui::object::UID;

    // Stores objects to be dispensed later
    struct Dispenser has key, store {
        id: UID
    }
}