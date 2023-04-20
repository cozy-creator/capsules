module transfer_system::transfer_witness {
    struct TransferWitness has drop {}

    public(friend) fun new(): TransferWitness {
        TransferWitness {}
    }

    #[test_only]
    public fun new_for_testing(): TransferWitness {
        new()
    }
}