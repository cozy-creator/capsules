// Capsules act as a wrapper, allowing any owned-object to be turned into a shared object. This is useful for if you want to
// sell an owned object on a market, and then the new owner can turn it back into an owned object.

module capsule::capsule {
    use std::option::{Self, Option};
    
    use sui::dynamic_field;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::typed_id;
    use sui::tx_context::{TxContext};

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    // Error Constants
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const ENO_TRANSFER_AUTHORITY: u64 = 1;
    const ECAPSULE_IS_EMPTY: u64 = 2;

    // Statically typed Capsule. Shared object
    // In the future we may create versions that are owned as well, to allow module-authority to assert its control over
    // `key + store` objects.
    struct Capsule<T: store> has key {
        id: UID,
        contents: Option<T>
    }

    struct Key has store, copy, drop {}
    struct Witness has drop {}

    // Helper function
    public entry fun create<T: store, Transfer>(
        obj: T,
        module_auth: vector<address>,
        owner: vector<address>,
        ctx: &mut TxContext
    ) {
        let transfer_auth = tx_authority::type_into_address<Transfer>();
        let capsule = create_(obj, module_auth, owner, vector[transfer_auth], ctx);
        transfer::share_object(capsule);
    }

    public fun create_<T: store>(
        obj: T,
        module_auth: vector<address>,
        owner: vector<address>,
        transfer_auth: vector<address>,
        ctx: &mut TxContext
    ): Capsule<T> {
        let capsule = Capsule {
            id: object::new(ctx),
            contents: option::some(obj)
        };

        let auth = tx_authority::begin_with_type(&Witness {});
        let typed_id = typed_id::new(&capsule);

        ownership::initialize(&mut capsule.id, typed_id, module_auth, &auth);
        ownership::as_shared_object_(&mut capsule.id, owner, transfer_auth, &auth);

        capsule        
    }

    // We are able to return capsule to another transaction, knowing that they will have to return it and have it shared here
    // because Capsule does not have `store`.
    public fun return_and_share<T: store>(capsule: Capsule<T>) {
        transfer::share_object(capsule);
    }

    public fun borrow<T: store>(capsule: &Capsule<T>, auth: &TxAuthority): &T {
        assert!(ownership::is_authorized_by_owner(&capsule.id, auth), ENO_OWNER_AUTHORITY);
        assert!(option::is_some(&capsule.contents), ECAPSULE_IS_EMPTY);

        option::borrow(&capsule.contents)
    }

    public fun borrow_mut<T: store>(capsule: &mut Capsule<T>, auth: &TxAuthority): &mut T {
        assert!(ownership::is_authorized_by_owner(&capsule.id, auth), ENO_OWNER_AUTHORITY);
        assert!(option::is_some(&capsule.contents), ECAPSULE_IS_EMPTY);

        option::borrow_mut(&mut capsule.contents)
    }

    // Unfortunately we cannot delete shared objects In Sui, which would be ideal. This means that this capsule, as a shared object,
    // will persist in memory forever despite being useless. This is why we need the Option<T> wrapper for contents.
    public fun extract<T: store>(capsule: &mut Capsule<T>, auth: &TxAuthority): T {
        assert!(ownership::is_authorized_by_transfer(&capsule.id, auth), ENO_TRANSFER_AUTHORITY);
        assert!(option::is_some(&capsule.contents), ECAPSULE_IS_EMPTY);

        // Set the owner to none, so it doesn't get picked by an indexer as owned by anyone
        ownership::transfer(&mut capsule.id, vector[], auth);
        option::extract(&mut capsule.contents)
    }

    public fun extend<T: store>(capsule: &mut Capsule<T>, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&capsule.id, auth), ENO_OWNER_AUTHORITY);

        &mut capsule.id
    }

    // ========== Getter Functions ==========

    public fun is_empty<T: store>(capsule: &Capsule<T>): bool {
        option::is_some(&capsule.contents)
    }

    // ========== Alternative Dynamic Capsules ==========
    // We may or may not actually use this
    // It might be cool to have the Capsule be untyped (no `T`), or it might be interesting to store multiple objects
    // as a combined 'package'. With dynamic fields we can store an arbitrary number of objects, but the management is a bit
    // more complex (all of the keys and such). It might be best to give this an entirely different API from the static capsule.
    // TO DO: This is incomplete so far

    // Dynamic capsule; stores contents in a dynamic field
    struct Capsule_ has key {
        id: UID
    }

    public fun create_dynamic<T: store>(obj: T, ctx: &mut TxContext): Capsule_ {
        let capsule = Capsule_ { id: object::new(ctx) };
        dynamic_field::add(&mut capsule.id, Key {}, obj);
        capsule
    }
}