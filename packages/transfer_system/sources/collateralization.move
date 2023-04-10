module transfer_system::collateralization {
    use sui::object::{ID, UID};

    struct Request<phantom A, phantom C> has key {
        id: UID,
        /// The collateral authority, contains the address of the lender and borrower
        authority: CAuthority,
        /// The ID of the asset to requested be borrowed
        asset_id: ID,
        /// The ID of the asset to being offered as collateral
        collateral_id: ID,
        /// The date when the asset is expected to be returned
        due_date: u64,
        /// The period of time which the asset return can be delayed with after the due date has elapsed
        grace_period: u64,
        /// The status of the request
        status: u8
    }

    // `CAuthority`, short for `CollateralAuthority`
    struct CAuthority has store, drop {
        lender: address,
        borrower: address
    }

    struct Vault has key {
        id: UID,
        /// The ID of the request where this vault belongs to
        request_id: ID,

        // A `transfer_system::collateralization::Key { }` is attached to this object
        // It used to store the collateral asset
    }

    struct Key has store, copy, drop { }

    const REQUEST_INITIALIZED: u8 = 0;
    const REQUEST_ACCEPTED: u8 = 1;
    const REQUEST_REPAID: u8 = 2;
    const REQUEST_OVERDUE: u8 = 3;
}