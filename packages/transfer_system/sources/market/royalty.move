module transfer_system::royalty {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;
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

    // ========== Error constants==========

    const ENotItemOwner: u64 = 0;
    const ERoyaltyCapMismatch: u64 = 1;
    const ERoyaltyNotFound: u64 = 2;
    const EItemRoyaltyMismatch: u64 = 3;

    // ========== Other contants ==========

    const BASE_BPS: u16 = 10_000;

    /// Attaches the royalty (`Royalty`) to an object which uid (`UID`) is passed as a mutable reference.
    /// 
    /// - Aborts
    /// If a the object is not owned by the transaction sender.
    public fun attach(uid: &mut UID, royalty: Royalty, ctx: &mut TxContext) {
        let auth = tx_authority::begin(ctx);
        assert!(ownership::is_authorized_by_owner(uid, &auth), ENotItemOwner);

        dof::add(uid, Key { }, royalty);
    }

    /// Detaches and deletes royalty that is attached to an object which uid (`UID`) is passed as a mutable reference.
    /// 
    /// - Aborts
    /// If royalty is not attached before.
    /// If royalty cap and the royalty do not matching IDs
    public fun detach(uid: &mut UID, royalty_cap: RoyaltyCap) {
        assert!(owns_royalty(uid, royalty_cap.royalty_id), EItemRoyaltyMismatch);

        let royalty = dof::remove<Key, Royalty>(uid, Key { });
        assert!(royalty_cap.royalty_id == object::id(&royalty), ERoyaltyCapMismatch);

        let Royalty { id: royalty_id, royalty_bps: _, recipient: _ } = royalty;
        object::delete(royalty_id);

        // The `RoyaltyCap` should be deleted, since the `Royalty` it belongs to have been deleted
        let RoyaltyCap { id: cap_id, royalty_id: _ } = royalty_cap;
        object::delete(cap_id);
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

    /// Collects royalty value from balance `Balance` of type `C`
    /// It then converts it to a coin `Coin` of type `C` and transfers it to the royalty recipient
    public fun collect_from_balance<C>(royalty: &Royalty, source: &mut Balance<C>, ctx: &mut TxContext) {
        let value = balance::value(source);
        let royalty_value = calculate_royalty_value(royalty, value);
        let royalty_coin = coin::from_balance(balance::split(source, royalty_value), ctx);

        transfer::transfer(royalty_coin, royalty.recipient)
    }

    /// Collects royalty value from coin `Coin` of type `C` and transfers it to the royalty recipient
    public fun collect_from_coin<C>(royalty: &Royalty, source: &mut Coin<C>, ctx: &mut TxContext) {
        let value = coin::value(source);
        let royalty_value = calculate_royalty_value(royalty, value);
        let royalty_coin = coin::split(source, royalty_value, ctx);

        transfer::transfer(royalty_coin, royalty.recipient)
    }


    // ==================== Getter function =====================

    public fun royalty_id(royalty: &Royalty): ID {
        object::id(royalty)
    }

    /// Returns whether an object which uid `UID` reference is passed owns the royalty whose id `ID` is passed
    public fun owns_royalty(uid: &UID, royalty_id: ID): bool {
        assert!(dof::exists_(uid, Key { }), ERoyaltyNotFound);

        let royalty = dof::borrow<Key, Royalty>(uid, Key { });
        object::id(royalty) == royalty_id
    }

    /// Returns whether an has royalty attached to it
    public fun has_royalty(uid: &UID): bool {
        dof::exists_(uid, Key { })
    }

    public fun borrow_royalty(uid: &UID): &Royalty {
        assert!(dof::exists_(uid, Key { }), ERoyaltyNotFound);
        dof::borrow<Key, Royalty>(uid, Key { })
    }

    // ==================== Helper functions ====================

    fun calculate_royalty_value(royalty: &Royalty, value: u64): u64 {
        let share = royalty.royalty_bps / BASE_BPS;
        value * (share as u64)
    }

}