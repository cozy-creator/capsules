module account::namespace {
    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui_utils::typed_id;
    
    use ownership::ownership;
    use ownership::publish_receipt::{Self, PublishReceipt};
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::delegation::{Self, RBAC};

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use display::creator::{Self, Creator};

    // Error enums
    const ESENDER_UNAUTHORIZED: u64 = 0;
    const EPACKAGE_ALREADY_CLAIMED: u64 = 1;

    // Shared, root-level object.
    struct Namespace has key {
        id: UID,
        packages: vector<ID>,
        rbac: RBAC
    }

    // Placed on PublishReceipt to prevent namespaces from being claimed twice
    struct Key has store, copy, drop {}

    // Authority object
    struct Witness has drop {}

    // ======== For Creators ======== 

    // Convenience entry function
    public entry fun claim(
        creator: &mut Creator,
        receipt: &mut PublishReceipt,
        ctx: &mut TxContext
    ) {
        let namespace = claim_(
            creator, receipt, tx_context::sender(ctx), &tx_authority::begin(ctx), ctx);
        return_and_share(namespace);
    }

    // Claim a namespace object from our publish receipt
    public fun claim_(
        receipt: &mut PublishReceipt,
        owner: address,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): Namespace {
        assert!(ownership::is_authorized_by_owner(creator::uid(creator), auth), ESENDER_UNAUTHORIZED);

        // This namespace can only ever be claimed once
        let receipt_uid = publish_receipt::uid_mut(receipt);
        assert!(!dynamic_field::exists_(receipt_uid, Key { }), EPACKAGE_ALREADY_CLAIMED);
        dynamic_field::add(receipt_uid, Key { }, true);

        let id = object::new(ctx);
        let auth = tx_authority::begin_with_uid(&id);
        let rbac = delegation::create_rbac(object::uid_to_address(&id), &auth);
        let namespace = publish_receipt::into_package_id(receipt);

        let namespace = Namespace { id, namespace, rbac };

        // Initialize ownership
        let typed_id = typed_id::new(&namespace);
        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<Namespace, SimpleTransfer>(
            &mut namespace.id,
            typed_id,
            owner,
            &auth
        );

        namespace
    }

    public fun return_and_share(namespace: Namespace) {
        transfer::share_object(namespace);
    }

    // ======== For Agents ========

    public fun claim_authority(namespace: &Namespace, ctx: &TxContext): TxAuthority {
        let principal = object::id_to_address(&namespace.id);
        let agent = tx_context::sender(ctx);
        let auth = tx_authority::begin(ctx);
        let agent_roles = delegation::rbac_agent_roles(&namespace.rbac);
        let roles = vec_map2::get_with_default(agent_roles, agent, vector::empty());
        let role_permissions = delegation::rbac_role_permissions(&namespace.rbac);

        tx_authority::add_namespace(namespace.packages, principal);
        tx_authority::add_permissions(principal, roles, role_permissions, &auth)
    }

    public fun assert_login<Permission>(namespace: &Namespace, ctx: TxContext): TxAuthority {
        let auth = claim_authority(namespace, ctx);
        assert!(tx_authority::is_signed_by_namespace<TypeFromModule, TypeFromModule>(functon, &auth), ENO_PERMISSION);

        auth
    }

    public fun has_native_permission<Permission>(auth: &TxAuthority): bool {
        let principal_maybe = tx_authority::get_principal<Permission>(auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);

        tx_authority::has_permission<Permission>(principal, auth)
    }

    public fun has_permission<Namespace, Permission>(auth: &TxAuthority): bool {
        let principal_maybe = tx_authority::get_principal<Namespace>(auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);

        tx_authority::has_permission<Permission>(principal, auth)
    }

    // ======== For Owners =====
    // No need for transfer; that can be handled by the SimpleTransfer module

    public fun uid(namespace: &Namespace): &UID {
        &namespace.id
    }

    public fun uid_mut(namespace: &mut Namespace, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&namespace.id, auth), ESENDER_UNAUTHORIZED);

        &mut namespace.id
    }
}