module ownership::ownership {
    use std::ascii::String;
    use std::option::{Self, Option};
    use sui::object::{Self, UID, ID};
    use sui::dynamic_field;
    use sui_utils::dynamic_field2;
    use sui_utils::encode;
    use ownership::tx_authority::{Self, TxAuthority};

    // error enums
    const ENO_MODULE_AUTHORITY: u64 = 0;
    const ENO_OWNER_AUTHORITY: u64 = 1;
    const ENO_TRANSFER_AUTHORITY: u64 = 2;
    const EUID_DOES_NOT_BELONG_TO_PROOF_OBJECT: u64 = 3;
    const EOBJECT_NOT_INITIALIZED: u64 = 4;
    const EOBJECT_ALREADY_INITIALIZED: u64 = 5;
    const ETRANSFER_ALREADY_EXISTS: u64 = 6;
    const EOWNER_ALREADY_EXISTS: u64 = 7;
    const EOWNER_ALREADY_INITIALIZED: u64 = 8;
    // const ETHIS_ASSET_CANNOT_BE_OWNED: u64 = 9;

    // Dynamic field keys
    struct Module has store, copy, drop { } // address
    struct Transfer has store, copy, drop { } // address
    struct Owner has store, copy, drop { } // address
    // The type-name the UID is nested inside of. This signifies that ownership for this UID was
    // initialized
    struct Type has store, copy, drop { } // ascii::string

    // Simple struct used in the initialize process. Wish we didn't have to use this, but
    // `initialize(&mut object.id, &object)` gives the error `Invalid borrow of variable, it is still
    // being mutably borrowed by another reference`. Hence why we have to break the type verification
    // setup into two function calls
    struct ProofOfType has drop {
        id: ID,
        type: String
    }

    public fun setup<T: key>(obj: &T): ProofOfType {
        ProofOfType {
            id: object::id(obj),
            type: encode::type_name<T>()
        }
    }

    // ======= Module Authority =======

    // Convenience function
    public fun initialize(uid: &mut UID, proof: ProofOfType, auth: &TxAuthority) {
        let module_authority = tx_authority::witness_addr_(proof.type);
        initialize_(uid, proof, option::some(module_authority), auth);
    }

    // In this case, ownership of UID reverts to Sui root-level ownership
    public fun initialize_without_module_authority(uid: &mut UID, proof: ProofOfType, auth: &TxAuthority) {
        initialize_(uid, proof, option::none(), auth);
    }

    // If module-authority is not set here, it can never be set, meaning owner and tranfser authority
    // can never be set either. The ability to obtain a mutable reference to UID is proof-of-ownership
    public fun initialize_(
        uid: &mut UID,
        proof: ProofOfType,
        module_authority: Option<address>,
        auth: &TxAuthority
    ) {
        assert!(object::uid_to_inner(uid) == proof.id, EUID_DOES_NOT_BELONG_TO_PROOF_OBJECT);
        assert!(tx_authority::is_signed_by_module_(proof.type, auth), ENO_MODULE_AUTHORITY);
        assert!(!is_initialized(uid), EOBJECT_ALREADY_INITIALIZED);

        dynamic_field::add(uid, Type { }, proof.type);

        if (option::is_some(&module_authority)) {
            dynamic_field::add(uid, Module { }, option::destroy_some(module_authority));
        };
    }

    // Only requires module authority
    public fun migrate_module_authority(uid: &mut UID, new_module_authority: address, auth: &TxAuthority) {
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field2::set(uid, Module { }, new_module_authority);
    }

    // Only requires module authority
    // Module authority is removed, and all module permissions now default to true.
    // After it is ejected, module authority can never be added again.
    public fun eject_module_authority(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field2::drop<Module, address>(uid, Module { });
    }

    // ======= Transfer Authority =======

    // Convenience function
    public fun initialize_owner_and_transfer_authority<Transfer>(uid: &mut UID, owner: address, auth: &TxAuthority) {
        let transfer = tx_authority::type_into_address<Transfer>();
        initialize_owner_and_transfer_authority_(uid, option::some(owner), option::some(transfer), auth);
    }

    // The owner and transfer authority can only ever be initialized once
    // Module authority must exist and approve this
    public fun initialize_owner_and_transfer_authority_(
        uid: &mut UID,
        owner: Option<address>,
        transfer_authority: Option<address>,
        auth: &TxAuthority
    ) {
        let (owner_maybe, transfer_maybe) = (owner(uid), transfer_authority(uid));
        assert!(option::is_none(&owner_maybe) && option::is_none(&transfer_maybe), EOWNER_ALREADY_INITIALIZED);
        assert!(is_initialized(uid), EOBJECT_NOT_INITIALIZED);
        // assert!(option::is_some(&module_authority(uid)), ETHIS_ASSET_CANNOT_BE_OWNED);
        assert!(is_authorized_by_module(uid, auth), ENO_MODULE_AUTHORITY);

        if (option::is_some(&owner)) {
            let addr = option::destroy_some(owner);
            dynamic_field2::set(uid, Owner { }, addr);
        };

        if (option::is_some(&transfer_authority)) {
            let addr = option::destroy_some(transfer_authority);
            dynamic_field2::set(uid, Transfer { }, addr);
        };
    }

    // Requires owner and transfer authority
    public fun migrate_transfer_authority(uid: &mut UID, new_addr: address, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field2::set(uid, Transfer { }, new_addr);
    }

    // Requires transfer authority. Does NOT require ownership or creator authority.
    // This means the specified transfer authority can change ownership arbitrarily, without the current
    // owner being the sender of the transaction.
    // This is useful for marketplaces, reclaimers, and collateral-repossession
    public fun transfer(uid: &mut UID, new_owner: address, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_TRANSFER_AUTHORITY);

        dynamic_field2::set(uid, Owner { }, new_owner);
    }

    // Requires transfer authority
    public fun eject_owner(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_MODULE_AUTHORITY);

        dynamic_field2::drop<Owner, address>(uid, Owner { });      
    }

    // Requires owner and transfer authority
    // This ejects the transfer authority, and it can never be set again
    public fun make_owner_immutable(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer(uid, auth), ENO_MODULE_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        dynamic_field2::drop<Transfer, address>(uid, Transfer { });
    }

    // ======= Authority Checkers =======

    public fun is_initialized(uid: &UID): bool {
        dynamic_field::exists_(uid, Type { })
    }

    /// Defaults to `true` if not set.
    public fun is_authorized_by_module(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else if (!dynamic_field::exists_(uid, Module { })) true
        else {
            let addr = *dynamic_field::borrow<Module, address>(uid, Module { });
            tx_authority::is_signed_by(addr, auth)
        }
    }

    /// Defaults to `false` if not set.
    public fun is_authorized_by_transfer(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else if (!dynamic_field::exists_(uid, Transfer { })) false
        else {
            let addr = *dynamic_field::borrow<Transfer, address>(uid, Transfer { });
            tx_authority::is_signed_by(addr, auth)
        }
    }

    /// Defaults to `true` if not set.
    public fun is_authorized_by_owner(uid: &UID, auth: &TxAuthority): bool {
        if (!is_initialized(uid)) false
        else if (!dynamic_field::exists_(uid, Owner { })) true
        else {
            let addr = *dynamic_field::borrow<Owner, address>(uid, Owner { });
            tx_authority::is_signed_by(addr, auth)
        }
    }

    // ========== Getter Functions =========

    public fun type(uid: &UID): Option<String> {
        if (dynamic_field::exists_(uid, Type { })) {
            option::some(*dynamic_field::borrow<Type, String>(uid, Type { }))
        } else {
            option::none()
        }
    }

    public fun owner(uid: &UID): Option<address> {
        if (dynamic_field::exists_(uid, Owner { })) {
            option::some(*dynamic_field::borrow<Owner, address>(uid, Owner { }))
        } else {
            option::none()
        }
    }

    public fun transfer_authority(uid: &UID): Option<address> {
        if (dynamic_field::exists_(uid, Transfer { })) {
            option::some(*dynamic_field::borrow<Transfer, address>(uid, Transfer { }))
        } else {
            option::none()
        }
    }

    public fun module_authority(uid: &UID): Option<address> {
        if (dynamic_field::exists_(uid, Module { })) {
            let addr = *dynamic_field::borrow<Module, address>(uid, Module { });
            option::some(addr)
        } else {
            option::none()
        }
    }
}