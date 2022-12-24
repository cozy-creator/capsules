// Every package should include metadata::boss_cap::register() in their `init` function
// We'll use this until Sui introduces its own solution for this
// BossCaps have absolute power over all of their constituent packages. They are meant to
// be rarely used. They can (1) create and edit World Metadata, and (2) create and edit
// Type Metadata.
// Projects should store their BossCaps in a secure multi-sig wallet.

module metadata::boss_cap {
    use std::vector;
    use std::string::String;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::types::is_one_time_witness;
    use sui_utils::encode;

    const ECANNOT_DELETE_CANNONICAL_BOSS_CAP: u64 = 0;

    // Authority object for packages. The cannonical version also stores the metadata for the World.
    // If cannonical = true, then this is the master boss-cap; other ones are subbordinate to this one
    struct BossCap has key, store {
        id: UID,
        cannonical: bool,
        packages: vector<ID>,
        // <metadata::Key { utf8(b"schema_version") }> : ID
        // <metadata::Key { String }> : <T: store> <- T must conform to schema_version
    }

    struct Key has store, copy, drop { slot: String }

    // We want there to only be one boss-cap per package, but we cannot guarantee that because:
    // (1) the package could include multiple modules which call this once each, and (2) the module could re-use
    // the same one-time witness, since we do not drop it here. We do this so that the one-time-witness can
    // be used for things like creating a 0x2::coin::create_currency.
    public fun create<GENESIS: drop>(genesis: GENESIS, ctx: &mut TxContext): (BossCap, GENESIS) {
        assert!(is_one_time_witness(&genesis), EBAD_WITNESS);

        let boss_cap = BossCap {
            id: object::new(ctx),
            cannonical: true,
            packages: vector[encode::package_id<GENESIS>()]
        };

        (boss_cap, genesis)
    }

    // Merge the authority of the second boss-cap into the first one
    public entry fun join(self: &mut BossCap, boss_cap: BossCap) {
        let BossCap { id, cannonical, packages } = boss_cap;
        object::delete(id);
        assert!(!cannonical, ECANNOT_DELETE_CANNONICAL_BOSS_CAP);

        let i = 0;
        while (i < vector::length(&packages)) {
            let package_id = *vector::borrow(packages, i);

            // Ensure there are no duplicates
            if (!vector::contains(&self.packages, package_id)) {
                vector::push_back(&mut self.packages, package_id);
            };
            i = i + 1;
        };
    }

    // Returns true if the operation succeeded
    // This makes sure that only the cannonical version can define a type, and that a type is not defined twice
    public fun define_type<T>(boss_cap: &mut BossCap): bool {
        let slot = encode::type_name<T>();

        if (!boss_cap.cannonical) { 
            false 
        } else if (dynamic_field::exists_(&boss_cap.id, Key { slot })) {
            false
        } else {
            dynamic_field::add(&mut boss_cap.id, Key { slot }, true);
            true
        }
    }

    public fun is_valid(boss_cap: &BossCap, package_id: ID): bool {
        vector::contains(&boss_cap.packages, package_id)
    }

    // Checks to see if 'packages' is a subset of the boss_cap's packages
    public fun is_subset(boss_cap: &BossCap, packages: &vector<ID>): bool {
        let i = 0;
        while (i < vector::length(&packages)) {
            if (!vector::contains(&boss_cap.packages, vector::borrow(packages, i))) {
                return false
            };
            i = i + 1;
        };

        true
    }

    public fun is_cannonical(boss_cap: &BossCap): bool {
        boss_cap.cannonical
    }

    public fun extend(boss_cap: &mut BossCap): &mut UID {
        &mut boss_cap.id
    }
}