module ownership::ownership {
    use std::option::{Self, Option};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::dynamic_field;

    use sui_utils::typed_id::{Self, TypedID};
    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::typed_id::{Self, TypedID};
    
    use ownership::tx_authority::{Self, TxAuthority};

    // error enums
    const ENO_MODULE_AUTHORITY: u64 = 0;
    const ENO_OWNER_AUTHORITY: u64 = 1;
    const ENO_TRANSFER_AUTHORITY: u64 = 2;
    const EUID_DOES_NOT_BELONG_TO_OBJECT: u64 = 3;
    const EOBJECT_NOT_INITIALIZED: u64 = 4;
    const EOBJECT_ALREADY_INITIALIZED: u64 = 5;
    const EOWNER_ALREADY_INITIALIZED: u64 = 6;

    // Dynamic field key for Ownership struct
    struct Key has store, copy, drop {}

    // Is it safe to have 'copy' and 'drop' here? Probably
    // Do we need to store 'type'? Probably
    // TO DO: it might be possible to initialize an owner, transfer auth, then drop both of them, and
    // then have the module re-initialize with a new owner and transfer auth. This isn't desired behavior;
    // see if it's possible.
    // We might add some 'was initialized for owner' boolean here perhaps
    struct Ownership has store, copy, drop {
        module_auth: vector<address>,
        owner: vector<address>,
        transfer_auth: vector<address>,
        type: StructTag,
        is_shared: Option<bool>
    }

    // ======= Module Authority =======

    // I wish we didn't have to use a 'typed-id' to initialize, but `initialize(&mut object.id, &object)`
    // gives the error `Invalid borrow of variable, it is still being mutably borrowed by another reference`.
    // Hence why we have to break the type verification step into two function calls

    // Set the module authority as the default authority-witness for the module declaring `T`
    public fun initialize_with_module_authority<T: key>(uid: &mut UID, typed_id: TypedID<T>, auth: &TxAuthority) {
        let module_authority = tx_authority::witness_addr<T>();
        initialize(uid, typed_id, vector[module_authority], auth);
    }

    // In this case, ownership of UID reverts to Sui root-level ownership
    public fun initialize_without_module_authority<T: key>(uid: &mut UID, typed_id: TypedID<T>, auth: &TxAuthority) {
        initialize(uid, typed_id, vector::empty(), auth);
    }

    // If module-authority is not set here, it can never be set, meaning owner and tranfser authority
    // can never be set either. The ability to obtain a mutable reference to UID is proof-of-ownership
    // As such, the object should either by owned (root-level) or wrapped; never shared (root-level)
    public fun initialize<T: key>(
        uid: &mut UID,
        typed_id: TypedID<T>,
        module_authority: vector<address>,
        auth: &TxAuthority
    ) {
        assert!(!is_initialized(uid), EOBJECT_ALREADY_INITIALIZED);
        assert!(object::uid_to_inner(uid) == typed_id::to_id(typed_id), EUID_DOES_NOT_BELONG_TO_OBJECT);
        assert!(tx_authority::is_signed_by_module<T>(auth), ENO_MODULE_AUTHORITY);

        let ownership = Ownership {
            module_auth: module_authority,
            owner: vector::empty(),
            transfer_auth: vector::empty(),
            type: struct_tag::get<T>(),
            // this won't be determined until we call `as_shared_object` or `as_owned_object`
            is_shared: option::none()
        };

        dynamic_field::add(uid, Key { }, ownership);
    }

    // Requires module and owner authority
    // Note that in case module-authority is empty, we allow the owner to unilaterally add one
    // This means an asset can migrate between module-authorities
    public fun add_module_authority(uid: &mut UID, new_authority: address, auth: &TxAuthority) {
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });

        if (!vector::contains(&ownership.module_auth, &new_authority)) {
            vector::push_back(&mut ownership.module_auth, new_authority);
        };
    }

    // Requires module and owner authority
    public fun remove_module_authority(uid: &mut UID, authority: address, auth: &TxAuthority) {
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        let (exists, i) = vector::index_of(&ownership.module_auth, &authority);
        if (exists) {
            vector::remove(&mut ownership.module_auth, i);
        };
    }

    // Requires module and owner authority
    // Module authority is removed, and all module permissions now default to true.
    // After it is ejected, module authority can never be added again.
    public fun remove_all_module_authorities(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.module_auth = vector::empty();
    }

    // ======= Transfer Authority =======

    // Convenience function
    public fun as_shared_object<Transfer>(
        uid: &mut UID,
        owner: vector<address>,
        auth: &TxAuthority
    ) {
        let transfer = tx_authority::type_into_address<Transfer>();
        as_shared_object_(uid, owner, vector[transfer], auth);
    }

    // We have to set both an owner and a transfer authority at the same time. Module authority must exist and
    // approve this. This initialize can only every be done once per object.
    public fun as_shared_object_(
        uid: &mut UID,
        owner: vector<address>,
        transfer_auth: vector<address>,
        auth: &TxAuthority
    ) {
        assert!(is_initialized(uid), EOBJECT_NOT_INITIALIZED);
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        assert!(option::is_none(&ownership.is_shared), EOWNER_ALREADY_INITIALIZED);

        ownership.is_shared = option::some(true);
        ownership.owner = owner;
        ownership.transfer_auth = transfer_auth;
    }

    // In this case no owner can ever be set, meaning ownership reverts to Sui's root-level ownership system
    // This means that a reference to this object, such as `&mut T` is all the authority that is needed
    // Note that transfer authority also cannot be set and has no meaning
    public fun as_owned_object(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_initialized(uid), EOBJECT_NOT_INITIALIZED);
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        assert!(option::is_none(&ownership.is_shared), EOWNER_ALREADY_INITIALIZED);

        ownership.is_shared = option::some(false);
    }

    // Requires transfer and owner authority
    public fun add_transfer_auth(uid: &mut UID, new_authority: address, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_TRANSFER_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        if (!vector::contains(&ownership.transfer_auth, &new_authority)) {
            vector::push_back(&mut ownership.transfer_auth, new_authority);
        };
    }

    // Requires transfer and owner authority
    public fun remove_transfer_auth(uid: &mut UID, authority: address, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_TRANSFER_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        let (exists, i) = vector::index_of(&ownership.transfer_auth, &authority);
        if (exists) {
            vector::remove(&mut ownership.transfer_auth, i);
        };
    }

    // Requires owner and transfer authority
    // This ejects the transfer authority, and it can never be set again
    public fun make_owner_immutable(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_TRANSFER_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.transfer_auth = vector::empty();
    }

    // Requires transfer authority. Does NOT require ownership or creator authority.
    // This means the specified transfer authority can change ownership arbitrarily, without the current
    // owner being the sender of the transaction.
    // This is useful for marketplaces, reclaimers, and collateral-repossession
    public fun transfer(uid: &mut UID, new_owner: vector<address>, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_TRANSFER_AUTHORITY);

        let ownership = dynamic_field::borrow_mut<Key, Ownership>(uid, Key { });
        ownership.owner = new_owner;
    }

    // ======= Authority Checkers =======

    public fun is_initialized(uid: &UID): bool {
        dynamic_field::exists_(uid, Key { })
    }

    /// Defaults to `true` if the object is initialized but the module authority is not set.
    public fun is_authorized_by_module(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (vector::is_empty(&ownership.module_auth)) true
            else {
                tx_authority::has_k_of_n_signatures(&ownership.module_auth, 1, auth)
            }
        }
    }

    /// Defaults to `false` if transfer authority is not set.
    public fun is_authorized_by_transfer(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (vector::is_empty(&ownership.transfer_auth)) false
            else {
                tx_authority::has_k_of_n_signatures(&ownership.transfer_auth, 1, auth)
            }
        }
    }

    /// Defaults to `true` if owner is not set.
    public fun is_authorized_by_owner(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else {
            let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
            if (vector::is_empty(&ownership.owner)) true
            else {
                tx_authority::has_k_of_n_signatures(&ownership.owner, 1, auth)
            }
        }
    }

    // ========== Getter Functions =========

    public fun get_type(uid: &UID): Option<StructTag> {
        if (!dynamic_field::exists_(uid, Key { })) {
            return option::none()
        };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        option::some(ownership.type)
    }

    public fun get_ownership(
        uid: &UID
    ): (vector<address>, vector<address>, vector<address>, Option<StructTag>, Option<bool>) {
        if (!dynamic_field::exists_(uid, Key { })) {
            return (vector::empty(), vector::empty(), vector::empty(), option::none(), option::none())
        };

        let ownership = dynamic_field::borrow<Key, Ownership>(uid, Key { });
        (
            ownership.module_auth,
            ownership.owner,
            ownership.transfer_auth,
            option::some(ownership.type),
            ownership.is_shared
        )
    }
}