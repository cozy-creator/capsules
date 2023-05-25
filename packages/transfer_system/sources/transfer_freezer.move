module transfer_system::transfer_freezer {
    use sui::object::UID;
    use sui::dynamic_field;

    use ownership::ownership;
    use ownership::permission::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};

    struct Freeze has copy, store, drop {
        freezer: address
    }

    struct Key has copy, store, drop {}

    const EOWNER_UNAUTHORIZED: u64 = 0;
    const ETRANSFER_NOT_FREEZED: u64 = 1;
    const ETRANSFER_ALREADY_FREEZED: u64 = 2;
    const EINVALID_FREEZER_AUTHORITY: u64 = 3;

    /// Freezes the transfer of an object, restricting ownership transfers.
    /// 
    /// Arguments:
    /// - `uid`: Mutable reference to the UID of the object.
    /// - `freezer`: The address attempting to freeze the transfer.
    /// - `auth`: Transaction authority used for authentication.
    /// 
    /// Preconditions:
    /// - The caller must have the owner permission for the object.
    /// - The transfer of the object must not be already frozen.
    /// 
    /// Postconditions:
    /// - The transfer of the object is frozen, preventing ownership transfers.
    /// 
    /// Errors:
    /// - EOWNER_UNAUTHORIZED: The caller does not have the necessary owner permission.
    /// - ETRANSFER_ALREADY_FREEZED: The transfer of the object is already frozen.
    public fun freeze_transfer(uid: &mut UID, freezer: address, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(uid, auth), EOWNER_UNAUTHORIZED);
        assert!(!is_transfer_freezed(uid), ETRANSFER_ALREADY_FREEZED);

        dynamic_field::add<Key, Freeze>(uid, Key { }, Freeze { freezer })
    }

    /// Unfreezes the transfer of an object, allowing ownership transfers.
    /// 
    /// Arguments:
    /// - `uid`: Mutable reference to the UID of the object.
    /// - `auth`: Transaction authority used for authentication.
    /// 
    /// Preconditions:
    /// - The transfer of the object must be currently frozen.
    /// 
    /// Postconditions:
    /// - The transfer of the object is unfrozen, allowing ownership transfers.
    /// 
    /// Errors:
    /// - ETRANSFER_NOT_FREEZED: The transfer of the object is not currently frozen.
    /// - EINVALID_FREEZER_AUTHORITY: The authority of the original freezer is invalid.
    public fun unfreeze_transfer(uid: &mut UID, auth: &TxAuthority) {
        assert!(is_transfer_freezed(uid), ETRANSFER_NOT_FREEZED);

        let Freeze { freezer } = dynamic_field::remove<Key, Freeze>(uid, Key { });
        assert!(tx_authority::has_permission<ADMIN>(freezer, auth), EINVALID_FREEZER_AUTHORITY)
    }

    /// Checks if the transfer of an object is currently frozen.
    /// 
    /// Arguments:
    /// - `uid`: The UID of the object.
    /// 
    /// Returns:
    /// - A boolean value indicating whether the transfer is frozen (`true`) or not (`false`).
    public fun is_transfer_freezed(uid: &UID): bool {
       dynamic_field::exists_(uid, Key { })
    }
}