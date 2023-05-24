// Cannot change types of value; this will abort if the Value-type of the existing object is wrong. The value top must be droppable

module sui_utils::dynamic_field2 {
    use std::option::{Self, Option};

    use sui::object::UID;
    use sui::dynamic_field;

    public fun set<Key: store + copy + drop, Value: store + drop>(uid: &mut UID, key: Key, value: Value) {
        drop<Key, Value>(uid, key);
        dynamic_field::add(uid, key, value);
    }

    public fun drop<Key: store + copy + drop, Value: store + drop>(uid: &mut UID, key: Key) {
        if (dynamic_field::exists_(uid, key)) {
            dynamic_field::remove<Key, Value>(uid, key);
        };
    }

    public fun get_maybe<Key: store + copy + drop, Value: store + copy>(uid: &UID, key: Key): Option<Value> {
        if (dynamic_field::exists_with_type<Key, Value>(uid, key)) {
            option::some(*dynamic_field::borrow<Key, Value>(uid, key))
        } else {
            option::none()
        }
    }

    public fun get_with_default<Key: store + copy + drop, Value: store + copy + drop>(uid: &UID, key: Key, default: Value): Value {
        if (dynamic_field::exists_with_type<Key, Value>(uid, key)) {
            *dynamic_field::borrow<Key, Value>(uid, key)
        } else {
            default
        }
    }

    public fun borrow_mut_fill<Key: store + copy + drop, Value: store + drop>(uid: &mut UID, key: Key, default: Value): &mut Value {
        if (!dynamic_field::exists_with_type<Key, Value>(uid, key)) {
            set(uid, key, default);
        };

        dynamic_field::borrow_mut<Key, Value>(uid, key)
    }   
}