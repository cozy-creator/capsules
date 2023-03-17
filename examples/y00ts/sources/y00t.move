module y00t::y00t {
    use sui::object::UID;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use display::publish_receipt;

    // One time witness
    struct Y00T has drop {}

    struct Y00tAbstract<phantom T> has key {
        id: UID
    }

    struct Y00t has key {
        id: UID
    }

    public entry fun create(_ctx: &mut TxContext) {
    }

    fun init(otw: Y00T, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&otw, ctx);

        transfer::transfer(receipt, tx_context::sender(ctx));
    }
}