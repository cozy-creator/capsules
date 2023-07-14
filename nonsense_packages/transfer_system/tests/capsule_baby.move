// CapsuleBaby - a capsule standard based asset for testing

#[test_only]
module transfer_system::capsule_baby {
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;

    use sui_utils::typed_id;

    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::royalty_market::Witness as RoyaltyMarket;

    struct Witness has drop {}

    struct CapsuleBaby has key {
        id: UID
    }

    public fun create(ctx: &mut TxContext) {
        let capsule_baby = CapsuleBaby {
            id: object::new(ctx)
        };

        let typed_id = typed_id::new(&capsule_baby);
        let auth = tx_authority::begin_with_type(&Witness {});

        ownership::as_shared_object<CapsuleBaby, RoyaltyMarket>(&mut capsule_baby.id, typed_id, vector[tx_context::sender(ctx)], &auth);

        transfer::share_object(capsule_baby)
    }

    public fun extend(self: &mut CapsuleBaby): &mut UID {
        &mut self.id
    }
}