// This module is a temporary stand-in until Sui-core adds this feature officially
//
// We want there to only be one package-publisher struct per package, but we cannot guarantee this because:
// (1) the package could include multiple modules which call this once each, and (2) the module could re-use
// the same one-time witness, since we do not drop it here. We do this so that the one-time-witness can
// be used for things like creating a 0x2::coin::create_currency.

module metadata::publish_receipt {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::TxContext;
    use sui::types::is_one_time_witness;
    use sui_utils::encode;

    // Error enums
    const EBAD_WITNESS: u64 = 0;

    // This proves that you published the corresponding package
    struct PublishReceipt has key, store {
        id: UID,
        package: ID,
        // metadata::type::Key{ slot: module_name::struct_name } -> bool
        // metadata::creator::Key{ slot: package_id } -> bool
    }

    public fun claim<GENESIS: drop>(genesis: &GENESIS, ctx: &mut TxContext): PublishReceipt {
        assert!(is_one_time_witness(genesis), EBAD_WITNESS);

        let publisher = PublishReceipt {
            id: object::new(ctx),
            package: encode::package_id<GENESIS>()
        };

        publisher
    }

    public fun into_package_id(publisher: &PublishReceipt): ID {
        *&publisher.package
    }

    public fun did_publish(publisher: &PublishReceipt, id: ID): bool {
        publisher.package == id
    }

    public fun extend(publisher: &mut PublishReceipt): &mut UID {
        &mut publisher.id
    }
}