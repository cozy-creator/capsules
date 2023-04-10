module transfer_system::collateralization {
    use std::vector;
    use std::option::{Self, Option};

    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};

    use ownership::ownership;
    use ownership::tx_authority;

    use sui_utils::struct_tag;

    struct Request<phantom A, phantom C> has key, store {
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
        grace_period: Option<u64>,
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

    // ========== Error enums ==========
    const ENO_OWNER_AUTH: u64 = 0;
    const EINVALID_ASSET_LENDER: u64 = 1;
    const EINVALID_OBJECT_TYPE: u64 = 2;
    const EINVALID_DUE_DATE: u64 = 3;

    // Request status enums
    const REQUEST_INITIALIZED: u8 = 0;
    const REQUEST_ACCEPTED: u8 = 1;
    const REQUEST_COMPLETED: u8 = 2;
    const REQUEST_OVERDUE: u8 = 3;

    public fun initialize<A: key, C: key>(
        clock: &Clock,
        asset: &UID,
        collateral: &UID,
        lender: address,
        due_date: u64,
        ctx: &mut TxContext
    ) {
        let request = initialize_<A, C>(clock, asset, collateral, lender, due_date, ctx);
        transfer::share_object(request)
    }

    public fun initialize_<A: key, C: key>(
        clock: &Clock,
        asset: &UID,
        collateral: &UID,
        lender: address,
        due_date: u64,
        ctx: &mut TxContext
    ): Request<A, C> {
        // Ensures that the tx sender owns the collateral item
        let auth = tx_authority::begin(ctx);
        assert!(ownership::is_authorized_by_owner(collateral, &auth), ENO_OWNER_AUTH);

        // Ensures that the lender owns the item to be borrowed
        let asset_owner = ownership::get_owner(asset);
        assert!(vector::contains(option::borrow(&asset_owner), &lender), EINVALID_ASSET_LENDER);
        
        // Ensures that the collateral type is valid
        assert!(match_object_type<C>(collateral), EINVALID_OBJECT_TYPE);

        // Ensures that the asset type is valid
        assert!(match_object_type<A>(asset), EINVALID_OBJECT_TYPE);
       
        // Ensures that the due date is in the future
        assert!(clock::timestamp_ms(clock) < due_date, EINVALID_DUE_DATE);

        let request = Request {
            id: object::new(ctx),
            asset_id: object::uid_to_inner(asset),
            collateral_id: object::uid_to_inner(collateral),
            grace_period: option::none(),
            due_date,
            status: REQUEST_INITIALIZED,
            authority: CAuthority {
                lender,
                borrower: tx_context::sender(ctx)
            }
        };

        request
    }

    // ========== Helper functions ===========

    fun match_object_type<T>(object: &UID): bool {
        let object_type = ownership::get_type(object);
        assert!(option::is_some(&object_type), 0);

        option::destroy_some(object_type) == struct_tag::get<T>()
    }
}