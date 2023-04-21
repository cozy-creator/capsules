// Namespaces establish a single address that holds multiple packages within it. Such as a studio
// publishing multiple packages and then unifying all their server-permissions underneath a single principal
// address.
// A Namespace can store the RBAC records for an entire organization.
// The intent is that the Namespace object will be owned by a master-key, which is a multi-sig wallet,
// stored safely offline, and then used to grant various admin keypairs to servers. The rights of these servers
// can be carefully scoped, and keypairs rotated in and out using the master-key.
//
// Namespaces can also be used to delegate authority from a keypair to other addresses.
// A potential abuse vector is that a malicious actor could trick a user into mistakenly signing a
// namespace::create() transaction, creating a Namespace object for that user's keypair, while setting the
// malcious actor as the owner of it. If this were to occur, the malicious actor would have permanent control
// over the user's keypair. To prevent this, we disallow transferring ownership of Namespace objects created
// outside of using a publish_receipt, and the owner is permanently the principal.
//
// Security note: the principal address of a namespace is the package-id of the publish-receipt used to
// create it initially, or the user's address who created it initially. For security, we should
// make sure it's impossible to do tx_authority::add_id() with the package-id of the published
// package somehow, otherwise the security of namespaces will be compromised. In that case we'll
// use an alternative address as the principal address (perhaps a hash of something or just a random
// 32 byte value?).

module ownership::namespace {
    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui_utils::typed_id;
    
    use ownership::ownership;
    use ownership::publish_receipt::{Self, PublishReceipt};
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::rbac::{Self, RBAC};

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    use display::creator::{Self, Creator};

    // Error enums
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EPACKAGE_ALREADY_CLAIMED: u64 = 1;
    const EPACKAGES_MUST_BE_EMPTY: u64 = 2;

    // Shared, root-level object.
    // The principal (address) is stored within the RBAC, and cannot be changed after creation
    struct Namespace has key {
        id: UID,
        packages: vector<ID>,
        rbac: RBAC
    }

    // Placed on PublishReceipt to prevent namespaces from being claimed twice
    struct Key has store, copy, drop {}

    // Permission type; used to receive packages from another namespace
    struct RECEIVE_PACKAGE {}

    // Authority object
    struct Witness has drop {}

    // ======== Create Namespaces ======== 

    // Convenience entry function
    public entry fun claim_package(receipt: &mut PublishReceipt, ctx: &mut TxContext) {
        let namespace = claim_package_(receipt, tx_context::sender(ctx), &tx_authority::begin(ctx), ctx);
        return_and_share(namespace);
    }

    // Claim a namespace object from a publish receipt.
    // The principal (address) will be the first package-ID used. We can combine several packags under the
    // same namespace.
    public fun claim_package_(
        receipt: &mut PublishReceipt,
        owner: address,
        ctx: &mut TxContext
    ): Namespace {
        let package_id = publish_receipt::into_package_id(receipt);
        let rbac = rbac::create_internal(package_id);

        let namespace = Namespace { 
            id: object::new(ctx),
            packages: vector::empty(), 
            rbac 
        };

        // Initialize ownership
        let typed_id = typed_id::new(&namespace);
        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<Namespace, SimpleTransfer>(&mut namespace.id, typed_id, owner, &auth);

        add_package_internal(receipt, &mut namespace);

        namespace
    }

    public fun return_and_share(namespace: Namespace) {
        transfer::share_object(namespace);
    }

    // ======== Edit Namespaces =====
    // You must be the owner of a namespace to edit it. If you want to change owners, call into SimpleTransfer.
    // Ownership of namespaces created with anything other than a publish_receipt are non-transferable.

    // Only the namespace owner can add the package
    public fun add_package(receipt: &mut PublishReceipt, namespace: &mut Namespace, auth: &TxAuthority) {
        assert!(ownership::has_admin_permission(&namespace.id, auth), ENO_OWNER_AUTHORITY);

        add_package_internal(receipt, namespace);
    }

    // Ensures that a publish-receipt (package) can only ever be claimed once
    fun add_package_internal(receipt: &mut PublishReceipt, namespace: &mut Namespace) {
        let receipt_uid = publish_receipt::uid_mut(receipt);
        assert!(!dynamic_field::exists_(receipt_uid, Key { }), EPACKAGE_ALREADY_CLAIMED);
        dynamic_field::add(receipt_uid, Key { }, true);

        let package_id = publish_receipt::into_package_id(receipt);
        vector::push_back(&mut namespace.packages, package_id);
    }

    // Sui does not currently support multi-party transactions, so we cannot do this atomically in a single
    // transaction; we need both the sender and the recipient to sign for this.
    // TO DO: use a single-use permission for this
    public fun transfer_package(from: &mut Namespace, to: &mut Namespace, package_id: ID, auth: &TxAuthority) {
        assert!(namespace::has_permission<RECEIVE>(to, &auth), ENO_NAMESPACE_PERMISSION);

        // TO DO
    }

    // Note that this is currently not callable, because Sui does not yet support destroying shared
    // objects. To destroy a namespace, you must first remove any packages from it; this is to
    // prevent packages from being permanently orphaned without a namespace.
    public fun destroy(namespace: Namespace) {
        assert!(ownership::has_admin_permission(&namespace.id, auth), ENO_OWNER_AUTHORITY);
        assert!(vector::is_empty(&namespace.packages), EPACKAGES_MUST_BE_EMPTY);

        let Namespace { id, packages: _, rbac: _ } = namespace;
        object::delete(id);
    }

    // ======== RBAC Editor ========
    // This is just authority-checking + pass-through to the private RBAC editor API.



    // ======== For Agents ========
    // Agents should call into this to retrieve any permissions assigned to them and stored within the
    // namespace. These permissions are brought into the current transaction-exeuction to pass validity-
    // checks later.

    public fun claim_authority(namespace: &Namespace, ctx: &TxContext): TxAuthority {
        let agent = tx_context::sender(ctx);
        let auth = tx_authority::begin(ctx);
        claim_authority_internal(namespace, agent, &auth)
    }

    public fun claim_authority_(namespace: &Namespace, auth: &TxAuthority): TxAuthority {
        let i = 0;
        let agents = tx_authority::agents(auth);
        while (i < vector::length(&agents)) {
            auth = claim_authority_internal(namespace, vector::borrow(&agents, i), auth);
            i = i + 1;
        };
        
        auth
    }

    // I don't think this really needs to be internal?
    fun claim_authority_internal(namespace: &Namespace, agent: address, auth: &TxAuthority): TxAuthority {
        let (principal, agent_roles, role_permissions) = rbac::to_fields(&namespace.rbac);
        let roles = vec_map2::get_with_default(agent_roles, agent, vector::empty());

        auth = tx_authority::add_permissions_internal(principal, roles, role_permissions, auth);
        auth = claim_foreign(namespace, principal, auth);
        tx_authority::add_namespace_internal(namespace.packages, principal, auth)
    }

    fun claim_foreign(namespace: &Namespace, principal: address, auth: &TxAthority): TxAuthority {
        let permission = dynamic_field2::get_with_default(&namespace.id, Key { principal }, vector[]);
        auth = tx_authority::add_permissions_internal(principal, permission, auth);
    }

    // ======== Validity Checkers ========
    // Used by modules to assert the correct permissions are present

    // Convenience function
    public fun assert_login<Permission>(namespace: &Namespace, ctx: TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);
        assert_login_<Permission>(namespace, &auth)
    }

    // Log the agent into the namespace, and assert that they have the specified permission
    public fun assert_login_<Permission>(namespace: &Namespace, auth: &TxAuthority): TxAuthority {
        let auth = claim_authority_(namespace, auth);
        let principal = rbac::principal(&namespace.rbac);
        assert!(tx_authority::has_permission<Permission>(principal, &auth), ENO_PERMISSION);

        auth
    }

    // Convenience function. Permission and Namespace are the same module.
    public fun has_permission<Permission>(auth: &TxAuthority): bool {
        has_permission_<Permission, Permission>(auth)
    }

    // `NamespaceType` can be literally any type declared in any package belonging to that Namespace;
    // we merely use this type to figure out the package-id, so that we can lookup the Namespace that
    // owns that type (assuming it has been added to TxAuthority already).
    // In this case, Namespace is the principal.
    public fun has_permission_<NamespaceType, Permission>(auth: &TxAuthority): bool {
        let principal_maybe = tx_authority::lookup_namespace_for_package<NamespaceType>(auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);

       tx_authority::has_permission<Permission>(principal, auth)
    }

    // ======== Extend Pattern ========

    public fun uid(namespace: &Namespace): &UID {
        &namespace.id
    }

    public fun uid_mut(namespace: &mut Namespace, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_signed_by_owner(&namespace.id, auth), ENO_OWNER_AUTHORITY);

        &mut namespace.id
    }
}

// ======== Edit RBAC =====
// Due to the limitations of Sui (no client-side composition involving passing references) we provide
// a set of pass-through functions below, which allows the Namespace's RBAC to be edited by the
// Namespace's owner.

module ownership::namespace_rbac() {

    // TO DO

}


    // UPDATE: I think it's simply too dangerous to allow regular users to create Namespaces.
    // We restrict namespaces to only projects who are deploying packages, since they can be
    // assumed to have tighter security and greater security knowledge.

    // Convenience entry function
    // public entry fun create(ctx: &mut TxContext) {
    //     create_(tx_context::sender(ctx), &tx_authority::begin(ctx), ctx);
    // }

    // Create a namespace object for an address; packages will be empty but can be added later
    // Instead of returning the Namespace here, we force you to use a second transaction
    // to edit it; this is a safety measure. If a user were tricked into creating this, the
    // malicious actor will need to trick the user into signing a second transaction after this,
    // adding permissions to the Namespace object created here.
    // public fun create_(principal: address, auth: &TxAuthority, ctx: &mut TxContext) {
    //     assert!(tx_authority::has_admin_permission(principal, auth), ENO_ADMIN_AUTHORITY);

    //     let rbac = rbac::create(principal, &auth);
    //     let namespace = Namespace { 
    //         id: object::new(ctx),
    //         packages: vector::empty(), 
    //         rbac 
    //     };

    //     // Initialize ownership
    //     let typed_id = typed_id::new(&namespace);
    //     let auth = tx_authority::begin_with_type(&Witness { });
    //     // Owner == principal, and ownership of this object can never be changed since we do not
    //     // assign any transfer function here
    //     ownership::as_shared_object_(&mut namespace.id, typed_id, principal, vector::empty(), &auth);

    //     transfer::share_object(namespace);
    // }