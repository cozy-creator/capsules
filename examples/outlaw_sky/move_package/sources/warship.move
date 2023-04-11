module outlaw_sky::warship {
    use sui::object::UID;
    
    struct Warship has key {
        id: UID
    }

    struct Witness has drop {}
}