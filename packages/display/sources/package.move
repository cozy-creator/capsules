module display::package {
    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui_utils::typed_id;
    
    use ownership::client;
    use ownership::ownership;
    use ownership::permissions::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::publish_receipt::{Self, PublishReceipt};
    use ownership::simple_transfer::Witness as SimpleTransfer;

    use display::creator::{Self, Creator};

    // Error enums
    const ESENDER_UNAUTHORIZED: u64 = 0;
    const EPACKAGE_ALREADY_CLAIMED: u64 = 1;

    // Owned, root-level object. Cannot be destroyed. Unique by package ID.
    struct Package has key {
        id: UID,
        // The ID of the published package
        package: ID,
        // The object-ID of the creator object that 'owns' this package
        // The reputation of the creator will extend to this package, as a chain of trust
        creator: ID
    }

    // Placed on PublishReceipt to prevent package-objects from being claimed twice
    struct Key has store, copy, drop {}

    // Authority object
    struct Witness has drop {}

    // Convenience entry function
    public entry fun claim(
        creator: &mut Creator,
        receipt: &mut PublishReceipt,
        ctx: &mut TxContext
    ) {
        let package = claim_(
            creator, receipt, tx_context::sender(ctx), &tx_authority::begin(ctx), ctx);
        return_and_share(package);
    }

    // Claim a package object from our publish receipt
    public fun claim_(
        creator: &mut Creator,
        receipt: &mut PublishReceipt,
        owner: address,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Package {
        assert!(client::has_owner_permission<ADMIN>(creator::uid(creator), auth), ESENDER_UNAUTHORIZED);

        // This package can only ever be claimed once
        let receipt_uid = publish_receipt::uid_mut(receipt);
        assert!(!dynamic_field::exists_(receipt_uid, Key { }), EPACKAGE_ALREADY_CLAIMED);
        dynamic_field::add(receipt_uid, Key { }, true);

        let package = Package { 
            id: object::new(ctx),
            package: publish_receipt::into_package_id(receipt),
            creator: object::id(creator)
        };

        // Initialize ownership
        let typed_id = typed_id::new(&package);
        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<Package, SimpleTransfer>(&mut package.id, typed_id, owner, &auth);

        package
    }

    public fun return_and_share(package: Package) {
        transfer::share_object(package);
    }

    // If Creator-A controls the package, and they want to give it to a Creator-B, this is a two-step
    // process, because Sui does not yet support multi-signer transactions.
    // Tx-1: signed by Creator-A; sui::transfer::transfer(package, Creator-B) Creator-B
    // Tx-2: signed by Creator-B; creator must call this function to set themselves as the new creator
    public fun assign_new_creator(package: &mut Package, new_creator: &Creator, auth: &TxAuthority) {
        assert!(client::has_owner_permission<ADMIN>(&package.id, auth), ESENDER_UNAUTHORIZED);
        assert!(client::has_owner_permission<ADMIN>(creator::uid(new_creator), auth), ESENDER_UNAUTHORIZED);

        package.creator = object::id(new_creator);
    }

    // ======== For Owners =====
    // No need for transfer; that can be handled by the SimpleTransfer module

    public fun uid(package: &Package): &UID {
        &package.id
    }

    public fun uid_mut(package: &mut Package, auth: &TxAuthority): &mut UID {
        assert!(client::has_owner_permission<ADMIN>(&package.id, auth), ESENDER_UNAUTHORIZED);

        &mut package.id
    }

    // ======== ???? =====
    // Some sort of package endorsement system would make sense as well... this would require package to be a
    // shared object however
}