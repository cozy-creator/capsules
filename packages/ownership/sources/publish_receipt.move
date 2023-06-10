// This module is a temporary stand-in until Sui-core adds this feature officially
// This object is used as an authority object, proving who published the package
//
// We want there to only be one package-publisher struct per package, but we cannot guarantee this because:
// (1) the package could include multiple modules which call this once each, and (2) the module could re-use
// the same one-time witness, since we do not drop it here. We do this so that the one-time-witness can
// be used for things like creating a 0x2::coin::create_currency.
//
// Note that publish receipts can only be claimed in a module's init function (due to requiring a one-time
// witness), when the package is deployed. In Sui, deploying an upgrade-package _does not_ call any init
// function, meaning upgrades cannot be used to produce more publish receipts.

module ownership::publish_receipt {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::TxContext;
    use sui::types::is_one_time_witness;

    use sui_utils::encode;

    // Error enums
    const EBAD_WITNESS: u64 = 0;

    struct PublishReceipt has key, store {
        id: UID,
        package: ID,
        // display::type::Key{ slot: module_name::struct_name } -> bool
        // display::creator::Key{ } -> bool
    }

    public fun claim<GENESIS: drop>(genesis: &GENESIS, ctx: &mut TxContext): PublishReceipt {
        assert!(is_one_time_witness(genesis), EBAD_WITNESS);

        PublishReceipt {
            id: object::new(ctx),
            package: encode::package_id<GENESIS>()
        }
    }

    public fun into_package_id(publisher: &PublishReceipt): ID {
        *&publisher.package
    }

    public fun did_publish<T>(publisher: &PublishReceipt): bool {
        did_publish_(publisher, encode::package_id<T>())
    }

    public fun did_publish_(publisher: &PublishReceipt, id: ID): bool {
        publisher.package == id
    }

    public fun uid(publisher: &PublishReceipt): &UID {
        &publisher.id
    }

    // Publisher is an owned-object, so no need for an ownership check here
    public fun uid_mut(publisher: &mut PublishReceipt): &mut UID {
        &mut publisher.id
    }

    public fun destroy(publisher: PublishReceipt) {
        let PublishReceipt { id, package: _ } = publisher;
        object::delete(id);
    }

    // Note that because PublishReceipt has key + store, it can be transfered and frozen generically

    #[test_only]
    public fun claim_for_testing<GENESIS: drop>(genesis: &GENESIS, ctx: &mut TxContext): PublishReceipt {
        claim(genesis, ctx)
    }

    #[test_only]
    public fun destroy_for_testing(receipt: PublishReceipt) {
        destroy(receipt)
    }
}