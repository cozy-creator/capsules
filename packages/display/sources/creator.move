module display::creator {
    use std::string::String;
    use std::vector;

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::typed_id;

    use display::publish_receipt::{Self, PublishReceipt};
    use display::display;
    use display::package::{Self, Package};
    use display::schema::Schema;
    
    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use sui_utils::dynamic_field2;

    // Error enums
    const EBAD_WITNESS: u64 = 0;
    const EPACKAGE_ALREADY_CLAIMED: u64 = 1;
    const ESENDER_UNAUTHORIZED: u64 = 2;
    const EPACKAGE_DOES_NOT_BELONG_TO_CREATOR: u64 = 3;

    // Shared, root-level object. Cannot be destroyed.
    struct Creator has key {
        id: UID
        // <display::Key { slot: String }> : <T: store>
    }

    // Added to publish-receipt
    struct Key has store, copy, drop { }

    // Module authority struct
    struct Witness has drop { }

    public entry fun define(
        owner: address,
        data: vector<vector<u8>>,
        schema: &Schema,
        ctx: &mut TxContext
    ) {
        let creator = Creator { id: object::new(ctx) };

        // Initialize owner and metadata
        let typed_id = typed_id::new(&creator);
        let auth = tx_authority::add_type_capability(
            &Witness { }, &tx_authority::begin(ctx));

        ownership::initialize_without_module_authority(&mut creator.id, typed_id, &auth);

        display::attach(&mut creator.id, data, schema, &auth);

        ownership::as_shared_object<SimpleTransfer>(&mut creator.id, vector[owner], &auth);

        transfer::share_object(creator);
    }

    // Convenience entry function
    public entry fun claim_package(creator: &mut Creator, receipt: &mut PublishReceipt, ctx: &mut TxContext) {
        let package_object = claim_package_(creator, receipt, &tx_authority::begin(ctx), ctx);
        package::transfer(package_object, tx_context::sender(ctx));
    }

    // This is the only way to produce a package object
    public fun claim_package_(
        creator: &mut Creator,
        receipt: &mut PublishReceipt,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Package {
        assert!(ownership::is_authorized_by_owner(&creator.id, auth), ESENDER_UNAUTHORIZED);

        // This package can only ever be claimed once
        let receipt_uid = publish_receipt::extend(receipt);
        assert!(!dynamic_field::exists_(receipt_uid, Key { }), EPACKAGE_ALREADY_CLAIMED);
        dynamic_field::add(receipt_uid, Key { }, true);

        let package_id = publish_receipt::into_package_id(receipt);
        package::define(package_id, object::id(creator), ctx)
    }

    // Conveninece function
    public entry fun change_creator(package: &mut Package, creator: &Creator, ctx: &mut TxContext) {
        change_creator_(package, creator, &tx_authority::begin(ctx));
    }

    // If you have control of the package object, you can redefine who the creator is
    public fun change_creator_(package: &mut Package, creator: &Creator, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&creator.id, auth), ESENDER_UNAUTHORIZED);

        package::set_creator(package, object::id(creator));
    }

    // ======== Metadata Module's API =====
    // For convenience, we replicate the Metadata Module's API here to make it easier to access Creator's UID.
    // Once Sui supports Script transactions, we can remove these.

    public entry fun update(
        creator: &mut Creator,
        keys: vector<String>,
        data: vector<vector<u8>>,
        schema: &Schema,
        overwrite_existing: bool
    ) {
        display::update(&mut creator.id, keys, data, schema, overwrite_existing, &tx_authority::empty());
    }

    public entry fun delete_optional(creator: &mut Creator, keys: vector<String>, schema: &Schema) {
        display::delete_optional(&mut creator.id, keys, schema, &tx_authority::empty());
    }

    public entry fun detach(creator: &mut Creator, schema: &Schema) {
        display::detach(&mut creator.id, schema, &tx_authority::empty());
    }

    public entry fun migrate(
        creator: &mut Creator,
        old_schema: &Schema,
        new_schema: &Schema,
        keys: vector<String>,
        data: vector<vector<u8>>
    ) {
        display::migrate(&mut creator.id, old_schema, new_schema, keys, data, &tx_authority::empty());
    }

    // ======== For Owners =====
    // We don't need any transfer functions here; that can be handled within the SimpleTransfer module.

    // Convenience function
    public fun extend_(creator: &mut Creator, ctx: &TxContext): &mut UID {
        extend(creator, &tx_authority::begin(ctx))
    }

    public fun extend(creator: &mut Creator, auth: &TxAuthority): &mut UID {
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
    public fun is_endorsed_by_num(creator: &Creator, addrs: vector<address>): u64 {
        let (count, i) = (0, 0);
        while (i < vector::length(&addrs)) {
            if (is_endorsed_by(creator, *vector::borrow(&addrs, i))) {
                count = count + 1;
            };
            i = i + 1;
        };

        count
    }
    
}