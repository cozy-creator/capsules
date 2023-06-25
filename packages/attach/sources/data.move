// ========== Sui's Data-Attaching System ==========
//
// This allows you to:
// (1) attach supported data-types to arbitrary objects using dynamic fields
// (2) deserialize data; clients can send objects as bytes and we deserialize + store on-chain
// (3) serialize data; clients can request objects stored on-chain, and we serialize + return them,
// we call these 'view functions'.
// (4) We keep track of data by using storing a Schema inside the object iself; this allows data
// be enumerated, copied, and deleted without the calling-app having to remember keys + types
// (5) We manage access to data using a namespace system. Any module can read from any other module's
// namespace, but can only write to their own.
//
// In order to use this system, you'll need `&mut UID` for the object. This means native-modules
// can always write to their objects, in any namespace they control, but foreign-modules require
// ownership-authority to obtain `&mut UID` from the native module.
//
// For the empty namespace ()`Key { namespace: option::none(), key: Any }`) any module with access
// to `&mut UID` can to write to any key.

module attach::data {
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::vector;

    use sui::dynamic_field;
    use sui::object::{UID, ID};

    use sui_utils::dynamic_field2;
    use sui_utils::encode;

    use ownership::tx_authority::{Self, TxAuthority};

    use attach::schema;
    use attach::serializer;

    // Error enums
    const ENO_NAMESPACE_AUTHORITY: u64 = 0;
    const EINCORRECT_DATA_LENGTH: u64 = 1;
    const EKEY_DOES_NOT_EXIST_ON_SCHEMA: u64 = 2;
    const EUNRECOGNIZED_TYPE: u64 = 3;

    // Key used to store data on an object for a given namespace + key
    struct Key has store, copy, drop { namespace: Option<ID>, key: String }

    // Action types
    struct WRITE {}

    // Convenience function using a Witness pattern. 'witness' is the Namespace, and must have
    // struct-name `Witness`
    public fun set<Namespace, T: store + copy + drop>(
        uid: &mut UID,
        keys: vector<String>,
        values: vector<T>,
        auth: &TxAuthority
    ) {
        let namespace_addr = encode::package_id<Namespace>();
        set_(uid, option::some(namespace_addr), keys, values, auth);
    }

    // Because of the ergonomics of Sui, all values added must be the same Type. If you have to add mixed types,
    // like u64's and Strings, that will require two separate calls.
    // This will abort if `T` is not supported by the schema system.
    public fun set_<T: store + drop>(
        uid: &mut UID,
        namespace: Option<ID>,
        keys: vector<String>,
        values: vector<T>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_package_opt<WRITE>(namespace, auth), ENO_NAMESPACE_AUTHORITY);
        assert!(vector::length(&keys) == vector::length(&values), EINCORRECT_DATA_LENGTH);

        let type = schema::simple_type_name<T>();
        let old_types_to_drop = schema::update_object_schema_(uid, namespace, keys, type);

        while (vector::length(&keys) > 0) {
            let key = vector::pop_back(&mut keys);
            let value = vector::pop_back(&mut values);
            let old_type = vector::pop_back(&mut old_types_to_drop);

            serializer::set_field_(uid, Key { namespace, key }, type, old_type, value, true);
        };
    }

    // Convenience function using a Witness pattern. 'witness' is the Namespace
    public fun deserialize_and_set<Namespace>(
        uid: &mut UID,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        let namespace_addr = encode::package_id<Namespace>();
        deserialize_and_set_(uid, option::some(namespace_addr), data, fields, auth);
    }

    // This is a powerful function that allows client applications to serialize arbitrary objects
    // (that consist of supported primitive types), submit them as a transaction, then deserialize +
    // attach all fields to an arbitrary object with a single function call. This is part of our Sui ORM
    // system.
    public fun deserialize_and_set_(
        uid: &mut UID,
        namespace: Option<ID>,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_package_opt<WRITE>(namespace, auth), ENO_NAMESPACE_AUTHORITY);
        assert!(vector::length(&data) == vector::length(&fields), EINCORRECT_DATA_LENGTH);
        
        let old_types_to_drop = schema::update_object_schema(uid, namespace, fields);

        let i = 0;
        while (i < vector::length(&fields)) {
            let field = *vector::borrow(&fields, i);
            let value = *vector::borrow(&data, i);
            let (key, type) = schema::parse_field(field);
            let old_type = *vector::borrow(&old_types_to_drop, i);

            serializer::set_field(uid, Key { namespace, key }, type, old_type, value, true);
            i = i + 1;
        };
    }

    // Convenience function using a Witness pattern. 'witness' is the Namespace
    public fun remove<Namespace>(
        uid: &mut UID,
        keys: vector<String>,
        auth: &TxAuthority
    ) {
        let namespace_addr = encode::package_id<Namespace>();
        remove_(uid, option::some(namespace_addr), keys, auth);
    }

    public fun remove_(
        uid: &mut UID,
        namespace: Option<ID>,
        keys: vector<String>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_package_opt<WRITE>(namespace, auth), ENO_NAMESPACE_AUTHORITY);

        let old_types = schema::remove(uid, namespace, keys);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let old_type = *vector::borrow(&old_types, i);

            if (!string::is_empty(&old_type)) {
                serializer::drop_field(uid, Key { namespace, key }, old_type);
            };

            i = i + 1;
        };
    }

    // Convenience function using a Witness pattern. 'witness' is the Namespace
    public fun remove_all<Namespace>(
        uid: &mut UID,
        auth: &TxAuthority
    ) {
        let namespace_addr = encode::package_id<Namespace>();
        remove_all_(uid, option::some(namespace_addr), auth);
    }

    public fun remove_all_(
        uid: &mut UID,
        namespace: Option<ID>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_package_opt<WRITE>(namespace, auth), ENO_NAMESPACE_AUTHORITY);

        let (keys, types) = schema::remove_all(uid, namespace);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let type = *vector::borrow(&types, i);

            serializer::drop_field(uid, Key { namespace, key }, type);

            i = i + 1;
        };
    }

    // ===== Accessor Functions =====

    public fun exists_(uid: &UID, namespace: Option<ID>, key: String): bool {
        dynamic_field::exists_(uid, Key { namespace, key })
    }

    // Hint: use schema::get_type(uid, namespace, key) to get the type of the value as an Option<String>.
    public fun exists_with_type<T: store>(uid: &UID, namespace: Option<ID>, key: String): bool {
        dynamic_field::exists_with_type<Key, T>(uid, Key { namespace, key })
    }

    // Requires no namespace authorization; any module can read any value. We chose to do this for reads to
    // encourage composability between projects, rather than keeping data private between namespaces.
    // The caller must correctly specify the type `T` of the value, and the value must exist, otherwise this
    // will abort.
    public fun borrow<T: store>(uid: &UID, namespace: Option<ID>, key: String): &T {
        dynamic_field::borrow<Key, T>(uid, Key { namespace, key })
    }

    // Requires namespace authority to write.
    // The caller must correctly specify the type `T` of the value, and the value must exist, otherwise this
    // will abort.
    public fun borrow_mut<T: store>(
        uid: &mut UID,
        namespace: Option<ID>,
        key: String,
        auth: &TxAuthority
    ): &mut T {
        assert!(tx_authority::can_act_as_package_opt<WRITE>(namespace, auth), ENO_NAMESPACE_AUTHORITY);

        dynamic_field::borrow_mut<Key, T>(uid, Key { namespace, key })
    }

    public fun borrow_mut_fill<Namespace, T: store + drop>(
        uid: &mut UID,
        key: String,
        default: T,
        auth: &TxAuthority
    ): &mut T {
        let package_id = encode::package_id<Namespace>();
        borrow_mut_fill_(uid, option::some(package_id), key, default, auth)
    }

    // Ensures that the specified value exists and is of the specified type by filling it with the default value
    // if it does not.
    public fun borrow_mut_fill_<T: store + drop>(
        uid: &mut UID,
        namespace: Option<ID>,
        key: String,
        default: T,
        auth: &TxAuthority
    ): &mut T {
        assert!(tx_authority::can_act_as_package_opt<WRITE>(namespace, auth), ENO_NAMESPACE_AUTHORITY);

        dynamic_field2::borrow_mut_fill<Key, T>(uid, Key { namespace, key }, default)
    }

    // ===== Copy Functions =====
    // Duplicate data from a namespace to another namespace, or copy from one object to another

    public fun duplicate<Source, Destination>(source_uid: &UID, destination_uid: &mut UID, auth: &TxAuthority) {
        let source = option::some(encode::package_id<Source>());
        let destination = option::some(encode::package_id<Destination>());
        duplicate_(source, destination, source_uid, destination_uid, auth);
    }

    public fun duplicate_(
        source: Option<ID>,
        destination: Option<ID>,
        source_uid: &UID,
        destination_uid: &mut UID,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::can_act_as_package_opt<WRITE>(destination, auth), ENO_NAMESPACE_AUTHORITY);

        let (keys, types) = schema::into_keys_types(source_uid, source);
        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let type = *vector::borrow(&types, i);
            
            let key1 = Key { namespace: source, key };
            let key2 = Key { namespace: destination, key };

            let old_types_to_drop = schema::update_object_schema_(destination_uid, destination, vector[key], type);
            let old_type = vector::pop_back(&mut old_types_to_drop);

            serializer::duplicate(source_uid, destination_uid, key1, key2, type, old_type, true);

            i = i + 1;
        };
    }

    // ==== Specialty Functions ====

    // Note that this changes the ordering of the fields in `data` and `fields`, which
    // shouldn't matter to the function calling this, because data[x] still corresponds to
    // fields[x] for all values of x.
    //
    // It's impossible to implement a general 'deserialize_and_take_field' function in Sui, because Move
    // must know all types statically at compile-time; types cannot vary at runtime. That's why this
    // is limited to only String types. We plan to create a native function within Sui that
    // allows for general deserialization of primitive types, like:
    //      deserialize<T>(data: vector<u8>): T
    // But until something like that exists, we're limited.
    public fun deserialize_and_take_string(
        key: String,
        data: &mut vector<vector<u8>>,
        fields: &mut vector<vector<String>>,
        default: String
    ): String {
        // Search for `key` in the fields vector
        let len = vector::length(fields);
        let (i, j) = (0, len);
        while (i < len) {
            let field = vector::borrow(fields, i);
            if (vector::borrow(field, 0) == &key) {
                j = i;
                break
            };
            i = i + 1;
        };

        // Key was not found
        if (j == len) {
            return default
        };

        let value = vector::swap_remove(data, j);
        let _field = vector::swap_remove(fields, j);

        string::utf8(value)
    }

    // ============= devInspect (view) Functions =============

    // This is the same as calling `view` with all the keys in its schema
    public fun view_all(uid: &UID, namespace: Option<ID>): vector<u8> {
        view(uid, namespace, schema::into_keys(uid, namespace))
    }

    // The response is raw BCS bytes; the client app will need to consult this object's schema for the
    // specified namespace + specified keys order to deserialize the results.
    public fun view(uid: &UID, namespace: Option<ID>, keys: vector<String>): vector<u8> {
        let (i, response, len) = (0, vector::empty<u8>(), vector::length(&keys));

        while (i < len) {
            vector::append(
                &mut response,
                get_bcs_bytes(uid, namespace, *vector::borrow(&keys, i))
            );
            i = i + 1;
        };

        response
    }

    // Same as above, but with separated vectors per type
    // This only matters for on-chain functions; off-chain all the vectors get concatenated together
    public fun view_parsed(uid: &UID, namespace: Option<ID>, keys: vector<String>): vector<vector<u8>> {
        let (i, response, len) = (0, vector::empty<vector<u8>>(), vector::length(&keys));

        while (i < len) {
            vector::push_back(
                &mut response,
                get_bcs_bytes(uid, namespace, *vector::borrow(&keys, i))
            );
            i = i + 1;
        };

        response
    }

    // Same as above, except we fill in undefined values with the default object's values
    public fun view_with_default(
        uid: &UID,
        default: &UID,
        namespace: Option<ID>,
        keys: vector<String>
    ): vector<u8> {
        let (i, response, len) = (0, vector::empty<u8>(), vector::length(&keys));

        while (i < len) {
            let key = *vector::borrow(&keys, i);
            let bytes = get_bcs_bytes(uid, namespace, key);
            if (bytes == vector[0u8]) bytes = get_bcs_bytes(default, namespace, key);
            vector::append(&mut response, bytes);
            i = i + 1;
        };

        response
    }

    // This is necessary because only attach::data can construct Key { } to access these fields
    public fun get_bcs_bytes(
        uid: &UID,
        namespace: Option<ID>,
        key: String
    ): vector<u8> {
        let type_maybe = schema::get_type(uid, namespace, key);
        // if (option::is_none(type_maybe)) {
        //     return vector[0u8]; // option::none in BCS
        // }
        // we might want to append vector[1u8] as option::some here
        let type = option::destroy_some(type_maybe);

        serializer::get_bcs_bytes(uid, Key { namespace, key }, type)
    }

    // Note that this doesn't validate that the schema you supplied is the cannonical schema for this object,
    // or that the keys  you've specified exist on your suppplied schema. Deserialize these results with the
    // schema you supplied, not with the object's cannonical schema
    // public fun view_field(uid: &UID, slot: String, schema: &Schema): vector<u8> {
    //     let (type_maybe, optional_maybe) = schema::get_field(schema, slot);

    //     if (dynamic_field::exists_(uid, Key { slot }) && option::is_some(&type_maybe)) {
    //         let type = option::destroy_some(type_maybe);

    //         // We only prepend option-bytes if the key is optional
    //         let bytes = if (option::destroy_some(optional_maybe)) { 
    //             vector[1u8] // option::is_some
    //         } else {
    //             vector::empty<u8>()
    //         };

    //         vector::append(&mut bytes, get_bcs_bytes(uid, slot, type));

    //         bytes
    //     } else if (option::is_some(&type_maybe)) {
    //         vector[0u8] // option::is_none
    //     } else {
    //         abort EKEY_DOES_NOT_EXIST_ON_SCHEMA
    //     }
    // }

    // public fun view_field_(uid: &UID, slot: String, fields: &VecMap<String, Field>): vector<u8> {
    //     if (vec_map::contains(fields, &slot)) {
    //         if (!dynamic_field::exists_(uid, Key { slot })) {
    //             return vector[0u8] // option::is_none
    //         };

    //         let field = vec_map::get(fields, &slot);
    //         let (type, optional) = schema::field_into_components(field);

    //         // We only prepend option-bytes if the key is optional
    //         let bytes = if (optional) { 
    //             vector[1u8] // option::is_some
    //         } else {
    //             vector::empty<u8>()
    //         };

    //         vector::append(&mut bytes, get_bcs_bytes(uid, slot, type));

    //         bytes
    //     } else {
    //         abort EKEY_DOES_NOT_EXIST_ON_SCHEMA
    //     }
    // }


}

#[test_only]
module attach::data_tests {
    use std::string::{String, utf8};
    use std::option::{Self, Option};
    use std::vector;

    use sui::bcs;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context;
    use sui::test_scenario::{Self, Scenario};

    use sui_utils::typed_id;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use attach::data;
    use attach::schema;

    // Error constants
    const EINVALID_METADATA: u64 = 0;
    const ENOT_OWNER: u64 = 1;

    const SENDER: address = @0x99;

    struct Witness has drop {}

    struct TestObject has key {
        id: UID
    }

    public fun uid(test_object: &TestObject): &UID {
        &test_object.id
    }

    public fun uid_mut(test_object: &mut TestObject, auth: &TxAuthority): &mut UID {
        assert!(ownership::can_borrow_uid_mut(&test_object.id, auth), ENOT_OWNER);

        &mut test_object.id
    }

    fun create_test_object(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        let object = TestObject { 
            id: object::new(ctx) 
        };

        let typed_id = typed_id::new(&object);
        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        let owner = option::some(tx_context::sender(ctx));

        ownership::as_shared_object_(&mut object.id, typed_id, owner, owner, &auth);
        transfer::share_object(object)
    }

    fun get_test_values(): (vector<vector<u8>>, vector<u8>) {
        let string_values = vector[ 
            bcs::to_bytes(&b"Capsules"), 
            bcs::to_bytes(&b"Coolest project on Sui!"), 
            bcs::to_bytes(&b"https://www.capsulecraft.dev/"),
        ];
        let u8_values = vector<u8>[10];

        (string_values, u8_values)
    }

    fun get_test_keys(): (vector<String>, vector<String>) {
        let string_keys = vector[utf8(b"name"), utf8(b"description"), utf8(b"website")];
        let u8_keys = vector[utf8(b"rating")];

        (string_keys, u8_keys)
    }

    fun get_serialized_test_data(): (vector<vector<String>>, vector<vector<u8>>) {
        let fields = vector[
            vector[utf8(b"name"), utf8(b"String")], 
            vector[utf8(b"description"), utf8(b"String")], 
            vector[utf8(b"website"), utf8(b"String")],
            vector[utf8(b"rating"), utf8(b"u8")],
        ];
        let values = vector[ 
            bcs::to_bytes(&b"Capsules"),
            bcs::to_bytes(&b"Coolest project on Sui!"),
            bcs::to_bytes(&b"https://www.capsulecraft.dev/"),
            bcs::to_bytes<u8>(&9),
        ];

        (fields, values)
    }

    fun current_package(): address {
        tx_authority::type_into_address<Witness>()
    }

    fun assert_deserialize_values(types: vector<String>, data: vector<u8>, values: vector<vector<u8>>) {
        let (i, bcs) = (0, bcs::new(data));

        while(i < vector::length(&types)) {
            let type = *vector::borrow(&types, i);
            let value = vector::borrow(&values, i);

            if(type == utf8(b"vector<u8>")) {
                assert!(bcs::peel_vec_u8(&mut bcs) == *value, 0)
            } else if (type == utf8(b"String")) {
                assert!(bcs::peel_vec_u8(&mut bcs) == bcs::peel_vec_u8(&mut bcs::new(*value)), 0)
            } else if(type == utf8(b"u8")) {
                assert!(bcs::peel_u8(&mut bcs) == *vector::borrow(value, 0), 0)
            };

            i = i + 1;
        }
    }

    fun assert_deserialize_serialized_data(uid: &mut UID, namespace: Option<ID>, values: vector<vector<u8>>, fields: vector<vector<String>>) {
        let data = data::view_all(uid, namespace);
        let (i, types) = (0, vector[]);

        while(i < vector::length(&fields)) {
            let field = vector::borrow(&fields, i);
            vector::push_back(&mut types, *vector::borrow(field, 1));

            i = i + 1;
        };

        assert_deserialize_values(types, data, values)
    }
 
    #[test]
    public fun test_set_data() {
        let scenario = test_scenario::begin(SENDER);
        let (string_keys, u8_keys) = get_test_keys();
        let (string_values, u8_values) = get_test_values();

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);

            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
            let uid = uid_mut(&mut object, &auth);

            data::set<Witness, vector<u8>>(uid, string_keys, string_values, &auth);
            data::set<Witness, u8>(uid, u8_keys, u8_values, &auth);

            let namespace = option::some(current_package());
            let (keys, types) = schema::into_keys_types(uid, namespace);
            let values = data::view(uid, namespace, keys);

            let data = string_values;
            vector::push_back(&mut data, u8_values);

            assert_deserialize_values(types, values, data);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_serialized_set_data() {
        let scenario = test_scenario::begin(SENDER);
        let namespace = option::some(current_package());
        let (fields, values) = get_serialized_test_data();

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);

            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
            let uid = uid_mut(&mut object, &auth);

            data::deserialize_and_set<Witness>(Witness {}, uid, values, fields);
            assert_deserialize_serialized_data(uid, namespace, values, fields);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_remove_data() {
        let scenario = test_scenario::begin(SENDER);
        let namespace = option::some(current_package());
        let (fields, values) = get_serialized_test_data();

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);

            let field_name = utf8(b"rating");
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
            let uid = uid_mut(&mut object, &auth);

            data::deserialize_and_set<Witness>(Witness {}, uid, values, fields);
            assert_deserialize_serialized_data(uid, namespace, values, fields);

            let auth = tx_authority::begin_with_type(&Witness {});
            data::remove(uid, namespace, vector[field_name], &auth);

            assert!(!data::exists_(uid, namespace, field_name), 0);
            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_remove_all_data() {
        let scenario = test_scenario::begin(SENDER);
        let namespace = option::some(current_package());
        let (fields, values) = get_serialized_test_data();

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let object = test_scenario::take_shared<TestObject>(&scenario);
            
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
            let uid = uid_mut(&mut object, &auth);
            
            data::deserialize_and_set<Witness>(Witness {}, uid, values, fields);
            assert_deserialize_serialized_data(uid, namespace, values, fields);
            data::remove_all(uid, namespace, &auth);

            let (i, len) = (0, vector::length(&fields));
            while (i < len) {
                let field_name = *vector::borrow(vector::borrow(&fields, i), 0);
                assert!(!data::exists_(uid, namespace, field_name), 0);

                i = i + 1;
            };

            test_scenario::return_shared(object);
        };

        test_scenario::end(scenario);
    }

    #[test]
    public fun test_duplicate_data() {
        let scenario = test_scenario::begin(SENDER);
        let namespace = option::some(current_package());
        let (fields, values) = get_serialized_test_data();

        create_test_object(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let source_object = test_scenario::take_shared<TestObject>(&scenario);
            
            let ctx = test_scenario::ctx(&mut scenario);
            let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
            let source_uid = uid_mut(&mut source_object, &auth);

            data::deserialize_and_set<Witness>(Witness {}, source_uid, values, fields);
            assert_deserialize_serialized_data(source_uid, namespace, values, fields);

            create_test_object(&mut scenario);
            test_scenario::next_tx(&mut scenario, SENDER);

            {
                let dest_object = test_scenario::take_shared<TestObject>(&scenario);
                let dest_uid = uid_mut(&mut dest_object, &auth);

                data::duplicate_(namespace, option::none(), source_uid, dest_uid, &auth);
                assert_deserialize_serialized_data(dest_uid, option::none(), values, fields);
                test_scenario::return_shared(dest_object);
            };

            test_scenario::return_shared(source_object);
        };

        test_scenario::end(scenario);
    }
}