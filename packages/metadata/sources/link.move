module metadata::link {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::types::is_one_time_witness;

    // Error constants
    const EBAD_WITNESS: u64 = 0;

    // An immutable record that links a Genesis type to a Witness type
    struct Link<phantom Genesis, phantom Witness> has key { id: UID }

    // Genesis and Witness needn't be from the same module; this allows a module to delegate
    // authority over its types to whatever module produces Witness.
    // We also return the genesis-witness, so that it can be used in other modules as well
    public fun create_link<GENESIS: drop, Witness: drop>(genesis: GENESIS, ctx: &mut TxContext): GENESIS {
        assert!(is_one_time_witness(&genesis), EBAD_WITNESS);

        transfer::freeze_object(Link<GENESIS, Witness> { id: object::new(ctx) });

        genesis
    }
}