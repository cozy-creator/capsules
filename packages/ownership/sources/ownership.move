// Sui's Ownership System For Shared Objects
//
// For owned-objects, Sui defines the owner at the system-level, hence there is no need for us to
// store an owner here. Owned-objects have 'referential authority'; if you can obtain a reference to an
// object, you own it. This is the basis of Sui Ownership.
// Furthermore, we do not add a transfer-authority because transferring authority is also handled by
// Sui's system-level transfer rules.
// All this function does is store a struct tag so you can assert later who the native module is and
// what the type the object is just from its UID.

module ownership::ownership {
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::dynamic_field;

    use sui_utils::encode;
    use sui_utils::dynamic_field2;
    use sui_utils::typed_id::{Self, TypedID};
    use sui_utils::struct_tag::{Self, StructTag};
    
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::action::ADMIN;

    // error enums
    const ENO_PACKAGE_AUTHORITY: u64 = 0;
    const ENO_OWNER_AUTHORITY: u64 = 1;
    const ENO_TRANSFER_AUTHORITY: u64 = 2;
    const EUID_DOES_NOT_BELONG_TO_OBJECT: u64 = 3;
    const EOBJECT_NOT_INITIALIZED: u64 = 4;
    const EOBJECT_ALREADY_INITIALIZED: u64 = 5;
    const EOWNER_ALREADY_INITIALIZED: u64 = 6;
    const EOBJECT_MUST_NOT_HAVE_OWNER: u64 = 7;
    const ETRANSFER_AUTH_MUST_BE_EJECTED_FIRST: u64 = 8;

    // Is it safe to have 'copy' and 'drop' here? Probably
    // Do we need to store 'type'? Probably
    // TO DO: it might be possible to initialize an owner, transfer auth, then drop both of them, and
    // then have the module re-initialize with a new owner and transfer auth. This isn't desired behavior;
    // see if it's possible.
    struct Ownership has store, copy, drop {
        owner: Option<address>,
        transfer_auth: Option<address>,
        type: StructTag
    }

    // Dynamic field key for storing the Ownership struct
    struct Key has store, copy, drop { }

    // Dynamic field key for indicating that an object is frozen
    struct Frozen has store, copy, drop { }

    // Action type allowing access to the UID
    struct INITIALIZE {} // Used by packages to initialize object they create
    struct UID_MUT {} // Used to access UID_MUT
    struct TRANSFER {} // Used by an object's transfer-authority to transfer the object (change owner).
    struct MIGRATE {} // Used to change (migrate) the transfer-authority
    struct FREEZE {} // Used to freeze the transfer-authority

    // ======= Initialize Ownership =======
    // The caller needs to supply a 'typed-id' here because `as_owned_object(&mut object.id, &object)`
    // gives the error `Invalid borrow of variable, it is still being mutably borrowed by another reference`.
    // This allows the caller to prove that the UID belongs to the specified object-type, allowing us to
    // figure out what module produced this object.

    public fun as_owned_object<T: key>(
        uid: &mut UID,
        typed_id: TypedID<T>,
        auth: &TxAuthority
    ) {
        assert_valid_initialization(uid, typed_id, auth);

        let ownership = Ownership {
            owner: option::none(),
            transfer_auth: option::none(),
            type: struct_tag::get<T>()
        };

        dynamic_field::add(uid, Key { }, ownership);
    }
    
    // Convenience function
    public fun as_shared_object<T: key, Transfer>(
        uid: &mut UID,
        typed_id: TypedID<T>,
        owner: address,
        auth: &TxAuthority
    ) {
        let transfer = encode::type_into_address<Transfer>();
        as_shared_object_(uid, typed_id, owner, transfer, auth);
    }

    public fun as_shared_object_<T: key>(
        uid: &mut UID,
        typed_id: TypedID<T>,
        owner: address,
        transfer_auth: address,
        auth: &TxAuthority
    ) {
        assert_valid_initialization(uid, typed_id, auth);

        let ownership = Ownership {
            owner: option::some(owner),
            transfer_auth: option::some(transfer_auth),
            type: struct_tag::get<T>()
        };

        dynamic_field::add(uid, Key { }, ownership);
    }

    // ======= Authority Checkers =======

    public fun assert_valid_initialization<T: key>(uid: &UID, typed_id: TypedID<T>, auth: &TxAuthority) {
        assert!(!is_initialized(uid), EOBJECT_ALREADY_INITIALIZED);
        assert!(object::uid_to_inner(uid) == typed_id::to_id(typed_id), EUID_DOES_NOT_BELONG_TO_OBJECT);
        assert!(tx_authority::can_act_as_package<T, INITIALIZE>(auth), ENO_PACKAGE_AUTHORITY);
    }

    public fun is_initialized(uid: &UID): bool {
        dynamic_field::exists_(uid, Key { })
    }

    // Defaults to `true` if the owner does not exist, or if it is not initialized.
    // That is, without an assigned owner, the reference itself _is_the owner. (Referential authority)
    public fun can_act_as_owner<Action>(uid: &UID, auth: &TxAuthority): bool {
        if (is_destroyed(uid)) false
        else if (!is_initialized(uid)) true
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (option::is_none(&ownership.owner)) true
            else {
                let owner = *option::borrow(&ownership.owner);
                tx_authority::can_act_as_address_on_object<Action>(
                    owner, &ownership.type, object::uid_as_inner(uid), auth)
            }
        }
    }

    // If this is initialized, package authority always exists and is always the native module (the module
    // declaring the object's type). I.e., the package-id corresponding to `0x599::my_module::Witness`.
    public fun can_act_as_declaring_package<Action>(uid: &UID, auth: &TxAuthority): bool {
        if (is_destroyed(uid)) false
        else if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            let package_id = struct_tag::package_id(&ownership.type);
            tx_authority::can_act_as_package_on_object_<Action>(
                package_id, &ownership.type, object::uid_as_inner(uid), auth)
        }
    }

    // Same as above, but uses the object itself, rather than the UID. Note that the UID need not
    // be initialized.
    // Note that this will pass even if the object is 'destroyed', because we do not have access to UID
    public fun can_act_as_declaring_package_<T: key, Action>(obj: &T, auth: &TxAuthority): bool {
        let type = struct_tag::get<T>();
        let package_id = struct_tag::package_id(&type);
        let id = object::id(obj);
        tx_authority::can_act_as_package_on_object_<Action>(package_id, &type, &id, auth)
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun can_act_as_transfer_auth<Action>(uid: &UID, auth: &TxAuthority): bool {
        if (is_destroyed(uid)) false
        else if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (option::is_none(&ownership.transfer_auth)) false
            else {
                let transfer_auth = *option::borrow(&ownership.transfer_auth);
                tx_authority::can_act_as_address_on_object<Action>(
                    transfer_auth, &ownership.type, object::uid_as_inner(uid), auth)
            }
        }
    }

    // For arbitrary addresses that are not one of the main three (owner, package, transfer_auth)
    public fun can_act_as_address_on_object<Action>(principal: address, uid: &UID, auth: &TxAuthority): bool {
        if (is_destroyed(uid)) false
        else if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            let id = object::uid_as_inner(uid);
            tx_authority::can_act_as_address_on_object<Action>(principal, &ownership.type, id, auth)
        }
    }

    // ========== Getter Functions =========

    public fun get_owner(uid: &UID): Option<address> {
        if (!is_initialized(uid)) { return option::none() };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        ownership.owner
    }

    public fun get_package_authority(uid: &UID): Option<ID> {
        if (!is_initialized(uid)) { return option::none() };
        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        option::some(struct_tag::package_id(&ownership.type))
    }

    // public fun get_module_authority(uid: &UID): Option<address> {
    //     if (!is_initialized(uid)) { return option::none() };

    //     let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
    //     let addr = tx_authority::witness_addr_from_struct_tag(&ownership.type);
    //     option::some(addr)
    // }

    public fun get_transfer_authority(uid: &UID): Option<address> {
        if (!is_initialized(uid)) { return option::none() };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        ownership.transfer_auth
    }

    public fun get_type(uid: &UID): Option<StructTag> {
        if (!is_initialized(uid)) { return option::none() };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        option::some(ownership.type)
    }

    // ======== Transfer Function ========
    // Used by the assigned transfer module

    // Requires transfer authority. Does NOT require ownership or module authority.
    // This means the specified transfer authority can change ownership unilaterally, without the current
    // owner being the sender of the transaction.
    // This is useful for marketplaces, reclaimers, and collateral-repossession.
    public fun transfer(uid: &mut UID, new_owner: Option<address>, auth: &TxAuthority) {
        assert!(can_act_as_transfer_auth<TRANSFER>(uid, auth), ENO_TRANSFER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.owner = new_owner;
    }

    // Only the transfer-auth can eject itself. Owner authority is not required.
    public fun eject_transfer_auth(uid: &mut UID, auth: &TxAuthority) {
        assert!(can_act_as_transfer_auth<MIGRATE>(uid, auth), ENO_TRANSFER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.transfer_auth = option::none();
    }

    // Requires the action of both the package and the current owner.
    // This means packages _cannot_ change their transfer-functionality unilaterally.
    // Transfer-auth must be undefined; i.e., never set before, or ejected.
    // If the new transfer-auth requires initialization, that must be called separately after this.
    public fun set_transfer_auth(uid: &mut UID, new_auth: address, auth: &TxAuthority) {
        assert!(can_act_as_declaring_package<MIGRATE>(uid, auth), ENO_PACKAGE_AUTHORITY);
        assert!(can_act_as_owner<MIGRATE>(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        assert!(option::is_none(&ownership.transfer_auth), ETRANSFER_AUTH_MUST_BE_EJECTED_FIRST);

        ownership.transfer_auth = option::some(new_auth);
    }

    // Transfer-auth is set to a non-existent address, meaning the owner can never be changed
    public fun make_owner_immutable(uid: &mut UID, auth: &TxAuthority) {
        set_transfer_auth(uid, @0x0, auth);
    }

    // ======= Freezing =======
    // Only transfer_auth has the right to freeze an object. It cannot be done by owner or packages.

    public fun freeze_transfer(uid: &mut UID, auth: &TxAuthority) {
        assert!(can_act_as_transfer_auth<FREEZE>(uid, auth), ENO_TRANSFER_AUTHORITY);

        dynamic_field2::set(uid, Frozen { }, true);
    }

    public fun unfreeze_transfer(uid: &mut UID, auth: &TxAuthority) {
        assert!(can_act_as_transfer_auth<FREEZE>(uid, auth), ENO_TRANSFER_AUTHORITY);

        dynamic_field2::drop<Frozen, bool>(uid, Frozen { });
    }

    public fun is_frozen(uid: &UID): bool {
        dynamic_field::exists_(uid, Frozen { })
    }

    // ======= TxAuthority Extended =======
    // We can add to tx-authority for objects using Ownership-specific logic

    // This only works for objects that have not been initialized yet, or have no owner.
    // In this case, mere possession is sufficient to prove ownership, so no `TxAuthority` is needed
    // here.
    public fun begin_with_object_id(
        uid: &UID
    ): TxAuthority {
        let owner_maybe = get_owner(uid);
        assert!(option::is_none(&owner_maybe), EOBJECT_MUST_NOT_HAVE_OWNER);

        tx_authority::begin_with_object_id(uid)
    }

    // If this object has an owner, then the owner must have given ADMIN authority to this transaction
    // for you to claim ownership of the object. This means that action-chaining is not possible,
    // in the sense that if the owner grants you an EDIT action, that does not give you EDIT rights
    // over this object.
    // TO DO: should we change this? Probably?
    public fun add_object_id(
        uid: &UID,
        auth: &TxAuthority
    ): TxAuthority {
        let owner_maybe = get_owner(uid);
        if (option::is_some(&owner_maybe)) {
            let owner = option::destroy_some(owner_maybe);
            assert!(tx_authority::can_act_as_address<ADMIN>(owner, auth), ENO_OWNER_AUTHORITY);
        };

        tx_authority::add_object_id(uid, auth)
    }

    // ======= Destroying Shared Objects =======
    // This compensates for the inability to destroy Shared Objects in Sui currently

    // This key's existence signifies the object is destroyed
    struct IsDestroyed has store, copy, drop { }

    // Cannot be reversed. Only the owner or creator can destroy an object
    public fun destroy(uid: &mut UID, auth: &TxAuthority) {
        assert!(can_act_as_owner<ADMIN>(uid, auth) ||
            can_act_as_declaring_package<ADMIN>(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field::add(uid, IsDestroyed { }, true);
    }

    public fun is_destroyed(uid: &UID): bool {
        dynamic_field::exists_(uid, IsDestroyed { })
    }

    // ======= Extend Pattern Protector =======
    // The problem with the extend pattern is that if anyone can get &mut UID access, they can add
    // lots of junk / spam dynamic fields to your object. Unfortunately, I think this is an acceptable
    // tradeoff versus having to manually gate access to UID. Managing UID access gets quite complex,
    // so it's easiest just to make it public

    // Checks all instances of why an agent needs mutable access to a UID
    // public fun validate_uid_mut(uid: &UID, auth: &TxAuthority): bool {
    //     if (can_act_as_owner<UID_MUT>(uid, auth)) { return true }; // Owner type added
    //     if (can_act_as_package<UID_MUT>(uid, auth)) { return true }; // Witness type added
    //     if (can_act_as_transfer_auth<UID_MUT>(uid, auth)) { return true }; // Transfer type added
    //
    //     false
    // }

    public fun can_borrow_uid_mut(_uid: &UID, _auth: &TxAuthority): bool {
        true
    }
}
