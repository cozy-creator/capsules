// The concept behind this is to provide a wrapper on top of dynamic field that enforces a schema
// I'm not sure if this is necessary; this might get axed

module attachment::attach {
    use sui::dynamic_field;

    struct SchemaVersion<T> {};
    struct Key<T> has store, copy, drop { key: T }

    public fun set<T: store + copy + drop, Value: store>(id: &mut UID, key: T, value: Value, schema: &Schema) {
        assert!(is_correct_schema<T>(id, schema), EINCORRECT_SCHEMA);
        assert!(schema::is_valid<T, Value>(schema, key), EINVALID_VALUE);

        let key = Key<T> { key };
        if (dynamic_field::exists_(id, key)) {
            dynamic_field::remove<Key, Value>(id, key);
        };

        dynamic_field::add(id, key, value);
    }

    public fun remove<T: store + copy + drop, Value: store>(id: &mut UID, key: T): Value {
        dynamic_field::remove<Key, Value>(id, Key<T> { key });
    }

    public fun borrow() {}

    public fun borrow_mut() {}

    public fun exists() {}

    public fun is_correct_schema<T>(id: &UID, schema: &Schema): bool {
        let schema_id = dynamc_field::borrow<SchemaVersion<T>, ID>(id, SchemaVersion<T> {});
        *schema_id == object::id(schema)
    }
}