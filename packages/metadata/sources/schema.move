// Note that we cannnot overload slots in our schema specifications; i.e., a slot cannot have two possible value types.
// It's either the specified type or it doesn't exist. Move is not generic enough to deal with figuring out types at runtime

module metadata::schema {
    use sui::object::UID;

    // Defines a mapping of slots (keys) to types. Used to validate inputs on write
    // Share object
    struct Schema has key, store {
        id: UID
    }

    // Define new schemas, update existing ones

    // Check validity of schema
    public fun is_valid<Key: store + copy + drop, Value: store>(schema: &Schema, key: &Key): bool {

    }
}