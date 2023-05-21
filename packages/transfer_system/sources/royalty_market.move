module transfer_system::royalty_market {
    use std::vector;
    use std::option::{Self, Option};

    use sui::balance::{Self, Balance};
    use sui::vec_map::{Self, VecMap};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use sui::transfer;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::publish_receipt::{Self, PublishReceipt};

    use sui_utils::struct_tag;

    struct Witness has drop {}

    struct Royalty<phantom T> has key, store {
        id: UID,
        royalty_bps: u16,
        royalty_splits: VecMap<address, u16>
    }

    struct RoyaltyPayment<phantom T> has drop {
        item_id: ID,
        item_price: u64,
        royalty_value: u64
    }

    struct Key<phantom C> has copy, store, drop { }

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

    public fun create_royalty_<T>(
        receipt: &PublishReceipt,
        royalty_bps: u16,
        creators: vector<address>,
        splits: vector<u16>,
        ctx: &mut TxContext
    ): Royalty<T> {
        let royalty_splits = to_royalty_splits(creators, splits);
        create_royalty_internal<T>(receipt, royalty_bps, royalty_splits, ctx)
    }

    public fun create_royalty<T>(
        receipt: &PublishReceipt,
        royalty_bps: u16,
        creator: address,
        ctx: &mut TxContext
    ): Royalty<T> {
        let royalty_splits = vec_map::empty();
        vec_map::insert(&mut royalty_splits, creator, BPS_BASE_VALUE);
        create_royalty_internal<T>(receipt, royalty_bps, royalty_splits, ctx)
    }

    public fun return_and_share<T>(royalty: Royalty<T>) {
        transfer::share_object(royalty)
    }

    fun create_royalty_internal<T>(
        receipt: &PublishReceipt,
        royalty_bps: u16,
        royalty_splits: VecMap<address, u16>,
        ctx: &mut TxContext
    ):  Royalty<T> {
        assert!(publish_receipt::did_publish<T>(receipt), EINVALID_PUBLISH_RECEIPT);

         Royalty {
            id: object::new(ctx),
            royalty_bps,
            royalty_splits
        }
    }

    public fun transfer<T, C>(
        uid: &mut UID,
        royalty: &mut Royalty<T>,
        receipt: RoyaltyPayment<T>,
        payment: Coin<C>,
        new_owner: Option<address>,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        transfer_(uid, royalty, receipt, payment, new_owner, &auth)
    }

    public fun transfer_<T, C>(
        uid: &mut UID,
        royalty: &mut Royalty<T>,
        payment: RoyaltyPayment<T>,
        coin: Coin<C>,
        new_owner: Option<address>,
        auth: &TxAuthority
    ) {
        assert_valid_item_type<T>(uid);
        assert!(object::uid_to_inner(uid) == payment.item_id, EITEM_RECEIPT_MISMATCH);
        assert!(coin::value(&coin) == payment.royalty_value, EINVALID_ROYALTY_PAYMENT);

        collect_royalty(royalty, coin);
        ownership::transfer(uid, new_owner, auth);
    }

    public fun calculate_royalty<T>(royalty: &Royalty<T>, value: u64): u64 {
        let royalty_bps = royalty_bps(royalty);
        let multiple = (royalty_bps as u64) * value;

        multiple / (BPS_BASE_VALUE as u64)
    }

    public fun create_payment<T>(item: &UID, royalty: &Royalty<T>, item_price: u64): RoyaltyPayment<T> {
        assert_valid_item_type<T>(item);
        let royalty_value = calculate_royalty(royalty, item_price);
        
        RoyaltyPayment {
            item_price,
            royalty_value,
            item_id: object::uid_to_inner(item)
        }
    }

    // ========== Getter functions =========

    public fun royalty_bps<T>(royalty: &Royalty<T>): u16 {
        royalty.royalty_bps
    }

    public fun royalty_splits<T>(royalty: &Royalty<T>): VecMap<address, u16> {
        royalty.royalty_splits
    }

    // ========== Helper functions ==========

    fun to_royalty_splits(creators: vector<address>, values: vector<u16>): VecMap<address, u16> {
        assert!(vector::length(&creators) == vector::length(&values), 0);
        let (total_bps, splits) = (0, vec_map::empty());

        while(!vector::is_empty(&creators)) {
            let creator = vector::pop_back(&mut creators);
            let value = vector::pop_back(&mut values);

            vec_map::insert(&mut splits, creator, value);
            total_bps = total_bps + value;
        };

        assert!(total_bps == BPS_BASE_VALUE, EINVALID_ROYALTY_SPLITS_TOTAL);
        splits
    }

    fun collect_royalty<T, C>(royalty: &mut Royalty<T>, coin: Coin<C>) {
        let key = Key { };
        let has_balance = dynamic_field::exists_with_type<Key<C>, Balance<C>>(&mut royalty.id, key);

        if(!has_balance) {
            dynamic_field::add<Key<C>, Balance<C>>(&mut royalty.id, key, coin::into_balance(coin))
        } else {
            let balance = dynamic_field::borrow_mut<Key<C>, Balance<C>>(&mut royalty.id, key);
            balance::join(balance, coin::into_balance(coin));
        }
    }

    fun assert_valid_item_type<T>(uid: &UID) {
        let type = ownership::get_type(uid);
        assert!(option::is_some(&type), ENO_ITEM_TYPE);
        assert!(option::destroy_some(type) == struct_tag::get<T>(), EITEM_TYPE_MISMATCH);
    }
}