module package::capsule_baby {
    use std::vector;
    use std::string::String;

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;

    use ownership::ownership;
    use ownership::tx_authority;
    use ownership::permission::ADMIN;
    use ownership::delegation::{Self, DelegationStore};

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

    // Convenience function
    public fun create_delegation_store(
        ctx: &mut TxContext
    ) {
        let store = delegation::create(ctx);
        delegation::return_and_share(store)
    }

    public fun delegate_baby(
        baby: &mut CapsuleBaby,
        store: &mut DelegationStore,
        agent: address,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        assert!(ownership::has_owner_permission<ADMIN>(&baby.id, &auth), ENO_OWNER_AUTH);

        let objects = vector::singleton(object::id(baby));
        delegation::add_permission_for_objects<EDITOR>(store, agent, objects, &auth)
    }

    public fun undelegate_baby(
        baby: &mut CapsuleBaby,
        store: &mut DelegationStore,
        agent: address,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        assert!(ownership::has_owner_permission<ADMIN>(&baby.id, &auth), ENO_OWNER_AUTH);

        let objects = vector::singleton(object::id(baby));
        delegation::remove_permission_for_objects_from_agent<EDITOR>(store, agent, objects, &auth)
    }

    public fun edit_baby_name(
        baby: &mut CapsuleBaby,
        store: &DelegationStore,
        new_name: String,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        if(ownership::has_owner_permission<ADMIN>(&baby.id, &auth)) {
            baby.name = new_name;
        } else {
            let auth = delegation::claim_delegation(store, ctx);
            assert!(ownership::has_owner_permission<EDITOR>(&baby.id, &auth), ENO_OWNER_AUTH);

            baby.name = new_name;
        }
    }
}