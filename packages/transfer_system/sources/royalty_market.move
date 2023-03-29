module transfer_system::royalty_market {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::pay;
    use sui::dynamic_object_field as dof;

    use ownership::ownership;
    use ownership::tx_authority;

    struct Royalty has key, store {
        id: UID,
        /// The royalty basis point
        royalty_bps: u16,
        /// The address where the royalty value should be sent to
        recipient: address
    }

    struct RoyaltyCap has key, store {
        id: UID,
        /// The ID of the royalty that this capability belongs to
        royalty_id: ID
    }

    struct Key has store, copy, drop {}

    struct Witness has drop {}


    // ========== Error constants==========

    const ENO_OWNER_AUTHORITY: u64 = 0;
    const ENO_ROYALTY_AUTHORITY: u64 = 1;
    const ENO_ROYALTY_FOUND: u64 = 2;

    // ========== Other contants ==========

    const BPS_BASE: u16 = 10_000;


    /// Attaches the royalty (`Royalty`) to an object which uid (`UID`) is passed as a mutable reference.
    /// 
    /// - Aborts
    /// If a the object is not owned by the transaction sender.
    public fun attach(uid: &mut UID, royalty: Royalty, ctx: &mut TxContext) {
        let auth = tx_authority::begin(ctx);
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENO_OWNER_AUTHORITY);

        dof::add(uid, Key { }, royalty);
    }

    /// Detaches royalty that is attached to an object which uid (`UID`) is passed as a mutable reference.
    /// 
    /// - Aborts
    /// If royalty is not attached before.
    /// If royalty cap and the royalty do not matching IDs
    public fun detach(uid: &mut UID, royalty_cap: &RoyaltyCap): Royalty {
        assert!(owns_royalty(uid, royalty_cap.royalty_id), ENO_ROYALTY_AUTHORITY);

        let royalty = dof::remove<Key, Royalty>(uid, Key { });
        assert!(royalty_cap.royalty_id == object::id(&royalty), ENO_ROYALTY_AUTHORITY);

        royalty
    }

    /// Destroys a royalty object and it's royalty cap
    /// 
    /// - Aborts
    /// If royalty cap and the royalty do not matching IDs
    public fun destroy(royalty_cap: RoyaltyCap, royalty: Royalty) {
        assert!(royalty_cap.royalty_id == object::id(&royalty), ENO_ROYALTY_AUTHORITY);

        let Royalty { id: royalty_id, royalty_bps: _, recipient: _ } = royalty;
        object::delete(royalty_id);

        // The `RoyaltyCap` should be deleted, since the `Royalty` it belongs to have been deleted
        let RoyaltyCap { id: cap_id, royalty_id: _ } = royalty_cap;
        object::delete(cap_id);
    }

    /// Detaches and destroys royalty that is attached to an object which uid (`UID`) is passed as a mutable reference.
    /// 
    /// - Aborts
    /// If royalty is not attached before.
    /// If royalty cap and the royalty do not matching IDs
    public fun detach_and_destroy(uid: &mut UID, royalty_cap: RoyaltyCap) {
        let royalty = detach(uid, &royalty_cap);
        destroy(royalty_cap, royalty)
    }

    /// Collects royalty value from balance `Balance` of type `C`
    /// It then converts it to a coin `Coin` of type `C` and transfers it to the royalty recipient
    public fun collect_from_balance<C>(royalty: &Royalty, source: &mut Balance<C>, ctx: &mut TxContext) {
        let value = balance::value(source);
        let royalty_value = calculate_royalty_value(royalty, value);
        let royalty_coin = coin::take(source, royalty_value, ctx);

        transfer::public_transfer(royalty_coin, royalty.recipient)
    }

    /// Collects royalty value from coin `Coin` of type `C` and transfers it to the royalty recipient
    public fun collect_from_coin<C>(royalty: &Royalty, source: &mut Coin<C>, ctx: &mut TxContext) {
        let value = coin::value(source);
        let royalty_value = calculate_royalty_value(royalty, value);
        let royalty_coin = coin::split(source, royalty_value, ctx);

        transfer::public_transfer(royalty_coin, royalty.recipient)
    }

    public fun transfer_with_coin<C>(uid: &mut UID, source: &mut Coin<C>, new_owner: vector<address>, ctx: &mut TxContext) {
        let royalty = borrow_royalty(uid);

        // collects the royalty value from the source coin and transfers it to the royalty recipient
        collect_from_coin(royalty, source, ctx);
        transfer(uid, new_owner, ctx)
    }

    public fun transfer_with_balance<C>(uid: &mut UID, source: &mut Balance<C>, new_owner: vector<address>, ctx: &mut TxContext) {
        let royalty = borrow_royalty(uid);

        // collects the royalty value from the source balance and transfers it to the royalty recipient
        collect_from_balance(royalty, source, ctx);
        transfer(uid, new_owner, ctx)
    }

    /// Creates a new royalty (`Royalty`) object and a royalty cap (`RoyaltyCap`) object
    public fun create_royalty_and_cap(royalty_bps: u16, recipient: address, ctx: &mut TxContext):  (Royalty, RoyaltyCap) {
         let royalty = create_royalty(royalty_bps, recipient, ctx);
         let royalty_cap = create_royalty_cap(&royalty, ctx);

         (royalty, royalty_cap)
    }

    /// Creates a new royalty (`Royalty`) object
    public fun create_royalty(royalty_bps: u16, recipient: address, ctx: &mut TxContext):  Royalty {
         Royalty {
            id: object::new(ctx),
            royalty_bps,
            recipient
        }
    }

    /// Creates a new royalty cap (`RoyaltyCap`) object
    public fun create_royalty_cap(royalty: &Royalty, ctx: &mut TxContext): RoyaltyCap {
        RoyaltyCap {
            id: object::new(ctx),
            royalty_id: object::id(royalty)
        }
    }

    // ==================== Getter function =====================

    public fun royalty_id(royalty: &Royalty): ID {
        object::id(royalty)
    }

    /// Returns whether an object which uid `UID` reference is passed owns the royalty whose id `ID` is passed
    public fun owns_royalty(uid: &UID, royalty_id: ID): bool {
        assert!(dof::exists_(uid, Key { }), ENO_ROYALTY_FOUND);

        let royalty = dof::borrow<Key, Royalty>(uid, Key { });
        object::id(royalty) == royalty_id
    }

    /// Returns whether an has royalty attached to it
    public fun has_royalty(uid: &UID): bool {
        dof::exists_(uid, Key { })
    }

    public fun borrow_royalty(uid: &UID): &Royalty {
        assert!(dof::exists_(uid, Key { }), ENO_ROYALTY_FOUND);
        dof::borrow<Key, Royalty>(uid, Key { })
    }


    // ==================== Helper functions ====================

    fun transfer(uid: &mut UID, new_owner: vector<address>, ctx: &TxContext) {
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENO_OWNER_AUTHORITY);

        ownership::transfer(uid, new_owner, &auth);
    }

    fun calculate_royalty_value(royalty: &Royalty, value: u64): u64 {
        let share = royalty.royalty_bps / BPS_BASE;
        value * (share as u64)
    }

     fun extract_sender(seller: Option<address>, ctx: &TxContext): address {
        if(option::is_some(&seller)) {
            option::extract(&mut seller)
        } else {
            tx_context::sender(ctx)
        }
    }
}