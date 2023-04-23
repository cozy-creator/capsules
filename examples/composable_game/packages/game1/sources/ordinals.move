module coposable_game::ordinals {
    use sui::object::{Self, UID};
    
    struct Ordinals has key {
        id: UID,
        number: u64
    }

    struct Art has store {
        prompts: String,
        model: String,
        image_url: Url
    }

    struct ADD {} // Permission type for adding art to ordinals
    struct ORDINALS has drop {} // one-time witness
    struct Witness has drop {} // module authority
    struct EDIT_THE_FIELD {} // Permission type for editing the field

    public fun create(store: &mut Ordinals, prompts: String, model: String, image_url: Url, auth: &TxAuthority) {
        assert!(namespace::has_permission<ADD>(auth), ENO_EDIT_PERMISSION);

        let art = Art { prompts, model, image_url };
        dynamic_field::add(&mut store.id, store.number, art);
        store.number = store.number + 1;
    }

    fun init(otw: ORDINALS, ctx: &mut TxContext) {
        transfer::share_object(Ordinals { id: object::new(ctx), number: 0 });

        let receipt = publish_receipt::claim(&otw, ctx);
        namespace::claim_package(&mut receipt, ctx);
        transfer::transfer(receipt, tx_context::sender(ctx));
    }
}