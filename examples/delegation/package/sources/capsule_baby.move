module package::capsule_baby {
    use std::string::String;

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;

    use ownership::ownership::{Self, can_act_as_owner, can_act_as_package};
    use ownership::publish_receipt;
    use ownership::tx_authority::{Self, TxAuthority};

    // use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use sui_utils::typed_id;

    struct CapsuleBaby has key {
        id: UID,
        name: String
    }

    struct CAPSULE_BABY has drop {}
    struct EDITOR {}

    struct Witness has drop {}

    const ENO_AUTHORITY: u64 = 0;

    fun init(genesis: CAPSULE_BABY, ctx: &mut TxContext) {
        let reciept = publish_receipt::claim(&genesis, ctx);
        transfer::public_transfer(reciept, tx_context::sender(ctx))
    }

    public fun create_baby(
        name: String,
        ctx: &mut TxContext
    ): CapsuleBaby {
        let owner = tx_context::sender(ctx);
        create_baby_(name, owner, ctx)
    }

    public fun create_baby_(
        name: String,
        owner: address,
        ctx: &mut TxContext
    ): CapsuleBaby {
        let baby = CapsuleBaby {
            id: object::new(ctx),
            name
        };

        let tid = typed_id::new(&baby);
        let auth = tx_authority::begin_with_package_witness(Witness {});
        ownership::as_shared_object<CapsuleBaby, Witness>(&mut baby.id, tid, owner, &auth);

        baby
    }

    public fun return_and_share(baby: CapsuleBaby) {
        transfer::share_object(baby)
    }

    public fun edit_baby_name(
        baby: &mut CapsuleBaby,
        new_name: String,
        auth: &TxAuthority
    ) {
        assert!(can_act_as_owner<EDITOR>(&baby.id, auth) || 
            can_act_as_package<EDITOR>(&baby.id, auth), ENO_AUTHORITY);

        baby.name = new_name;
    }
}
