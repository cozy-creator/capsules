#[test_only]
module royalties::royalties_test {
    use sui::test_scenario;
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    use ownership::ownership;
    use ownership::tx_authority;
    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    struct TestWitness has drop {}

    struct Car has key {
        id: UID,
    }

    public fun create_car(ctx: &mut TxContext): Car {
        Car { id: object::new(ctx) }
    }

    #[test]
    fun test_sanity() {
        let blue = @0x00F;
        let red = @0xF00;

        let scenario = test_scenario::begin(blue);
        {
            let car = create_car(test_scenario::ctx(&mut scenario));
            let auth = tx_authority::add_type_capability(&TestWitness {}, &tx_authority::begin(test_scenario::ctx(&mut scenario)));
            let proof = ownership::setup(&car);

            ownership::initialize(&mut car.id, proof, &auth);
            ownership::initialize_owner_and_transfer_authority<SimpleTransfer>(&mut car.id, blue, &auth);
            transfer::share_object(car);

        };
        test_scenario::next_tx(&mut scenario, red);
        {
            // let car = test_scenario::take_from_sender<Car>(&scenario);
            // transfer::transfer(car, blue);
        };
        test_scenario::end(scenario);
    }
}