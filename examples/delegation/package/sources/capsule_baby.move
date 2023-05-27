module package::capsule_baby {
    use std::string::String;

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use sui_utils::typed_id;

    struct CapsuleBaby has key {
        id: UID,
        name: String
    }

    struct EDITOR {}

    struct Witness has drop {}

    const ENO_OWNER_AUTH: u64 = 0;

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
        ownership::as_shared_object<CapsuleBaby, SimpleTransfer>(&mut baby.id, tid, owner, &auth);

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
        assert!(ownership::has_owner_permission<EDITOR>(&baby.id, auth), ENO_OWNER_AUTH);
        baby.name = new_name;
    }
}

    // public fun edit_baby_name(
    //     baby: &mut CapsuleBaby,
    //     store: &DelegationStore,
    //     new_name: String,
    //     ctx: &mut TxContext
    // ) {
    //     let auth = tx_authority::begin(ctx);
    //     if(ownership::has_owner_permission<ADMIN>(&baby.id, &auth)) {
    //         baby.name = new_name;
    //     } else {
    //         let auth = delegation::claim_delegation(store, ctx);
    //         assert!(ownership::has_owner_permission<EDITOR>(&baby.id, &auth), ENO_OWNER_AUTH);

    //         baby.name = new_name;
    //     }
    // }
