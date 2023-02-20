module power::power {
    use sui::object::{UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use metadata::publish_receipt;
    use metadata::creator;
    // use metadata::package;
   
    // Error constants
    const ENOT_OWNER: u64 = 0;

    struct POWER has drop {}
    
    struct Power has key, store {
        id: UID,
        value: u64
    }

    fun init(witness: POWER, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&witness, ctx);

        transfer::transfer(receipt, tx_context::sender(ctx));
    }
}