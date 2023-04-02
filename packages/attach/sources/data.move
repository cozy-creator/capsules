// ========== Sui's Data-Attaching System ==========
//
// Attach supported data-types to arbitrary objects using dynamic fields, and manage access to them
// using a namespace system. Any module can read from any other module's namespace, but modules can
// only write to their own namespaces, unless the other module delegates them permission to do so.
//
// Native-modules do not require ownership-authority to write to their namespace; they can always
// produce a &mut UID for their native-objects. On the other hand, Foreign-modules require
// ownership-authority for writes.

module attach::data {
    use std::string::{Self, String};
    use std::option;
    use std::vector;

    use sui::bcs::{Self};
    use sui::dynamic_field;
    use sui::object::{UID, ID};
    use sui::vec_map::VecMap;
    use sui::url::Url;

    use sui_utils::encode;
    use sui_utils::deserialize;
    use sui_utils::dynamic_field2;

    use ownership::tx_authority::{Self, TxAuthority};

    use attach::schema;

    // Error enums
    const ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE: u64 = 0;
    const EINCORRECT_DATA_LENGTH: u64 = 1;
    const EKEY_DOES_NOT_EXIST_ON_SCHEMA: u64 = 2;
    const EUNRECOGNIZED_TYPE: u64 = 3;

    // Key used to store data on an object for a given namespace + key
    struct Key has store, copy, drop { namespace: address, key: String }

    // Convenience function
    public fun set<Namespace, T: store + copy + drop>(
        uid: &mut UID,
        keys: vector<String>,
        values: vector<T>,
        auth: &TxAuthority
    ) {
        let namespace_addr = tx_authority::type_into_address<Namespace>();
        set_(uid, namespace_addr, keys, values, auth);
    }

    // Because of the ergonomics of Sui, all values added must be the same Type. If you have to add mixed types,
    // like u64's and Strings, that will require two separate calls.
    public fun set_<T: store + drop>(
        uid: &mut UID,
        namespace: address,
        keys: vector<String>,
        values: vector<T>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::is_signed_by(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);
        assert!(vector::length(&keys) == vector::length(&values), EINCORRECT_DATA_LENGTH);

        let type = schema::simple_type_name<T>();
        let old_types_to_drop = schema::update_object_schema_(uid, namespace, keys, type);

        while (vector::length(&keys) > 0) {
            let key = vector::pop_back(&mut keys);
            let value = vector::pop_back(&mut values);
            let old_type = vector::pop_back(&mut old_types_to_drop);

            set_field_(uid, Key { namespace, key }, type, old_type, value, true);
        };
    }

    // Convenience function
    public fun deserialize_and_set<Namespace>(
        uid: &mut UID,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        let namespace_addr = tx_authority::type_into_address<Namespace>();
        deserialize_and_set_(uid, namespace_addr, data, fields, auth);
    }

    // This is a powerful function that allows client applications to serialize arbitrary objects
    // (that consist of supported primitive types), submit them as a transaction, then deserialize +
    // attach all fields to an arbitrary object with a single function call. This is part of our Sui ORM
    // system.
    public fun deserialize_and_set_(
        uid: &mut UID,
        namespace: address,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::is_signed_by(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);
        assert!(vector::length(&data) == vector::length(&fields), EINCORRECT_DATA_LENGTH);
        
        let old_types_to_drop = schema::update_object_schema(uid, namespace, fields);

        let i = 0;
        while (i < vector::length(&fields)) {
            let field = *vector::borrow(&fields, i);
            let value = *vector::borrow(&data, i);
            let (key, type) = schema::parse_field(field);
            let old_type = *vector::borrow(&old_types_to_drop, i);

            set_field(uid, Key { namespace, key }, type, old_type, value, true);
            i = i + 1;
        };
    }

    public fun remove<T: store + copy + drop>(
        uid: &mut UID,
        namespace: address,
        keys: vector<String>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::is_signed_by(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);

        let old_types = schema::remove(uid, namespace, keys);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let old_type = *vector::borrow(&old_types, i);

            if (!string::is_empty(&old_type)) {
                drop_field(uid, key, old_type);
            };

            i = i + 1;
        };
    }

    public fun remove_all<T: store + copy + drop>(
        uid: &mut UID,
        namespace: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::is_signed_by(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);

        let (keys, types) = schema::remove_all(uid, namespace);

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let type = *vector::borrow(&types, i);

            drop_field(uid, key, type);

            i = i + 1;
        };
    }

    // ===== Accessor Functions =====

    public fun exists_(uid: &UID, namespace: address, key: String): bool {
        dynamic_field::exists_(uid, Key { namespace, key })
    }

    // Hint: use schema::get_type(uid, namespace, key) to get the type of the value as an Option<String>.
    public fun exists_with_type<T: store>(uid: &UID, namespace: address, key: String): bool {
        dynamic_field::exists_with_type<Key, T>(uid, Key { namespace, key })
    }

    // Requires no namespace authorization; any module can read any value. We chose to do this for reads to
    // encourage composability between projects, rather than keeping data private between namespaces.
    // The caller must correctly specify the type `T` of the value, and the value must exist, otherwise this
    // will abort.
    public fun borrow<T: store>(uid: &UID, namespace: address, key: String): &T {
        dynamic_field::borrow<Key, T>(uid, Key { namespace, key })
    }

    // Requires namespace authority to write.
    // The caller must correctly specify the type `T` of the value, and the value must exist, otherwise this
    // will abort.
    public fun borrow_mut<T: store>(uid: &mut UID, namespace: address, key: String, auth: &TxAuthority): &mut T {
        assert!(tx_authority::is_signed_by(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);

        dynamic_field::borrow_mut<Key, T>(uid, Key { namespace, key })
    }

    // Ensures that the specified value exists and is of the specified type by filling it with the default value
    // if it does not.
    public fun borrow_mut_fill<T: store + drop>(
        uid: &mut UID,
        namespace: address,
        key: String,
        default: T,
        auth: &TxAuthority
    ): &mut T {
        assert!(tx_authority::is_signed_by(namespace, auth), ENO_AUTHORITY_TO_WRITE_TO_NAMESPACE);

        if (!exists_with_type<T>(uid, namespace, key)) {
            set_(uid, namespace, vector[key], vector[default], auth);
        };

        dynamic_field::borrow_mut<Key, T>(uid, Key { namespace, key })
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
    public fun view_all(uid: &UID, namespace: address): vector<u8> {
        view(uid, namespace, schema::into_keys(uid, namespace))
    }

    // The response is raw BCS bytes; the client app will need to consult this object's schema for the
    // specified namespace + specified keys order to deserialize the results.
    public fun view(uid: &UID, namespace: address, keys: vector<String>): vector<u8> {
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

    // Same as above, except we fill in undefined values with the default object's values
    public fun view_with_default(uid: &UID, default: &UID, namespace: address, keys: vector<String>): vector<u8> {
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

    // Same as above, but vector<vector<u8>> rather than appending all the values into a single vector<u8>
    // This only matters for on-chain responses; for off-chain responses, they'll be appended together anyway
    // public fun view_parsed(uid: &UID, keys: vector<String>, fields: &VecMap<String, Field>): vector<vector<u8>> {
    //     let (i, response, len) = (0, vector::empty<vector<u8>>(), vector::length(&keys));

    //     while (i < len) {
    //         let slot = *vector::borrow(&keys, i);
    //         vector::push_back(&mut response, view_field_(uid, slot, fields));
    //         i = i + 1;
    //     };

    //     response
    // }

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

    // ============ (de)serializes objects ============
    // We choose to keep these functions private so that they can only be modified by going
    // through one of the above-listed functions, which modify the object's stored schema

    // Aborts if `type_string` does not match `value` (the binary data) supplied, because the bcs
    // deserialization will fail
    //
    // Supported types: address, bool, objectID, u8, u16, u32, u64, u128, u256, String (utf8),
    // VecMap<String, String>, Url, and vectors of these types, as well as vector<vector<u8>>
    fun set_field<T: store + copy + drop>(
        uid: &mut UID,
        key: T,
        type: String,
        old_type: String, // Pass an empty string if this arg is not needed
        value: vector<u8>,
        overwrite: bool
    ) {
        if (!string::is_empty(&old_type) && old_type != type) {
            // Type is changing; drop the old field
            drop_field(uid, key, old_type);
        };

        // This is cheaper on gas; we don't have to construct a string every time we do a comparison
        // to a string literal. Instead we can just compare the string-bytes
        let type_bytes = *string::bytes(&type);

        // Empty byte-arrays are treated as undefined
        if (vector::length(&value) == 0) {
            // These types are allowed to be empty arrays and still count as being "defined"
            if (type_bytes == b"String" || type_bytes == b"VecMap" || encode::is_vector(type) ) {
                value = vector[0u8];
            } else { 
                drop_field(uid, key, type);
                return
            };
        };

        let i = 0;

        if (type_bytes == b"address") {
            let (addr, _) = deserialize::address_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, addr);
        } 
        else if (type_bytes == b"bool") {
            let (boolean, _) = deserialize::bool_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, boolean);
        } 
        else if (type_bytes == b"id") {
            let (object_id, _) = deserialize::id_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, object_id);
        } 
        else if (type_bytes == b"u8") {
            let integer = vector::borrow(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, *integer);
        }
        else if (type_bytes == b"u16") {
            let (integer, _) = deserialize::u16_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u32") {
            let (integer, _) = deserialize::u32_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u64") {
            let (integer, _) = deserialize::u64_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u128") {
            let (integer, _) = deserialize::u128_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"u256") {
            let (integer, _) = deserialize::u256_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, integer);
        } 
        else if (type_bytes == b"String") {
            let (string, _) = deserialize::string_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, string);
        }
        else if (type_bytes == b"Url") {
            let (url, _) = deserialize::url_(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, url);
        } 
        else if (type_bytes == b"vector<address>") {
            let (vec, _) = deserialize::vec_address(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<bool>") {
            let (vec, _) = deserialize::vec_bool(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<id>") {
            let (vec, _) = deserialize::vec_id(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u8>") {
            let (vec, _) = deserialize::vec_u8(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u16>") {
            let (vec, _) = deserialize::vec_u16(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u32>") {
            let (vec, _) = deserialize::vec_u32(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u64>") {
            let (vec, _) = deserialize::vec_u64(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u128>") {
            let (vec, _) = deserialize::vec_u128(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<u256>") {
            let (vec, _) = deserialize::vec_u256(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<vector<u8>>") {
            let (vec, _) = deserialize::vec_vec_u8(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec);
        }
        else if (type_bytes == b"vector<String>") {
            let (strings, _) = deserialize::vec_string(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, strings);
        }
        else if (type_bytes == b"vector<Url>") {
            let (urls, _) = deserialize::vec_url(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, urls);
        }
        else if (type_bytes == b"VecMap") {
            let (vec_map, _) = deserialize::vec_map_string_string(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec_map);
        }
        else if (type_bytes == b"vector<VecMap>") {
            let (vec_maps, _) = deserialize::vec_vec_map_string_string(&value, i);
            if (overwrite || !dynamic_field::exists_(uid, key))
                dynamic_field2::set(uid, key, vec_maps);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // Pass in the actual value V, rather than the bytes for value V to deserialize
    fun set_field_<K: store + copy + drop, V: store + drop>(
        uid: &mut UID,
        key: K,
        type: String,
        old_type: String,
        value: V,
        overwrite: bool
    ) {
        if (!overwrite && dynamic_field::exists_(uid, key)) {
            return
        };

        if (!string::is_empty(&old_type) && old_type != type) {
            // Type is changing; drop the old field
            drop_field(uid, key, old_type);
        };

        dynamic_field2::set(uid, key, value);
    }

    // Unfortunately sui::dynamic_field does not have a general 'drop' function; the value of the type
    // being dropped MUST be known. This makes dropping droppable assets unecessarily complex, hence
    // this lengthy function in place of what should be one line of code. I know... believe me I've asked.
    fun drop_field<T: store + copy + drop>(uid: &mut UID, key: T, type_string: String) {
        let type = *string::bytes(&type_string);

        if (type == b"address") {
            dynamic_field2::drop<T, address>(uid, key);
        } 
        else if (type == b"bool") {
            dynamic_field2::drop<T, bool>(uid, key);
        } 
        else if (type == b"id") {
            dynamic_field2::drop<T, ID>(uid, key);
        } 
        else if (type == b"u8") {
            dynamic_field2::drop<T, u8>(uid, key);
        } 
        else if (type == b"u64") {
            dynamic_field2::drop<T, u64>(uid, key);
        } 
        else if (type == b"u128") {
            dynamic_field2::drop<T, u128>(uid, key);
        } 
        else if (type == b"String") {
            dynamic_field2::drop<T, String>(uid, key);
        }
        else if (type == b"Url") {
            dynamic_field2::drop<T, Url>(uid, key);
        } 
        else if (type == b"vector<address>") {
            dynamic_field2::drop<T, vector<address>>(uid, key);
        }
        else if (type == b"vector<bool>") {
            dynamic_field2::drop<T, vector<bool>>(uid, key);
        }
        else if (type == b"vector<id>") {
            dynamic_field2::drop<T, vector<ID>>(uid, key);
        }
        else if (type == b"vector<u8>") {
            dynamic_field2::drop<T, vector<u8>>(uid, key);
        }
        else if (type == b"vector<u64>") {
            dynamic_field2::drop<T, vector<u64>>(uid, key);
        }
        else if (type == b"vector<u128>") {
            dynamic_field2::drop<T, vector<u128>>(uid, key);
        }
        else if (type == b"vector<String>") {
            dynamic_field2::drop<T, vector<String>>(uid, key);
        }
        else if (type == b"vector<Url>") {
            dynamic_field2::drop<T, vector<Url>>(uid, key);
        }
        else if (type == b"VecMap") {
            dynamic_field2::drop<T, VecMap<String, String>>(uid, key);
        }
        else if (type == b"vector<VecMap>") {
            dynamic_field2::drop<T, vector<VecMap<String, String>>>(uid, key);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // If we get dynamic_field::get_bcs_bytes we can simplify this down into 2 or 3 lines
    public fun get_bcs_bytes(uid: &UID, namespace: address, key: String): vector<u8> {
        let type_maybe = schema::get_type(uid, namespace, key);
        // if (option::is_none(type_maybe)) {
        //     return vector[0u8]; // option::none in BCS
        // }
        // we might want to append vector[1u8] as option::some here
        let type = *string::bytes(&option::destroy_some(type_maybe));

        let key = Key { namespace, key };

        if (type == b"address") {
            let addr = dynamic_field::borrow<Key, address>(uid, key);
            bcs::to_bytes(addr)
        } 
        else if (type == b"bool") {
            let boolean = dynamic_field::borrow<Key, bool>(uid, key);
            bcs::to_bytes(boolean)
        } 
        else if (type == b"id") {
            let object_id = dynamic_field::borrow<Key, ID>(uid, key);
            bcs::to_bytes(object_id)
        } 
        else if (type == b"u8") {
            let int = dynamic_field::borrow<Key, u8>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"u64") {
            let int = dynamic_field::borrow<Key, u64>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"u128") {
            let int = dynamic_field::borrow<Key, u128>(uid, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"String") {
            let string = dynamic_field::borrow<Key, String>(uid, key);
            bcs::to_bytes(string)
        }
        else if (type == b"Url") {
            let url = dynamic_field::borrow<Key, Url>(uid, key);
            bcs::to_bytes(url)
        } 
        else if (type == b"vector<address>") {
            let vec = dynamic_field::borrow<Key, vector<address>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<bool>") {
            let vec = dynamic_field::borrow<Key, vector<bool>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<id>") {
            let vec = dynamic_field::borrow<Key, vector<ID>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u8>") {
            let vec = dynamic_field::borrow<Key, vector<u8>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u64>") {
            let vec = dynamic_field::borrow<Key, vector<u64>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u128>") {
            let vec = dynamic_field::borrow<Key, vector<u128>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<String>") {
            let vec = dynamic_field::borrow<Key, vector<String>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<Url>") {
            let vec = dynamic_field::borrow<Key, vector<Url>>(uid, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"VecMap") {
            let vec_map = dynamic_field::borrow<Key, VecMap<String, String>>(uid, key);
            bcs::to_bytes(vec_map)
        }
        else if (type == b"vector<VecMap>") {
            let vec_vec_map = dynamic_field::borrow<Key, vector<VecMap<String, String>>>(uid, key);
            bcs::to_bytes(vec_vec_map)
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }
}

#[test_only]
module attach::data_tests {
    use std::string::{String, utf8};
    use std::vector;
    use std::option;

    use sui::bcs;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::test_scenario::{Self, Scenario};
    use sui::typed_id;

    use display::display;
    use display::schema;

    use ownership::tx_authority;
    use ownership::ownership;

    struct Witness has drop {}

    struct TestObject has key {
        id: UID
    }

    // Error constant
    const EINVALID_METADATA: u64 = 0;

    const SENDER: address = @0x99;

    public fun extend(test_object: &mut TestObject): &mut UID {
        &mut test_object.id
    }

    public fun assert_correct_serialization(data: vector<vector<u8>>, schema_data: vector<vector<String>>): Scenario {
        // Tx1: Create a schema
        let scenario_val = test_scenario::begin(SENDER);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            schema::create(schema_data, ctx);
        };

        // Tx2: Create an object and attach metadata
        test_scenario::next_tx(scenario, SENDER);
        let schema = test_scenario::take_immutable<schema::Schema>(scenario);
        {
            let ctx = test_scenario::ctx(scenario);

            let object = TestObject { id: object::new(ctx) };
            let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
            let typed_id = typed_id::new(&object);

            ownership::initialize_with_module_authority(&mut object.id, typed_id, &auth);

            display::attach(&mut object.id, data, &schema, &auth);

            transfer::share_object(object);
        };

        // Tx3: view metadata and assert that it was deserialized correctly
        test_scenario::next_tx(scenario, SENDER);
        let test_object = test_scenario::take_shared<TestObject>(scenario);
        {
            let uid = extend(&mut test_object);
            display::view_field(uid, utf8(b"name"), &schema);

            let keys = schema::into_keys(&schema);
            let i = 0;

            while (i < vector::length(&keys)) {
                let key = *vector::borrow(&keys, i);
                let bcs_bytes = display::view_field(uid, key, &schema);
                assert!(&bcs_bytes == vector::borrow(&data, i), EINVALID_METADATA);
                i = i + 1;
            };
        };
        test_scenario::return_immutable(schema);
        test_scenario::return_shared(test_object);

        scenario_val
    }

    #[test]
    public fun nft1() {
        let schema_data = vector<vector<String>>[ 
            vector[utf8(b"name"), utf8(b"String")],
            vector[utf8(b"description"), utf8(b"Option<String>")],
            vector[utf8(b"image"), utf8(b"String")], 
            vector[utf8(b"power_level"), utf8(b"u64")] 
        ];
        let data = vector<vector<u8>>[ 
            bcs::to_bytes(&b"Kyrie"), 
            bcs::to_bytes(&option::some(vector<u8>[])), 
            bcs::to_bytes(&b"https://wikipedia.org/"), 
            bcs::to_bytes(&19999u64) 
        ];

        test_scenario::end(assert_correct_serialization(data, schema_data));
    }

    #[test]
    public fun nft2() {
        let schema_data = vector[ 
            vector[utf8(b"name"), utf8(b"String")], 
            vector[utf8(b"description"), utf8(b"Option<String>")], 
            vector[utf8(b"image"), utf8(b"String")], 
            vector[utf8(b"power_level"), utf8(b"u64")], 
            vector[utf8(b"attributes"), utf8(b"VecMap")] 
        ];

        let data = vector[ 
            vector[6, 79, 117, 116, 108, 97, 119], 
            vector[1, 65, 84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], 
            vector[77, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], 
            vector[199, 0, 0, 0, 0, 0, 0, 0], 
            vector[ 0 ]
        ];

        test_scenario::end(assert_correct_serialization(data, schema_data));
    }

    #[test]
    public fun nft3() {
        let schema_data = vector[ 
            vector[utf8(b"name"), utf8(b"String")], 
            vector[utf8(b"description"), utf8(b"Option<String>")], 
            vector[utf8(b"image"), utf8(b"String")], 
            vector[utf8(b"attributes"), utf8(b"VecMap")] 
        ];

        let data = vector[ 
            vector[10, 121, 48, 48, 116, 32,  35, 56, 49,  55, 51], 
            vector[ 0 ], 
            vector[37, 104, 116, 116, 112, 115,  58,  47, 47, 109, 101, 116,  97, 100,  97, 116,  97,  46, 121,  48,  48, 116, 115,  46,  99, 111, 109, 47, 121,  47,  56,  49,  55,  50,  46, 112, 110, 103], 
            vector[7, 10, 66, 97, 99, 107, 103, 114, 111, 117, 110, 100, 5,  87, 104, 105, 116, 101,   3,  70, 117, 114,  14,  80, 97, 114,  97, 100, 105, 115, 101, 32, 71, 114, 101, 101, 110,  4,  70,  97,  99, 101, 9,  87, 104, 111, 108, 101, 115, 111, 109, 101,   8,  67, 108, 111, 116, 116, 104, 101, 115,  12,  83, 117, 109, 109, 101, 114,  32, 83, 104, 105, 114, 116,   4,  72, 101,  97, 100,  17,  66, 101,  97, 110, 105, 101,  32,  40,  98, 108,  97,  99, 107, 111, 117, 116, 41, 7,  69, 121, 101, 119, 101,  97, 114,  14,  77, 101, 108, 114, 111, 115, 101,  32,  66, 114, 105,  99, 107, 115, 3, 49, 47, 49, 4, 78, 111, 110, 101] ];

        test_scenario::end(assert_correct_serialization(data, schema_data));
    }

    #[test]
    public fun test_update() {
        let schema_data = vector[ 
            vector[utf8(b"name"), utf8(b"String")], 
            vector[utf8(b"url"), utf8(b"Url")], 
            vector[utf8(b"attributes"), utf8(b"VecMap")] 
        ];

        let data = vector[ 
            vector[10, 121, 48, 48, 116, 32,  35, 56, 49,  55, 51], 
            vector[37, 104, 116, 116, 112, 115,  58,  47, 47, 109, 101, 116,  97, 100,  97, 116,  97,  46, 121,  48,  48, 116, 115,  46,  99, 111, 109, 47, 121,  47,  56,  49,  55,  50,  46, 112, 110, 103], 
            vector[7, 10, 66, 97, 99, 107, 103, 114, 111, 117, 110, 100, 5,  87, 104, 105, 116, 101,   3,  70, 117, 114,  14,  80, 97, 114,  97, 100, 105, 115, 101, 32, 71, 114, 101, 101, 110,  4,  70,  97,  99, 101, 9,  87, 104, 111, 108, 101, 115, 111, 109, 101, 8,  67, 108, 111, 116, 116, 104, 101, 115,  12,  83, 117, 109, 109, 101, 114,  32, 83, 104, 105, 114, 116, 4,  72, 101,  97, 100,  17,  66, 101,  97, 110, 105, 101,  32,  40,  98, 108,  97,  99, 107, 111, 117, 116, 41, 7,  69, 121, 101, 119, 101,  97, 114,  14,  77, 101, 108, 114, 111, 115, 101,  32,  66, 114, 105,  99, 107, 115, 3, 49, 47, 49, 4, 78, 111, 110, 101] ];
        
        let scenario_val = assert_correct_serialization(data, schema_data);
        let scenario = &mut scenario_val;

        // Tx4: Update the display data
        test_scenario::next_tx(scenario, SENDER);
        let schema = test_scenario::take_immutable<schema::Schema>(scenario);
        let test_object = test_scenario::take_shared<TestObject>(scenario);
        {
            let new_data = bcs::to_bytes(&utf8(b"New Name"));
            let auth = tx_authority::begin_with_type(&Witness {});
            let uid = extend(&mut test_object);
            display::update(uid, vector[utf8(b"name")], vector[new_data], &schema, true, &auth);

            let bcs_bytes = display::view_field(uid, utf8(b"name"), &schema);
            assert!(bcs_bytes == new_data, EINVALID_METADATA);
        };
        test_scenario::return_immutable(schema);
        test_scenario::return_shared(test_object);

        test_scenario::end(scenario_val);
    }
}