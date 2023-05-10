// Organizations establish a single address that holds multiple packages within it. Such as a studio
// publishing multiple packages and then unifying all their server-permissions underneath a single principal
// address.
// A Organization can store the RBAC records for an entire organization.
// The intent is that the Organization object will be owned by a master-key, which is a multi-sig wallet,
// stored safely offline, and then used to grant various admin keypairs to servers. The rights of these servers
// can be carefully scoped, and keypairs rotated in and out using the master-key.
//
// Organizations can also be used to delegate authority from a keypair to other addresses.
// A potential abuse vector is that a malicious actor could trick a user into mistakenly signing a
// organization::create() transaction, creating a Organization object for that user's keypair, while setting the
// malcious actor as the owner of it. If this were to occur, the malicious actor would have permanent control
// over the user's keypair. To prevent this, we disallow transferring ownership of Organization objects created
// outside of using a publish_receipt, and the owner is permanently the principal.
//
// Security note: the principal address of a organization is the package-id of the publish-receipt used to
// create it initially, or the user's address who created it initially. For security, we should
// make sure it's impossible to do tx_authority::add_id() with the package-id of the published
// package somehow, otherwise the security of organizations will be compromised. In that case we'll
// use an alternative address as the principal address (perhaps a hash of something or just a random
// 32 byte value?).
//
// If you want to rotate the master-key for a organization, you can simply send the organization to a new
// address using SimpleTransfer.

module ownership::organization {
    use std::option;
    use std::string::String;
    use std::vector;

    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui_utils::encode;
    use sui_utils::typed_id;
    use sui_utils::vector2;

    use ownership::client;
    use ownership::ownership;
    use ownership::permissions::{Self, SingleUsePermission, ADMIN};
    use ownership::publish_receipt::{Self, PublishReceipt};
    use ownership::rbac::{Self, RBAC};
    use ownership::simple_transfer::Witness as SimpleTransfer;
    use ownership::tx_authority::{Self, TxAuthority};

    // Error enums
    const ENO_PERMISSION: u64 = 0;
    const ENO_OWNER_AUTHORITY: u64 = 1;
    const EPACKAGE_ALREADY_CLAIMED: u64 = 2;
    const EPACKAGES_MUST_BE_EMPTY: u64 = 3;
    const ENO_MODULE_AUTHORITY: u64 = 4;

    // Shared, root-level object.
    // The principal (address) is stored within the RBAC, and cannot be changed after creation
    struct Organization has key {
        id: UID,
        packages: vector<ID>,
        rbac: RBAC
    }

    // Placed on PublishReceipt to prevent organizations from being claimed twice
    struct Key has store, copy, drop {}

    // Permission types
    struct REMOVE_PACKAGE {}
    struct ADD_PACKAGE {}
    struct SINGLE_USE {} // issue single-use permissions on behalf of the organization

    // Authority object
    struct Witness has drop {}

    // ======== Create Organizations ======== 

    // Convenience entry function
    public entry fun create_from_package(receipt: &mut PublishReceipt, ctx: &mut TxContext) {
        let organization = create_from_package_(receipt, tx_context::sender(ctx), ctx);
        return_and_share(organization);
    }

    // Claim a organization object from a publish receipt.
    // The principal (address) will be the first package-ID used. We can combine several packags under the
    // same organization.
    public fun create_from_package_(
        receipt: &mut PublishReceipt,
        owner: address,
        ctx: &mut TxContext
    ): Organization {
        let package_id = publish_receipt::into_package_id(receipt);
        let rbac = rbac::create(object::id_to_address(&package_id));

        let organization = Organization { 
            id: object::new(ctx),
            packages: vector::empty(), 
            rbac 
        };

        // Initialize ownership
        let typed_id = typed_id::new(&organization);
        let auth = tx_authority::begin_with_type(&Witness { });
        ownership::as_shared_object<Organization, SimpleTransfer>(&mut organization.id, typed_id, owner, &auth);

        add_package_internal(receipt, &mut organization);

        organization
    }

    public fun return_and_share(organization: Organization) {
        transfer::share_object(organization);
    }

    // Note that this is currently not callable, because Sui does not yet support destroying shared
    // objects. To destroy a organization, you must first remove any packages from it; this is to
    // prevent packages from being permanently orphaned without a organization.
    public fun destroy(organization: Organization, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);
        assert!(vector::is_empty(&organization.packages), EPACKAGES_MUST_BE_EMPTY);

        let Organization { id, packages: _, rbac: _ } = organization;
        object::delete(id);
    }

    // ======== Edit Organizations =====
    // You must be the owner of a organization to edit it. If you want to change owners, call into SimpleTransfer.
    // Ownership of organizations created with anything other than a publish_receipt are non-transferable.

    // This is a special struct that acts as an intermediary to transfer packages between organizations.
    // This is necessary because Sui does not support multi-signer-transactions, so we cannot do this
    // exchange atomically in a single transaction. Rather, the sender must first remove the package from its
    // organization and send it to the intended recipient. The recipient must then merge it into their organization.
    struct StoredPackage has key, store {
        id: UID,
        package: ID
    }

    // Only the organization owner can add the package
    public fun add_package(receipt: &mut PublishReceipt, organization: &mut Organization, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);

        add_package_internal(receipt, organization);
    }

    // Ensures that a publish-receipt (package) can only ever be claimed once
    fun add_package_internal(receipt: &mut PublishReceipt, organization: &mut Organization) {
        let receipt_uid = publish_receipt::uid_mut(receipt);
        assert!(!dynamic_field::exists_(receipt_uid, Key { }), EPACKAGE_ALREADY_CLAIMED);
        dynamic_field::add(receipt_uid, Key { }, true);

        let package_id = publish_receipt::into_package_id(receipt);
        vector::push_back(&mut organization.packages, package_id);
    }

    // Aborst if package_id does not exist within the organization
    public fun remove_package(
        organization: &mut Organization,
        package_id: ID,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): StoredPackage {
        assert!(ownership::has_owner_permission<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);

        let package = option::destroy_some(vector2::remove_maybe(&mut organization.packages, &package_id));
        StoredPackage {
            id: object::new(ctx),
            package
        }
    }

    public fun add_package_from_stored(
        organization: &mut Organization,
        stored_package: StoredPackage,
        auth: &TxAuthority
    ) {
        assert!(ownership::has_owner_permission<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);

        let StoredPackage { id, package } = stored_package;
        object::delete(id);

        vector::push_back(&mut organization.packages, package);
    }

    // ======== RBAC Editor ========
    // This is just a pass-through layer into RBAC itself + authority-checking + pass-through
    // The RBAC editor is private, and can only be accessed via this organization module

    public fun set_role_for_agent_(ns: &mut Organization, agent: address, role: String, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(&ns.id, auth), ENO_OWNER_AUTHORITY);

        rbac::set_role_for_agent(&mut ns.rbac, agent, role);
    }

    // public fun grant_admin_role_for_agent(ns: &mut Organization, agent: address, auth: &TxAuthority) {
    //     assert!(ownership::has_owner_permission<ADMIN>(&ns.id, auth), ENO_OWNER_AUTHORITY);

    //     rbac::grant_admin_role_for_agent(&mut ns.rbac, agent);
    // }

    // public fun grant_manager_role_for_agent(ns: &mut Organization, agent: address, auth: &TxAuthority) {
    //     assert!(ownership::has_owner_permission<ADMIN>(&ns.id, auth), ENO_OWNER_AUTHORITY);

    //     rbac::grant_manager_role_for_agent(&mut ns.rbac, agent);
    // }

    public fun delete_agent(ns: &mut Organization, agent: address, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(&ns.id, auth), ENO_OWNER_AUTHORITY);

        rbac::delete_agent(&mut ns.rbac, agent);
    }

    public fun grant_permission_to_role<Permission>(ns: &mut Organization, role: String, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(&ns.id, auth), ENO_OWNER_AUTHORITY);

        rbac::grant_permission_to_role<Permission>(&mut ns.rbac, role);
    }

    public fun revoke_permission_from_role<Permission>(ns: &mut Organization, role: String, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(&ns.id, auth), ENO_OWNER_AUTHORITY);

        rbac::revoke_permission_from_role<Permission>(&mut ns.rbac, role);
    }

    public fun delete_role_and_agents(ns: &mut Organization, role: String, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<ADMIN>(&ns.id, auth), ENO_OWNER_AUTHORITY);

        rbac::delete_role_and_agents(&mut ns.rbac, role);
    }

    // ======== For Agents ========
    // Agents should call into this to retrieve any permissions assigned to them and stored within the
    // organization. These permissions are brought into the current transaction-exeuction to pass validity-
    // checks later.

    public fun claim_permissions(organization: &Organization, ctx: &TxContext): TxAuthority {
        let agent = tx_context::sender(ctx);
        let auth = tx_authority::begin(ctx);
        auth = claim_permissions_for_agent(organization, agent, &auth);
        tx_authority::add_organization_internal(organization.packages, principal(organization), &auth)
    }

    public fun claim_permissions_(organization: &Organization, auth: &TxAuthority): TxAuthority {
        let (i, auth) = (0, tx_authority::copy_(auth));
        let agents = tx_authority::agents(&auth);
        while (i < vector::length(&agents)) {
            let agent = *vector::borrow(&agents, i);
            auth = claim_permissions_for_agent(organization, agent, &auth);
            i = i + 1;
        };
        
        tx_authority::add_organization_internal(organization.packages, principal(organization), &auth)
    }

    // This function could safely be public, but we want users to use one of the above-two functions
    fun claim_permissions_for_agent(organization: &Organization, agent: address, auth: &TxAuthority): TxAuthority {
        let permissions = rbac::get_agent_permissions(&organization.rbac, agent);
        let principal = principal(organization);
        tx_authority::add_permissions_internal(principal, agent, permissions, auth)
    }

    // Convenience function
    public fun assert_login<Permission>(organization: &Organization, ctx: &TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);
        assert_login_<Permission>(organization, &auth)
    }

    // Log the agent into the organization, and assert that they have the specified permission
    public fun assert_login_<Permission>(organization: &Organization, auth: &TxAuthority): TxAuthority {
        let auth = claim_permissions_(organization, auth);
        let principal = rbac::principal(&organization.rbac);
        assert!(tx_authority::has_permission<Permission>(principal, &auth), ENO_PERMISSION);

        auth
    }

    // This is helpful if you just want to define this organization within the current TxAuthority,
    // and you don't care about searching for any stored permissions inside the organization itself.
    public fun add_to_tx_authority(organization: &Organization, auth: &TxAuthority): TxAuthority {
        tx_authority::add_organization_internal(organization.packages, principal(organization), auth)
    }

    // ======== Single Use Permissions ========

    // In order to issue a single-use permission, the agent calling into this must:
    // (1) have (organization, Permission); the agent already has this permission (or higher), and
    // (2) have (organization, SINGLE_USE); the agent was granted the authority to issue single-use permissions 
    // (or is an admin; the manager role is not sufficient)
    public fun create_single_use_permission<Permission>(
        auth: &TxAuthority,
        ctx: &mut TxContext
    ): SingleUsePermission {
        let principal = option::destroy_some(tx_authority::lookup_organization_for_package<Permission>(auth));

        assert!(tx_authority::has_org_permission_excluding_manager<Permission, SINGLE_USE>(auth), ENO_OWNER_AUTHORITY);
        assert!(tx_authority::has_permission<Permission>(principal, auth), ENO_OWNER_AUTHORITY);

        permissions::create_single_use<Permission>(principal, ctx)
    }

    // This is a module-witness pattern; this is equivalent to a storable Witness
    public fun create_single_use_permission_from_witness<Witness: drop, Permission>(
        _witness: Witness,
        ctx: &mut TxContext
    ): SingleUsePermission {
        // This ensures that the Witness supplied is the module-authority Witness corresponding to `Permission`
        assert!(tx_authority::is_module_authority<Witness, Permission>(), ENO_MODULE_AUTHORITY);

        permissions::create_single_use<Permission>(encode::type_into_address<Witness>(), ctx)
    }

    // ======== Getter Functions ========

    public fun principal(organization: &Organization): address {
        rbac::principal(&organization.rbac)
    }

    public fun packages(organization: &Organization): vector<ID> {
        organization.packages
    }

    // ======== Extend Pattern ========

    public fun uid(organization: &Organization): &UID {
        &organization.id
    }

    public fun uid_mut(organization: &mut Organization, auth: &TxAuthority): &mut UID {
        assert!(client::can_borrow_uid_mut(&organization.id, auth), ENO_PERMISSION);

        &mut organization.id
    }

    // ======== Convenience Entry Functions ========
    // These improve usability by making organization functions callable directly by the Sui CLI; no need
    // for client-side composition to construct a TxAuthority object.

    public entry fun remove_package_(
        organization: &mut Organization,
        package_id: ID,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        let stored_package = remove_package(organization, package_id, &auth, ctx);
        transfer::transfer(stored_package, recipient);
    }

    public entry fun set_role_for_agent(ns: &mut Organization, agent: address, role: String, ctx: &TxContext) {
        let auth = tx_authority::begin(ctx);
        set_role_for_agent_(ns, agent, role, &auth);
    }

}


    // UPDATE: I think it's simply too dangerous to allow regular users to create Organizations.
    // We restrict organizations to only projects who are deploying packages, since they can be
    // assumed to have tighter security and greater security knowledge.

    // Convenience entry function
    // public entry fun create(ctx: &mut TxContext) {
    //     create_(tx_context::sender(ctx), &tx_authority::begin(ctx), ctx);
    // }

    // Create a organization object for an address; packages will be empty but can be added later
    // Instead of returning the Organization here, we force you to use a second transaction
    // to edit it; this is a safety measure. If a user were tricked into creating this, the
    // malicious actor will need to trick the user into signing a second transaction after this,
    // adding permissions to the Organization object created here.
    // public fun create_(principal: address, auth: &TxAuthority, ctx: &mut TxContext) {
    //     assert!(tx_authority::has_admin_permission(principal, auth), ENO_ADMIN_AUTHORITY);

    //     let rbac = rbac::create(principal, &auth);
    //     let organization = Organization { 
    //         id: object::new(ctx),
    //         packages: vector::empty(), 
    //         rbac 
    //     };

    //     // Initialize ownership
    //     let typed_id = typed_id::new(&organization);
    //     let auth = tx_authority::begin_with_type(&Witness { });
    //     // Owner == principal, and ownership of this object can never be changed since we do not
    //     // assign any transfer function here
    //     ownership::as_shared_object_(&mut organization.id, typed_id, principal, vector::empty(), &auth);

    //     transfer::share_object(organization);
    // }