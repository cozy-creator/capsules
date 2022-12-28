module ownership::ownership {
    use std::option::{Self, Option};
    use std::string::String;
    use sui::object::{Self, ID, UID};
    use sui::dynamic_field;
    use sui::tx_context::{Self, TxContext};
    use capsule::module_authority;
    use sui_utils::encode;
    use sui_utils::df_set;
    use metadata::metadata::Creator;

    // error enums
    const ECREATOR_ALREADY_SET: u64 = 0;
    const ENO_MODULE_AUTHORITY: u64 = 0;
    const ENOT_OWNER: u64 = 1;
    const EOWNER_ALREADY_SET: u64 = 2;
    const ENO_TRANSFER_AUTHORITY: u64 = 3;
    const EMISMATCHED_HOT_POTATO: u64 = 4;
    const EUID_AND_OBJECT_MISMATCH: u64 = 5;
    const EINCORRECT_PACKAGE_CREATOR: u64 = 6;
    const EOWNER_MUST_EXIST: u64 = 7;

    struct Key has store, copy, drop { slot: u8 } // = address

    // Slots for Key
    const OWNER: u8 = 0; // Can open the Capsule, add/remove to delegates.
    const TRANSFER: u8 = 1; // Can edit Owner field, which wipes delegates.
    const CREATOR: u8 = 2; // Creator consent needed to edit Metadata, Data, and Inventory. Creator ID as an address

    // ======= Creator Authority =======
    // The ID-address of a creator object

    // You must present the UID _as well as_ the object itself in order for us to verify (1)
    // what package the object came from, and (2) that you are the creator of that package.
    // This prevents arbitrary people from claiming the creator-rights of arbitrary objects.
    // That is to say, even if uid has no 'creator' field set, there is still implicitly a creator
    // in existence that hasn't claimed their creator-status yet
    public fun claim_creator<Object: key>(uid: &mut UID, obj: &Object, creator: &Creator) {
        assert!(!dynamic_field::exists_(id, Key { slot: CREATOR }), ECREATOR_ALREADY_SET);
        assert!(object::uid_to_inner(uid) == object::id_address(obj), EUID_AND_OBJECT_MISMATCH);

        let package_id = encode::package_id<Object>();
        assert!(creator::has_package(creator, package_id), EINCORRECT_PACKAGE_CREATOR);

        dynamic_field::add(id, Key { slot: CREATOR }, object::id_address(creator));
    }

    // Claims and then nullifies creator authority. The owner now has full control
    public fun eject_creator(uid: &mut UID, obj: &Object, creator: &Creator, auth: &TxAuthority) {
        if (!dynamic_field::exists_(id, Key { slot: CREATOR })) {
            claim_creator(uid, obj, creator);
        };

        eject_creator_(uid, auth);
    }

    // If the creator is set to @0x0, then we treat every call as valid by the creator.
    // Requires approval from the creator and owner. Owner must exist.
    public fun eject_creator_(uid: &mut UID, auth: &TxAuthority) {
        assert!(dynamic_field::exists_(id, Key { slot: OWNER }), EOWNER_MUST_EXIST);
        assert!(is_authorized_by_creator(uid, auth), ENO_CREATOR_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        df_set::set(uid, Key { slot: CREATOR }, @0x0);
    }

    // If you want to give creator rights to a different package, claim it first yourself and then
    // transfer creator status to whatever other creator object you like
    public fun transfer_creator(uid: &mut UID, old: &Creator, new: &Creator, auth: &TxAuthority) {
        assert!(is_authorized_by_creator(uid, old, auth), ENO_CREATOR_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        df_set::set(uid, Key { slot: CREATOR }, object::id_address(new));
    }

    // ======= Transfer Authority =======

    // Requires owner and creator authority.
    public fun bind_transfer_authority(uid: &mut UID, addr: address, creator: &Creator, auth: &TxAuthority) {
        assert!(is_authorized_by_creator(uid, creator, auth), ENO_CREATOR_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        df_set::set(uid, Key { slot: TRANSFER }, addr);
    }

    // Convenience function
    public fun bind_transfer_authority_to_type<T>(uid: &mut UID, creator: &Creator, auth: &TxAuthority) {
        bind_transfer_authority(uid, tx_authority::type_into_address<T>(), creator, auth);
    }

    // Convenience function
    public fun bind_transfer_authority_to_object<Object: key>(
        uid: &mut UID,
        obj: &Object,
        creator: &Creator,
        auth: &TxAuthority
    ) {
        bind_transfer_authority(uid, object::id_address(obj), creator, auth);
    }

    // Requires owner and creator authority.
    // This makes ownership non-transferrable until another transfer authority is bound.
    public fun unbind_transfer_authority(uid: &mut UID, creator: &Creator, auth: &TxAuthority) {
        assert!(is_authorized_by_creator(uid, creator, auth), ENO_CREATOR_AUTHORITY);
        assert!(is_authorized_by_owner(uid, auth), ENO_OWNER_AUTHORITY);

        let key = Key { slot: TRANSFER };
        if (dynamic_field::exists_(uid, key)) {
            dynamic_field::remove<Key, address>(uid, key);
        };
    }

    // ========== Transfer Function =========

    // Requires transfer authority. Does NOT require ownership or creator authority.
    // This means the specified transfer authority can change ownership arbitrarily, without the current
    // owner being the sender of the transaction.
    // This is useful for marketplaces, reclaimers, and collateral-repossession
    public fun transfer(id: &mut UID, new_owner: address, auth: &TxAuthority) {
        assert!(is_authorized_by_transfer_authority(uid, auth), ENO_TRANSFER_AUTHORITY);

        let owner = dynamic_field::borrow_mut<Key, address>(id, Key { slot: OWNER });
        *owner = new_owner;
    }

    // ======= Ownership Authority =======
    // Binding requires (1) creator consent, and (2) that an owner does not already exist
    // In order to receive creator consent, the claim_creator function must be called first

    public fun bind_owner(uid: &mut UID, creator: &Creator, owner: address, auth: &TxAuthority) {
        assert!(is_authorized_by_creator(uid, creator, auth), ENO_CREATOR_AUTHORITY);
        assert!(!dynamic_field::exists_(id, Key { slot: OWNER }), EOWNER_ALREADY_SET);

        dynamic_field::add(id, Key { slot: OWNER }, owner);        
    }

    // Convenience function
    public fun bind_owner_to_type<T>(&uid: &mut UID, auth: &TxAuthority) {
        bind_owner(uid, tx_authority::type_into_address<T>(), auth);
    }

    // Convenience function
    public fun bind_owner_to_object<Object: key>(&uid: &mut UID, obj: &Object, auth: TxAuthority) {
        bind_owner(uid, object::id_address(obj), auth);
    }

    // ========== Validity Checker Functions =========

    // If no Creator field is set, this defaults to false
    public fun is_authorized_by_creator(uid: &UID, creator: &Creator, auth: &TxAuthority): bool {
        let key = Key { slot: CREATOR };
        if (!dynamic_field::exists_<Key, address>(uid, key)) { return false };

        let creator_addr = dynamic_field::borrow<Key, address>(uid, key);
        if (creator_addr != object::id_address(creator)) { return false };

        let creator_addr = creator::owner(creator);
        if (creator_addr == @0x0) { 
            // @0x0 is the null-creator address, which we always approve
            return true
        }; 
        tx_authority::is_valid_address(creator_addr, auth)
    }

    // If no transfer field is set, this defaults to false
    public fun is_authorized_by_transfer_authority(uid: &UID, auth: &TxAuthority): bool {
        let key = Key { slot: TRANSFER };
        if (dynamic_field::exists_<Key, address>(uid, key)) {
            let transfer_addr = dynamic_field::borrow<Key, address>(uid, key);
            tx_authority::is_valid_address(transfer_addr, auth)
        } else {
            return false
        }
    }

    // If no owner field is set, this defaults to true
    public fun is_authorized_by_owner(uid: &UID, auth: &TxAuthority): bool {
        let key = Key { slot: OWNER };
        if (dynamic_field::exists_<Key, address>(uid, key)) {
            let owner_addr = dynamic_field::borrow<Key, address>(uid, key);
            tx_authority::is_valid_address(creator_addr, auth)
        } else {
            return true
        }
    }

    // ========== Getter Functions =========

    public fun owner(uid: &UID): Option<address> {
        let key = Key { slot: OWNER };
        if (dynamic_field::exists_(uid, key)) {
            option::some(*dynamic_field::borrow<Key, address>(uid, key))
        } else {
            option::none()
        }
    }

    public fun transfer_authority(uid: &UID): Option<address> {
        let key = Key { slot: TRANSFER };
        if (dynamic_field::exists_(uid, key)) {
            option::some(*dynamic_field::borrow<Key, address>(uid, Key { slot: TRANSFER }))
        } else {
            option::none()
        }
    }

    public fun creator(uid: &UID): Option<ID> {
        let key = Key { slot: CREATOR };
        if (dynamic_field::exists_(uid, key)) {
            let id = object::id_from_address(dynamic_field::borrow<Key, address>(uid, key))
            option::some(id)
        } else {
            option::none()
        }
    }
}