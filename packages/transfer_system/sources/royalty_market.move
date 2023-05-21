module transfer_system::royalty_market {
    use std::vector;
    use std::option::{Self, Option};

    use sui::vec_map::{Self, VecMap};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::transfer;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::publish_receipt::{Self, PublishReceipt};

    use sui_utils::struct_tag;

    struct Witness has drop {}

    struct Royalty<phantom T> has key, store {
        id: UID,
        bps_value: u16,
        creator: address
    }

    struct RoyaltyPayment<phantom T> {
        item: ID,
        value: u64,
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

    public fun create_royalty<T>(
        receipt: &PublishReceipt,
        bps_value: u16,
        ctx: &mut TxContext
    ): Royalty<T> {
        let creator = tx_context::sender(ctx);
        create_royalty_<T>(receipt, bps_value, creator, ctx)
    }

    fun create_royalty_<T>(
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
    
    public fun transfer<T, C>(
        uid: &mut UID,
        payment: RoyaltyPayment<T>,
        coin: Coin<C>,
        new_owner: Option<address>,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        transfer_(uid, payment, coin, new_owner, &auth)
    }

    public fun transfer_<T, C>(
        uid: &mut UID,
        payment: RoyaltyPayment<T>,
        coin: Coin<C>,
        new_owner: Option<address>,
        auth: &TxAuthority
    ) {
        assert_valid_item_type<T>(uid);

        let RoyaltyPayment { item, value, creator } = payment;
        assert!(object::uid_to_inner(uid) == item, EITEM_RECEIPT_MISMATCH);
        assert!(coin::value(&coin) == value, EINVALID_ROYALTY_PAYMENT);

        transfer::public_transfer(coin, creator);
        ownership::transfer(uid, new_owner, auth);
    }

    public fun return_and_share<T>(royalty: Royalty<T>) {
        transfer::share_object(royalty)
    }

    public fun calculate_royalty<T>(royalty: &Royalty<T>, value: u64): u64 {
        let bps_value = bps_value(royalty);
        let multiple = (bps_value as u64) * value;

        multiple / (BPS_BASE_VALUE as u64)
    }

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