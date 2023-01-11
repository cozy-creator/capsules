// Currently, this stores metadata as raw-bytes. For example, a ascii::String will simply be stored as bytes, rather than
// a type. Should we change this, and store the actual objects instead? It might be more useful for on-chain programs trying to
// read values, or for explorers examining dynamic fields.
//
// Additionally we are storing each schema as a root-level immutable object. Inside of each object we are merely storing the ID
// of that object, rather than the object itself. Perhaps we should store the schema itself inside the object?
//
// What BCS could use: objectID, peel_u16, peel_u32, peel_u256, peel_ascii_string, peel_utf8_string, and vector versions of
// all of these
//
// Future to do:
// - add authority-checking to see who can add or modify metadata
// - migrate schema for an object (compatible upgrades?)
// - edit individual metadata for a key (including add / remove if optional)
// - have a better url type

module metadata::metadata {
    use std::ascii;
    use std::string;
    use std::option;
    use std::vector;
    use sui::bcs::{Self, BCS};
    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use metadata::schema::{Self, Schema};
    use sui_utils::vector::slice_mut;

    // Error enums
    const EINCORRECT_DATA_LENGTH: u64 = 0;
    const EMISSING_OPTION_BYTE: u64 = 1;
    const EUNRECOGNIZED_TYPE: u64 = 2;
    const EINCORRECT_SCHEMA_SUPPLIED: u64 = 3;
    const EINCOMPATIBLE_READER_SCHEMA: u64 = 4;

    /// Address length in Sui is 20 bytes.
    const SUI_ADDRESS_LENGTH: u64 = 20;

    struct SchemaID has store, copy, drop { }
    struct Key has store, copy, drop { slot: ascii::String }

    // Schema = vector<ascii::String> = [slot_name, slot_type, optional]
    // for example: "age", "u8", "0", where 0 = required, 1 = optional
    // That is, Schema is a vector with 3 items per item in the schema
    public fun define(id: &mut UID, schema_: &Schema, data: vector<vector<u8>>) {
        let schema = schema::get(schema_);
        assert!(vector::length(&schema) == vector::length(&data), EINCORRECT_DATA_LENGTH);

        let i = 0;
        while (i < vector::length(&schema)) {
            let item = vector::borrow(&schema, i);
            let (key, type, optional) = schema::item(item);
            let value = *vector::borrow(&data, i);

            // All optional items must be prepended with an option byte, otherwise an abort will occur
            if (optional) {
                if (is_some(value)) {
                    vector::remove(&mut value, 0); // remove the optional-byte
                } else {
                    i = i + 1;
                    continue
                }
            };

            add_field(id, Key { slot: key }, type, value);
            i = i + 1;
        };

        dynamic_field::add(id, SchemaID { }, object::id(schema_));
    }

    public fun remove_optional() {

    }

    // Works if the updated value is already defined or undefined (optional)
    public fun update() {

    }

    // ============= devInspect Functions ============= 

    // convenience function so you can supply ascii-bytes rather than ascii types
    public fun view(id: &UID, keys: vector<vector<u8>>, schema_: &Schema): (vector<vector<u8>>, ID) {
        let (ascii_keys, i) = (vector::empty<ascii::String>(), 0);
        while (i < vector::length(&keys)) {
            vector::push_back(&mut ascii_keys, ascii::string(*vector::borrow(&keys, i)));
            i = i + 1;
        };
        view_(id, ascii_keys, schema_)
    }

    // This prepends every item with an option byte: 1 (exists) or 0 (doesn't exist)
    // The response we're turning is just raw bytes; it's up to the client app to figure out what the value-types should be,
    // which is why we provide an ID for the object's schema, which is needed in order to deserialize the bytes.
    // Perhaps there is a more convenient way to do this for the client?
    public fun view_(id: &UID, keys: vector<ascii::String>, schema_: &Schema): (vector<vector<u8>>, ID) {
        let (i, response) = (0, vector::empty<vector<u8>>());
        let schema_id = *dynamic_field::borrow<SchemaID, ID>(id, SchemaID { } );
        assert!(object::id(schema_) == schema_id, EINCORRECT_SCHEMA_SUPPLIED);

        while (i < vector::length(&keys)) {
            let slot = *vector::borrow(&keys, i);
            let (type_maybe, _) = schema::find_type_for_key(schema_, slot);
            if (dynamic_field::exists_(id, Key { slot }) && option::is_some(&type_maybe)) {
                let type = option::destroy_some(type_maybe);
                let bytes = get_bcs_bytes(id, Key { slot }, type);
                // Sui Devnet doesn't have this function yet
                // vector::insert(&mut bytes, 1u8, 0);
                vector::reverse(&mut bytes);
                vector::push_back(&mut bytes, 1u8); // option::is_some
                vector::reverse(&mut bytes);
                // So we use these three ugly lines instead for now ^^^
                vector::push_back(&mut response, bytes);
            } else {
                vector::push_back(&mut response, vector[0u8]); // option::is_none
            };
            i = i + 1;
        };

        (response, schema_id)
    }

    // This is the same as calling view_ with all the keys of its own schema
    public fun view_all(id: &UID, schema_: &Schema): (vector<vector<u8>>, ID) {
        let (schema, i, keys) = (schema::get(schema_), 0, vector::empty<ascii::String>());

        while (i < vector::length(&schema)) {
            let (key, _, _) = schema::item(vector::borrow(&schema, i));
            vector::push_back(&mut keys, key);
            i = i + 1;
        };
        view_(id, keys, schema_)
    }

    // You can specify a set of keys to use by taking them from a 'reader schema'. Note that the reader_schema
    // and object's own schema must be compatible, in the sense that any key overlaps = the same type.
    // Maybe we could take into account optionality or do some sort of type coercian to relax this compatability
    // requirement? I.e., turn a u8 into a u64, or an ascii string into a utf8 string
    public fun view_with_reader_schema(id: &UID, reader_schema_: &Schema, object_schema_: &Schema): (vector<vector<u8>>, ID) {
        assert!(schema::is_compatible(reader_schema_, object_schema_), EINCOMPATIBLE_READER_SCHEMA);

        let (reader_schema, i, keys) = (schema::get(reader_schema_), 0, vector::empty<ascii::String>());

        while (i < vector::length(&reader_schema)) {
            let (key, _, _) = schema::item(vector::borrow(&reader_schema, i));
            vector::push_back(&mut keys, key);
            i = i + 1;
        };
        view_(id, keys, object_schema_)
    }

    public fun get_schema_id(id: &UID): ID {
        *dynamic_field::borrow<SchemaID, ID>(id, SchemaID { } )
    }

    // ============ (de)serializes objects ============ 

    // BCS serialization for optionals:
    // option::some<u8>() = [1,(8 bytes little endian)]
    // option::none<anything>() = [0]
    // Options prepend a single byte, which is either 0 or 1.
    // Meaning option::some<u64>() has an extra preceeding byte compared to just u64
    // If you are passing in non-optional bytes, such as just u64, rather than Option<u64>, this function will probably abort
    public fun is_some(bytes: vector<u8>): bool {
        let first_byte = *vector::borrow(&bytes, 0);

        if (first_byte == 1) {
            true
        } else if (first_byte == 0) {
            false
        } else {
            abort EMISSING_OPTION_BYTE
        }
    }

    // Aborts if the type is incorrect (schema violation) because the bcs deserialization will fail
    // Supported: address, bool, objectID, u8, u64, u128, string::String (utf8), ascii::String +  vectors of these types
    // Not yet supported: u16, u32, u256 <--not included in sui::bcs
    public fun add_field(id: &mut UID, key: Key, type_: ascii::String, bytes: vector<u8>) {
        let bcs = &mut bcs::new(copy bytes);
        let type = ascii::into_bytes(type_);

        if (type == b"address") {
            let addr = bcs::peel_address(bcs);
            dynamic_field::add(id, key, addr);
        } 
        else if (type == b"bool") {
            let boolean = bcs::peel_bool(bcs);
            dynamic_field::add(id, key, boolean);
        } 
        else if (type == b"0x2::object::ID") {
            let object_id = object::id_from_bytes(bytes);
            dynamic_field::add(id, key, object_id);
        } 
        else if (type == b"u8") {
            let integer = bcs::peel_u8(bcs);
            dynamic_field::add(id, key, integer);
        } 
        else if (type == b"u64") {
            let integer = bcs::peel_u64(bcs);
            dynamic_field::add(id, key, integer);
        } 
        else if (type == b"u128") {
            let integer = bcs::peel_u128(bcs);
            dynamic_field::add(id, key, integer);
        } 
        else if (type == b"0x1::string::String") {
            let string = string::utf8(bytes);
            dynamic_field::add(id, key, string);
        } 
        else if (type == b"0x1::ascii::String") {
            let string = ascii::string(bytes);
            dynamic_field::add(id, key, string);
        } 
        else if (type == b"vector<address>") {
            let vec = bcs::peel_vec_address(bcs);
            dynamic_field::add(id, key, vec);
        }
        else if (type == b"vector<bool>") {
            let vec = bcs::peel_vec_bool(bcs);
            dynamic_field::add(id, key, vec);
        }
        else if (type == b"vector<0x2::object::ID>") {
            let vec = peel_vec_id(bcs);
            dynamic_field::add(id, key, vec);
        }
        else if (type == b"vector<u8>") {
            let vec = bcs::peel_vec_u8(bcs);
            dynamic_field::add(id, key, vec);
        }
        else if (type == b"vector<u64>") {
            let vec = bcs::peel_vec_u64(bcs);
            dynamic_field::add(id, key, vec);
        }
        else if (type == b"vector<u128>") {
            let vec = bcs::peel_vec_u128(bcs);
            dynamic_field::add(id, key, vec);
        }
        else if (type == b"vector<0x1::string::String>") {
            let (string, _) = peel_vec_utf8_string(*bcs);
            dynamic_field::add(id, key, string);
        }
        else if (type == b"vector<0x1::ascii::String>") {
            let (string, _) = peel_vec_ascii_string(*bcs);
            dynamic_field::add(id, key, string);
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    public fun get_bcs_bytes(id: &UID, key: Key, type_: ascii::String): vector<u8> {
        let type = ascii::into_bytes(type_);

        if (type == b"address") {
            let addr = dynamic_field::borrow<Key, address>(id, key);
            bcs::to_bytes(addr)
        } 
        else if (type == b"bool") {
            let boolean = dynamic_field::borrow<Key, bool>(id, key);
            bcs::to_bytes(boolean)
        } 
        else if (type == b"0x2::object::ID") {
            let object_id = dynamic_field::borrow<Key, ID>(id, key);
            bcs::to_bytes(object_id)
        } 
        else if (type == b"u8") {
            let int = dynamic_field::borrow<Key, u8>(id, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"u64") {
            let int = dynamic_field::borrow<Key, u64>(id, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"u128") {
            let int = dynamic_field::borrow<Key, u128>(id, key);
            bcs::to_bytes(int)
        } 
        else if (type == b"0x1::string::String") {
            let string = dynamic_field::borrow<Key, string::String>(id, key);
            bcs::to_bytes(string)
        } 
        else if (type == b"0x1::ascii::String") {
            let string = dynamic_field::borrow<Key, ascii::String>(id, key);
            bcs::to_bytes(string)
        } 
        else if (type == b"vector<address>") {
            let vec = dynamic_field::borrow<Key, vector<address>>(id, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<bool>") {
            let vec = dynamic_field::borrow<Key, vector<bool>>(id, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<0x2::object::ID>") {
            let vec = dynamic_field::borrow<Key, vector<ID>>(id, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u8>") {
            let vec = dynamic_field::borrow<Key, vector<u8>>(id, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u64>") {
            let vec = dynamic_field::borrow<Key, vector<u64>>(id, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<u128>") {
            let vec = dynamic_field::borrow<Key, vector<u128>>(id, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<0x1::string::String>") {
            let vec = dynamic_field::borrow<Key, vector<string::String>>(id, key);
            bcs::to_bytes(vec)
        }
        else if (type == b"vector<0x1::ascii::String>") {
            let vec = dynamic_field::borrow<Key, vector<ascii::String>>(id, key);
            bcs::to_bytes(vec)
        }
        else {
            abort EUNRECOGNIZED_TYPE
        }
    }

    // ============ BCS extensions ============ 
    // These functions should be added to sui::bcs

    // To do: Check this; does bcs prepend a length to addresses, or is it just assumed that they are of length 20?
    public fun peel_vec_id(bcs: &mut BCS): vector<ID> {
        let (len, i, res) = (bcs::peel_vec_length(bcs), 0, vector[]);
        while (i < len) {
            let id = object::id_from_address(bcs::peel_address(bcs));
            vector::push_back(&mut res, id);
            i = i + 1;
        };
        res
    }

    // To do: check to see if bcs is prepending the length of strings; I believe it does
    // Returns any remaining BCS bytes. This setup is needed because there is no way to access a BCS'
    // underlying bytes without destroying it
    public fun peel_vec_ascii_string(bcs: BCS): (vector<ascii::String>, BCS) {
        let (num_strings, i, res) = (bcs::peel_vec_length(&mut bcs), 0, vector[]);
        while (i < num_strings) {
            let len = bcs::peel_vec_length(&mut bcs);
            let bytes = bcs::into_remainder_bytes(bcs); // remove bytes from bcs wrapper
            let string_bytes = slice_mut(&mut bytes, 0, len);
            let string = ascii::string(string_bytes);
            vector::push_back(&mut res, string);
            bcs = bcs::new(bytes); // put bytes back into bcs wrapper for the next loop
            i = i + 1;
        };
        (res, bcs)
    }

    // Unfortunately the above function had to be copy-paste replicated
    public fun peel_vec_utf8_string(bcs: BCS): (vector<string::String>, BCS) {
        let (num_strings, i, res) = (bcs::peel_vec_length(&mut bcs), 0, vector[]);
        while (i < num_strings) {
            let len = bcs::peel_vec_length(&mut bcs);
            let bytes = bcs::into_remainder_bytes(bcs); // remove bytes from bcs wrapper
            let string_bytes = slice_mut(&mut bytes, 0, len);
            let string = string::utf8(string_bytes);
            vector::push_back(&mut res, string);
            bcs = bcs::new(bytes); // put bytes back into bcs wrapper for the next loop
            i = i + 1;
        };
        (res, bcs)
    }
}