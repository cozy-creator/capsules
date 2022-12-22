// Every package should include metadata::boss_cap::register() in their `init` function
// We'll use this until Sui introduces its own solution for this

module metadata::boss_cap {
    use std::vector;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::types::is_one_time_witness;
    use sui_utils::encode;

    struct BossCap has key, store {
        id: UID,
        packages: vector<ID>,
    }

    // We want there to only be one boss-cap per package, but we cannot guarantee that because:
    // (1) the package could include multiple modules which call this once each, and (2) the module could re-use
    // the same one-time witness, since we do not consume it here. We do this so that the one-time-witness can
    // be used for things like creating a 0x2::coin::create_currency.
    public fun register<GENESIS: drop>(genesis: &GENESIS, ctx: &mut TxContext): BossCap {
        assert!(is_one_time_witness(genesis), EBAD_WITNESS);

        let package_id = encode::package_id<GENESIS>();

        BossCap {
            id: object::new(ctx),
            packages: vector[package_id]
        }
    }

    // Merge the authority of the second boss-cap into the first one
    public entry fun join(self: &mut BossCap, boss_cap: BossCap) {
        let BossCap { id, packages } = boss_cap;
        object::delete(id);

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

    public fun is_valid(boss_cap: &BossCap, package_id: ID): bool {
        vector::contains(&boss_cap.packages, package_id)
    }
}