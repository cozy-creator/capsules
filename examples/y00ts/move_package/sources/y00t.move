module y00t::y00t {
    use std::string::String;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use sui_utils::typed_id;

    use ownership::ownership;
    use ownership::publish_receipt;
    use ownership::tx_authority;

    use attach::data;

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    // A currency for type `T`, such as Points<Y00t>
    struct Points<phantom T> has key {
        id: UID,
        balance: u64
    }

    struct Y00t has key {
        id: UID
    }

    struct Y00T has drop {} // One time witness; needed to claim PublishReceipt
    struct Witness has drop {} // module authority

    public entry fun create(data: vector<vector<u8>>, fields: vector<vector<String>>, ctx: &mut TxContext) {
        let y00t = Y00t { id: object::new(ctx) };

        let owners = vector[tx_context::sender(ctx)];
        let typed_id = typed_id::new(&y00t);
        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<Y00t, SimpleTransfer>(&mut y00t.id, typed_id, owners, &auth);

        data::deserialize_and_set(Witness { }, &mut y00t.id, data, fields);

        transfer::share_object(y00t);
    }

    // Note that once init functions can accept arguments in Sui, we should bring in a creator object and then
    // claim the package object directly inside of this
    fun init(otw: Y00T, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&otw, ctx);

        transfer::public_transfer(receipt, tx_context::sender(ctx));
    }
}