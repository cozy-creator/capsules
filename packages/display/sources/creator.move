// TO DO: we might generalize this as an identity

module display::creator {
    use std::vector;

    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::dynamic_field;
    use sui::transfer;

    use sui_utils::typed_id;
    use sui_utils::dynamic_field2;
    
    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    // Error enums
    const ESENDER_UNAUTHORIZED: u64 = 0;

    // Shared, root-level object. Cannot be destroyed.
    struct Creator has key {
        id: UID
        // <data::Key { namespace, key }> : <T: store>
    }

    // Added to publish-receipt to prevent a package from being claimed twice
    struct Key has store, copy, drop { }

    // Module authority struct
    struct Witness has drop { }

    public entry fun create(
        owner: address,
        ctx: &mut TxContext
    ) {
        let creator = Creator { id: object::new(ctx) };

        // Initialize ownership
        let typed_id = typed_id::new(&creator);
        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<Creator, SimpleTransfer>(
            &mut creator.id,
            typed_id,
            vector[owner],
            &auth
        );

        transfer::share_object(creator);
    }

    // ======== For Owners =====
    // We don't need any transfer functions here; that can be handled within the SimpleTransfer module.

    public fun uid(creator: &Creator): &UID {
        &creator.id
    }

    public fun uid_mut(creator: &mut Creator, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&creator.id, auth), ESENDER_UNAUTHORIZED);

        &mut creator.id
    }

    // ======== Creator Endorsement System =====
    // This is part of Capsule's on-chain Trust and Safety system
    //
    // Creators can be independently endorsed by trusted entities; the owner of the Creator object's consent
    // is not required to add or remove endorsements.
    //
    // Objects that originate from packages whose creators are not endorsed by a trusted authority
    // should not be displayed in wallets / marketplaces, and should be viewed as spam.
    //
    // We use dynamic fields, rather than vectors, because it scales O(1) instead of O(n) for n endorsements.

    struct Endorsement has store, copy, drop { from: address }
    
    public fun add_endorsement_(creator: &mut Creator, from: address, auth: &TxAuthority) {
        assert!(tx_authority::is_signed_by(from, auth), ESENDER_UNAUTHORIZED);

        dynamic_field2::set<Endorsement, bool>(&mut creator.id, Endorsement { from }, true);
    }

    public fun remove_endorsement_(creator: &mut Creator, from: address, auth: &TxAuthority) {
        assert!(tx_authority::is_signed_by(from, auth), ESENDER_UNAUTHORIZED);

        dynamic_field2::drop<Endorsement, bool>(&mut creator.id, Endorsement { from });
    }

    public fun is_endorsed_by(creator: &Creator, from: address): bool {
        dynamic_field::exists_(&creator.id, Endorsement { from })
    }

    // Useful to see if this creator has been endorsed by a minimum threshold of trusted entities
    public fun is_endorsed_by_num(creator: &Creator, endorsers: vector<address>): u64 {
        let (count, i) = (0, 0);
        while (i < vector::length(&endorsers)) {
            if (is_endorsed_by(creator, *vector::borrow(&endorsers, i))) {
                count = count + 1;
            };
            i = i + 1;
        };

        count
    }
    
}