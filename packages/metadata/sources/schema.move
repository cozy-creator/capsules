module metadata::schema {
    use sui::object::UID;

    // Defines a mapping of slots (keys) to types. Used to validate inputs on write
    // Share object
    struct Schema has key, store {
        id: UID
    }

    // Define new schemas, update existing ones
}