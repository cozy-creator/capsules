// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Typed wrappers around Sui object IDs
/// While not always necessary, this is helpful for indicating the type of an object, particularly
/// when storing its ID in another object.
/// Additionally, it can be helpful for disambiguating between different IDs in an object.
/// For example
/// ```
/// struct MyObject has key {
///   id: VersionedID,
///   child1: TypedID<A>,
///   child2: TypedID<B>,
/// }
/// ```
/// We then know that `child1` is an ID for an object of type `A` and that `child2` is an `ID`
/// of an object of type `B`
module sui_utils::typed_id {
    use sui::object::{Self, ID};

    /// An ID of an of type `T`. See `ID` for more details
    /// By construction, it is guaranteed that the `ID` represents an object of type `T`
    struct TypedID<phantom T: key> has copy, drop, store {
        id: ID,
    }

    /// Get the underlying `ID` of `obj`, and remember the type
    public fun new<T: key>(obj: &T): TypedID<T> {
        TypedID { id: object::id(obj) }
    }

    /// Borrow the inner `ID` of `typed_id`
    public fun as_id<T: key>(typed_id: &TypedID<T>): &ID {
        &typed_id.id
    }

    /// Get the inner `ID` of `typed_id`
    public fun to_id<T: key>(typed_id: TypedID<T>): ID {
        let TypedID { id } = typed_id;
        id
    }

    /// Check that underlying `ID` in the `typed_id` equals the objects ID
    public fun equals_object<T: key>(typed_id: &TypedID<T>, obj: &T): bool {
        typed_id.id == object::id(obj)
    }
}

#[test_only]
module sui_utils::typed_id_tests {
    use sui::object::{Self, UID};
    use sui::test_scenario;

    use sui_utils::typed_id;

    struct TestObject has key {
        id: UID
    }

    fun drop_obj(obj: TestObject) {
        let TestObject { id } = obj;
        object::delete(id);
    }

    #[test]
    fun test_equality() {
        let scenario = test_scenario::begin(@0x54E);
        let ctx = test_scenario::ctx(&mut scenario);

        let obj = TestObject { id: object::new(ctx) };
        let tid = typed_id::new(&obj);

        assert!(typed_id::equals_object(&tid, &obj), 0);
        assert!(typed_id::as_id(&tid) == object::borrow_id(&obj), 0);
        assert!(typed_id::to_id(tid) == object::id(&obj), 0);

        drop_obj(obj);
        test_scenario::end(scenario);
    }
}