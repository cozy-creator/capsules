module transfer_system::royalty_market {
    use std::option::{Self, Option};

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::transfer;

    use ownership::ownership;
    use ownership::tx_authority;
    use ownership::publish_receipt::{Self, PublishReceipt};

    use sui_utils::encode;
    use sui_utils::struct_tag;

    struct Witness has drop {}

    struct Royalty<phantom T> has key, store {
        id: UID,
        /// The basis point value for the royalty
        bps_value: u16,
        /// The address creator or rights holder associated with the royalty
        creator: address
    }

    /// A struct used to capture and store the specific details of a royalty payment associated with an item
    struct RoyaltyPayment<phantom T> {
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
    ): Royalty<T> {
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
    ):  Royalty<T> {
        assert!(publish_receipt::did_publish<T>(receipt), EINVALID_PUBLISH_RECEIPT);

         Royalty {
            id: object::new(ctx),
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
    public fun transfer<T, C>(
        uid: &mut UID,
        payment: RoyaltyPayment<T>,
        coin: Coin<C>,
        new_owner: Option<address>
    ) {
        assert_valid_item_type<T>(uid);

        let RoyaltyPayment { item, value, creator } = payment;
        assert!(object::uid_to_inner(uid) == item, EITEM_RECEIPT_MISMATCH);
        assert!(coin::value(&coin) == value, EINVALID_ROYALTY_PAYMENT);
        
        let auth = tx_authority::begin_with_type(&Witness {});

        transfer::public_transfer(coin, creator);
        ownership::transfer(uid, new_owner, &auth);
    }

    // Convenience function
    public fun transfer_to_object<T, C, O: key>(
        uid: &mut UID,
        payment: RoyaltyPayment<T>,
        coin: Coin<C>, 
        obj: &O
    ) {
        let addr = object::id_address(obj);
        transfer(uid, payment, coin, option::some(addr));
    }

    // Convenience function
    public fun transfer_to_type<T, C, W>(
        uid: &mut UID,
        payment: RoyaltyPayment<T>,
        coin: Coin<C>
    ) {
        let addr = encode::type_into_address<W>();
        transfer(uid, payment, coin, option::some(addr));
    }

    public fun return_and_share<T>(royalty: Royalty<T>) {
        transfer::share_object(royalty)
    }

    /// Calculate the royalty value or amount based on the given value and Royalty.
    public fun calculate_royalty<T>(royalty: &Royalty<T>, value: u64): u64 {
        let bps_value = bps_value(royalty);
        let multiple = (bps_value as u64) * value;

        multiple / (BPS_BASE_VALUE as u64)
    }

    /// Create a `RoyaltyPayment` for an item of type `T`
    /// Performs a check to ensure that the item is of the type `T`
    /// 
    /// This function calculates the royalty value or amount based on the given Royalty and item price. 
    /// The result is placed in the constructed `RoyaltyPayment`
    public fun create_payment<T>(item: &UID, royalty: &Royalty<T>, price: u64): RoyaltyPayment<T> {
        assert_valid_item_type<T>(item);
        let value = calculate_royalty(royalty, price);
        
        RoyaltyPayment {
            value,
            creator: royalty.creator,
            item: object::uid_to_inner(item)
        }
    }

    // ========== Getter functions =========

    public fun bps_value<T>(royalty: &Royalty<T>): u16 {
        royalty.bps_value
    }

    public fun creator<T>(royalty: &Royalty<T>): address {
        royalty.creator
    }

    // ========== Helper functions ==========

    fun assert_valid_item_type<T>(uid: &UID) {
        let type = ownership::get_type(uid);
        assert!(option::is_some(&type), ENO_ITEM_TYPE);
        assert!(option::destroy_some(type) == struct_tag::get<T>(), EITEM_TYPE_MISMATCH);
    }
}