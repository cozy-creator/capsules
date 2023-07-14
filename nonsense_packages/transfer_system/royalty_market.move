module transfer_system::royalty_market {
    use std::type_name::{Self, TypeName};
    use std::option::{Self, Option};

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::transfer;

    use capsule::capsule::Capsule;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::publish_receipt::{Self, PublishReceipt};

    use sui_utils::encode;
    use sui_utils::struct_tag;

    use transfer_system::transfer_freezer;

    struct Witness has drop {}

    struct Royalty has key, store {
        id: UID,
        /// The type name of the object associated with the royalty
        type: TypeName,
        /// The basis point value for the royalty
        bps_value: u16,
        /// The address creator or rights holder associated with the royalty
        creator: address
    }

    /// A struct used to capture and store the specific details of a royalty payment associated with an item
    struct RoyaltyPayment {
        /// The type name of the object associated with the royalty
        type: TypeName,
        /// ID of the item associated with the royalty payment
        item: ID,
        /// The amount of the royalty payment
        value: u64,
        /// The address of the creator or rights holder who is receiving the royalty payment
        creator: address
    }

    // ========== Error constants==========

    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EINVALID_PUBLISH_RECEIPT: u64 = 1;
    const ENO_ITEM_TYPE: u64 = 3;
    const EITEM_TYPE_MISMATCH: u64 = 4;
    const EITEM_RECEIPT_MISMATCH: u64 = 5;
    const EINVALID_ROYALTY_SPLITS_TOTAL: u64 = 6;
    const EINVALID_ROYALTY_PAYMENT: u64 = 7;
    const ETRANSFER_FREEZED: u64 = 8;

    const BPS_BASE_VALUE: u16 = 10_000;

    // ========== Royalty functions ==========

    /// Create a new royalty object for type `T` and returns it
    /// Performs checks to ensure that the `PublishReceipt` originates from the same package as the type `T`
    /// 
    /// The creator or rights holder associated with the created royalty is set to the transaction sender
    public fun create_royalty<T>(
        receipt: &PublishReceipt,
        bps_value: u16,
        ctx: &mut TxContext
    ): Royalty {
        let creator = tx_context::sender(ctx);
        create_royalty_<T>(receipt, bps_value, creator, ctx)
    }

    /// Create a new royalty object for type `T` and returns it
    /// Performs checks to ensure that the `PublishReceipt` originates from the same package as the type `T`
    public fun create_royalty_<T>(
        receipt: &PublishReceipt,
        bps_value: u16,
        creator: address,
        ctx: &mut TxContext
    ):  Royalty {
        assert!(publish_receipt::did_publish<T>(receipt), EINVALID_PUBLISH_RECEIPT);

         Royalty {
            id: object::new(ctx),
            type: type_name::get<T>(),
            bps_value,
            creator
        }
    }

    /// Transfer an item of the type `T` to a new owner
    /// Performs a check to ensure that the item being transferred is really of the type `T`
    /// Performs a check to ensure that the `RoyaltyPayment` corresponds to the item being transferred
    /// Performs a check to ensure that the exact royalty amount specified in the given `RoyaltyPayment` is being paid
    /// 
    /// A `TxAuthority` struct will be constructed using the witness royalty market
    /// The contructed auth will later be used to authorize the item transfer
    public fun transfer<T: key, C>(
        uid: &mut UID,
        payment: RoyaltyPayment,
        coin: Coin<C>,
        new_owner: Option<address>
    ) {
        assert!(!transfer_freezer::is_transfer_freezed(uid), ETRANSFER_FREEZED);
        assert!(type_name::get<T>() == payment.type, EITEM_TYPE_MISMATCH);
        // if(!is_capsule<T>(uid)) { assert_valid_item_type<T>(uid) };

        let RoyaltyPayment { item, value, creator, type: _ } = payment;
        assert!(object::uid_to_inner(uid) == item, EITEM_RECEIPT_MISMATCH);
        assert!(coin::value(&coin) == value, EINVALID_ROYALTY_PAYMENT);
        
        let auth = tx_authority::begin_with_type(&Witness {});

        transfer::public_transfer(coin, creator);
        ownership::transfer(uid, new_owner, &auth);
    }

    // Convenience function
    public fun transfer_to_object<T: key + store, C, O: key>(
        uid: &mut UID,
        payment: RoyaltyPayment,
        coin: Coin<C>, 
        object: &O
    ) {
        let addr = object::id_address(object);
        transfer<T, C>(uid, payment, coin, option::some(addr));
    }

    // Convenience function
    public fun transfer_to_type<T: key + store, C, W>(
        uid: &mut UID,
        payment: RoyaltyPayment,
        coin: Coin<C>
    ) {
        let addr = encode::type_into_address<W>();
        transfer<T, C>(uid, payment, coin, option::some(addr));
    }

    /// Calculate the royalty value or amount based on the given value and Royalty.
    public fun calculate_royalty(royalty: &Royalty, value: u64): u64 {
        let bps_value = bps_value(royalty);
        let multiple = (bps_value as u64) * value;

        multiple / (BPS_BASE_VALUE as u64)
    }

    /// Create a `RoyaltyPayment` for an item of type `T`
    /// Performs a check to ensure that the item is of the type `T`
    /// 
    /// This function calculates the royalty value or amount based on the given Royalty and item price. 
    /// The result is placed in the constructed `RoyaltyPayment`
    public fun create_payment<T>(item: &UID, royalty: &Royalty, price: u64): RoyaltyPayment {
        assert_valid_item_type<T>(item);
        let value = calculate_royalty(royalty, price);
        
        RoyaltyPayment {
            value,
            type: royalty.type,
            creator: royalty.creator,
            item: object::uid_to_inner(item)
        }
    }

    // Convenience function
    public fun freeze_with_signer(
        uid: &mut UID,
        ctx: &mut TxContext,
        auth: &TxAuthority
    ) {
        let freezer = tx_context::sender(ctx);
        freeze_transfer(uid, freezer, auth)
    }

    // Convenience function
    public fun freeze_with_type<T>(
        _: &T,
        uid: &mut UID,
        auth: &TxAuthority
    ) {
        let freezer = encode::type_into_address<T>();
        freeze_transfer(uid, freezer, auth)
    }

    // Convenience function
    public fun freeze_with_package_witness<T: drop>(
        _: T,
        uid: &mut UID,
        auth: &TxAuthority
    ) {
        let freezer = object::id_to_address(&encode::package_id<T>());
        freeze_transfer(uid, freezer, auth)
    }

    public fun freeze_transfer(
        uid: &mut UID,
        freezer: address,
        auth: &TxAuthority
    ) {
        transfer_freezer::freeze_transfer(uid, freezer, auth)
    }

    public fun unfreeze_transfer(uid: &mut UID, auth: &TxAuthority) {
        transfer_freezer::unfreeze_transfer(uid, auth)
    }

    public fun return_and_share(royalty: Royalty) {
        transfer::share_object(royalty)
    }

    // ========== Getter functions =========

    public fun bps_value(royalty: &Royalty): u16 {
        royalty.bps_value
    }

    public fun creator(royalty: &Royalty): address {
        royalty.creator
    }

    public fun payment_value(payment: &RoyaltyPayment): u64 {
        payment.value
    }

    // ========== Helper functions ==========

    public fun assert_valid_item_type<T>(uid: &UID) {
        let type = ownership::get_type(uid);
        assert!(option::is_some(&type), ENO_ITEM_TYPE);
        assert!(option::destroy_some(type) == struct_tag::get<T>(), EITEM_TYPE_MISMATCH);
    }

    public fun assert_royalty_type<T>(royalty: &Royalty) {
        assert!(type_name::get<T>() == royalty.type, EITEM_TYPE_MISMATCH);
    }

    public fun is_capsule<T: key + store>(uid: &UID): bool {
        option::destroy_some(ownership::get_type(uid)) == struct_tag::get<Capsule<T>>()
    }
}