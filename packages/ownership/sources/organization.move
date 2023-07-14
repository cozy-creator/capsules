// Organizations establish a single address that holds multiple packages within it. Such as a studio
// publishing multiple packages and then unifying all their server-actions underneath a single principal
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
// Security note: the principal address of a organization is the object-id of the organization object.
// This is safe, because it is a 'shared object' and you cannot add the object-id to tx_authority by
// mere possession (reference) of the object.
//
// If you want to rotate the master-key for a organization, you can simply send the organization to a new
// address using OrgTransfer.
// 
// Note that 'Organization' is distinct and separate from 'Person'; although they accomplish similar goals,
// namely they both act as a store of delegated actions on behalf of a principal, they accomplish this
// in different ways. For a 'Person' object, we delegate using 'action sets', meaning the end-user can
// delegate control of specific types and object-ids, in addition to just actions. This allows for
// very granular control. Organizations have less granular control, but use an RBAC (role based access control)
// scheme instead, allowing them to delegate actions to a large number of agents (keypairs) at one time
// efficiently.
// Additionally, Organization is built generally assuming that the user is more sophisticated and has
// better security practices, although for more potentially dangerous actions. Whereas Person is built with
// the assumption that the end-user may be easily phished.

module ownership::organization {
    use std::option;
    use std::string::String;
    use std::vector;

    use sui::dynamic_field;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui_utils::typed_id;
    use sui_utils::dynamic_field2;

    use ownership::action::ADMIN;
    use ownership::publish_receipt::{Self, PublishReceipt};
    use ownership::rbac::{Self, RBAC};
    use ownership::ownership::{Self, INITIALIZE};
    use ownership::org_transfer::OrgTransfer;
    use ownership::tx_authority::{Self, TxAuthority};

    // Error enums
    const ENO_PERMISSION: u64 = 0;
    const ENO_OWNER_AUTHORITY: u64 = 1;
    const EPACKAGE_ALREADY_CLAIMED: u64 = 2;
    const EPACKAGES_MUST_BE_EMPTY: u64 = 3;
    const ENO_MODULE_AUTHORITY: u64 = 4;
    const EPACKAGE_NOT_FOUND: u64 = 5;

    // The principal address (org-id) is also stored within the RBAC.
    // An organizationd ID cannot be changed after creation.
    //
    // All package-IDs stored within the Organization map to the same org-id; the org-id is the principal.
    // That means if you have action from the org-id, you have permision to all its packages. Whereas
    // if you only have action to one of its packages, that does not extend upwards to the organization
    // as a whole.
    //
    // Shared, root-level object.
    struct Organization has key {
        id: UID,
        packages: vector<Package>,
        rbac: RBAC
    }

    // This struct is normally stored with an Organization object, but it can also be stored elsewhere or
    // even be a root-level owned object; this is so that it can be transferred between Organizations.
    // You see, Sui does not yet support multi-signer-transactions, so we cannot transfer a pacakge between
    // Organizations atomically in a single transation. Rather, the sender must first remove the package from
    // its oOrganization and send it to the intended recipient. The recipient must then merge it into their
    // Organization.
    //
    // Owned object, root-level or stored
    struct Package has key, store {
        id: UID,
        package_id: ID
    }

    // Placed on PublishReceipt to prevent organizations from being claimed twice
    struct Key has store, copy, drop {}

    // Package Authority Witness
    struct Witness has drop {}

    // Action types
    struct REMOVE_PACKAGE {}
    struct ADD_PACKAGE {}
    // struct SINGLE_USE {} // issue single-use actions on behalf of the organization

    // ======== Create Organizations ======== 

    // Claim an organization object from a publish receipt.
    // The organization-address (principal) will be generated and cannot be changed. The org-id is the
    // same as this object-ID.
    // Organization objects allow us to combine several packages under the same organization.
    public fun create_from_receipt(
        receipt: &mut PublishReceipt,
        owner: address,
        ctx: &mut TxContext
    ): Organization {
        let organization = create_internal(owner, ctx);
        add_package_internal(receipt, &mut organization, ctx);
        organization
    }

    fun create_internal(owner: address, ctx: &mut TxContext): Organization {
        let org_uid = object::new(ctx);
        let rbac = rbac::create(object::uid_to_address(&org_uid));

        let organization = Organization { 
            id: org_uid,
            packages: vector::empty(),
            rbac 
        };

        // Initialize ownership
        let typed_id = typed_id::new(&organization);
        let auth = tx_authority::begin_with_package_witness<Witness, INITIALIZE>(Witness { });
        ownership::as_shared_object<Organization, OrgTransfer>(&mut organization.id, typed_id, owner, &auth);

        organization
    }

    // Only the organization owner can add the package
    public fun add_package(
        receipt: &mut PublishReceipt,
        organization: &mut Organization,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        assert!(ownership::can_act_as_owner<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);

        add_package_internal(receipt, organization, ctx);
    }

    fun add_package_internal(
        receipt: &mut PublishReceipt,
        organization: &mut Organization,
        ctx: &mut TxContext
    ) {
        // Ensures that a publish-receipt (package) can only ever be claimed once
        let receipt_uid = publish_receipt::uid_mut(receipt);
        assert!(!dynamic_field::exists_(receipt_uid, Key { }), EPACKAGE_ALREADY_CLAIMED);
        dynamic_field::add(receipt_uid, Key { }, true);

        let package_id = publish_receipt::into_package_id(receipt);
        vector::push_back(&mut organization.packages, Package { id: object::new(ctx), package_id });
    }

    public fun return_and_share(organization: Organization) {
        transfer::share_object(organization);
    }

    // Note that this is currently not callable, because Sui does not yet support destroying shared
    // objects. To destroy a organization, you must first remove any packages from it; this is to
    // prevent packages from being permanently orphaned without a organization.
    public fun destroy(organization: Organization, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);
        assert!(vector::is_empty(&organization.packages), EPACKAGES_MUST_BE_EMPTY);

        let Organization { id, packages, rbac: _ } = organization;
        object::delete(id);
        vector::destroy_empty(packages);
    }

    // ======== Edit Organizations =====
    // You must be the owner of a organization to edit it. If you want to change owners, call into OrgTransfer.
    // Ownership of organizations created with anything other than a publish_receipt are non-transferable.

    // Abort if package_id does not exist within the organization
    public fun remove_package(
        organization: &mut Organization,
        package_id: ID,
        auth: &TxAuthority
    ): Package {
        assert!(ownership::can_act_as_owner<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);

        let i = 0;
        while (i < vector::length(&organization.packages)) {
            let package = vector::borrow(&organization.packages, i);
            if (package.package_id == package_id) {
                return vector::remove(&mut organization.packages, i)
            };
            i = i + 1;
        };

        abort EPACKAGE_NOT_FOUND
    }

    public fun create_from_package(package: Package, owner: address, ctx: &mut TxContext): Organization {
        let organization = create_internal(owner, ctx);
        vector::push_back(&mut organization.packages, package);
        organization
    }

    public fun add_package_from_stored(
        organization: &mut Organization,
        package: Package,
        auth: &TxAuthority
    ) {
        assert!(ownership::can_act_as_owner<ADMIN>(&organization.id, auth), ENO_OWNER_AUTHORITY);

        vector::push_back(&mut organization.packages, package);
    }

    // ======== RBAC Editor ========
    // This is just a pass-through layer into RBAC itself + authority-checking + pass-through
    // The RBAC editor is private, and can only be accessed via this organization module

    public fun set_role_for_agent(org: &mut Organization, agent: address, role: String, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&org.id, auth), ENO_OWNER_AUTHORITY);

        rbac::set_role_for_agent(&mut org.rbac, agent, role);
    }

    public fun delete_agent(org: &mut Organization, agent: address, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&org.id, auth), ENO_OWNER_AUTHORITY);

        rbac::delete_agent(&mut org.rbac, agent);
    }

    public fun grant_action_to_role<Action>(org: &mut Organization, role: String, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&org.id, auth), ENO_OWNER_AUTHORITY);

        rbac::grant_action_to_role<Action>(&mut org.rbac, role);
    }

    public fun revoke_action_from_role<Action>(org: &mut Organization, role: String, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&org.id, auth), ENO_OWNER_AUTHORITY);

        rbac::revoke_action_from_role<Action>(&mut org.rbac, role);
    }

    public fun delete_role_and_agents(org: &mut Organization, role: String, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&org.id, auth), ENO_OWNER_AUTHORITY);

        rbac::delete_role_and_agents(&mut org.rbac, role);
    }

    // ======== For Agents ========
    // Agents should call into this to retrieve any actions assigned to them and stored within the
    // organization. These actions are brought into the current transaction-exeuction to pass validity-
    // checks later.

    public fun claim_actions(organization: &Organization, ctx: &TxContext): TxAuthority {
        let agent = tx_context::sender(ctx);
        let auth = tx_authority::begin(ctx);
        auth = claim_actions_for_agent(organization, agent, &auth);
        let packages = packages(organization);
        tx_authority::add_organization_internal(packages, principal(organization), &auth)
    }

    public fun claim_actions_(organization: &Organization, auth: &TxAuthority): TxAuthority {
        let (i, new_auth) = (0, tx_authority::copy_(auth));
        let agents = tx_authority::agents(&new_auth);
        while (i < vector::length(&agents)) {
            let agent = *vector::borrow(&agents, i);
            new_auth = claim_actions_for_agent(organization, agent, &new_auth);
            i = i + 1;
        };
        let packages = packages(organization);
        tx_authority::add_organization_internal(packages, principal(organization), &new_auth)
    }

    // This function could safely be public, but we want users to use one of the above-two functions
    // The owner-address of an Organization automatically gets an ADMIN role over the organization;
    // there's no need to add a special role for the owner
    fun claim_actions_for_agent(organization: &Organization, agent: address, auth: &TxAuthority): TxAuthority {
        let actions = if (ownership::get_owner(&organization.id) == option::some(agent)) {
            rbac::get_admin()
        } else {
            rbac::get_agent_actions(&organization.rbac, agent)
        };
        
        let principal = principal(organization);
        tx_authority::add_actions_internal(principal, agent, actions, auth)
    }

    // Convenience function
    public fun assert_login<Action>(organization: &Organization, ctx: &TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);
        assert_login_<Action>(organization, &auth)
    }

    // Log the agent into the organization, and assert that they have the specified action
    public fun assert_login_<Action>(organization: &Organization, auth: &TxAuthority): TxAuthority {
        let auth = claim_actions_(organization, auth);
        let principal = rbac::principal(&organization.rbac);
        assert!(tx_authority::can_act_as_address<Action>(principal, &auth), ENO_PERMISSION);

        auth
    }

    // This is helpful if you just want to define this organization within the current TxAuthority,
    // and you don't care about searching for any stored actions inside the organization itself.
    public fun add_to_tx_authority(organization: &Organization, auth: &TxAuthority): TxAuthority {
        let packages = packages(organization);
        tx_authority::add_organization_internal(packages, principal(organization), auth)
    }

    // ======== Single Use Actions ========

    // In order to issue a single-use action, the agent calling into this must:
    // (1) have (organization, Action); the agent already has this action (or higher), and
    // (2) have (organization, SINGLE_USE); the agent was granted the authority to issue single-use actions 
    // (or is an admin; the manager role is not sufficient)
    // public fun create_single_use_action<Action>(
    //     auth: &TxAuthority,
    //     ctx: &mut TxContext
    // ): SingleUseAction {
    //     let principal = option::destroy_some(tx_authority::lookup_organization_for_package<Action>(auth));

    //     assert!(
    //         tx_authority::has_package_action_excluding_manager<Action, SINGLE_USE>(auth),
    //         ENO_OWNER_AUTHORITY);
    //     assert!(tx_authority::can_act_as_address<Action>(principal, auth), ENO_OWNER_AUTHORITY);

    //     action::create_single_use<Action>(principal, ctx)
    // }

    // This is a module-witness pattern; this is equivalent to a storable Witness
    // public fun create_single_use_action_from_witness<Witness: drop, Action>(
    //     _witness: Witness,
    //     ctx: &mut TxContext
    // ): SingleUseAction {
    //     // This ensures that the Witness supplied is the module-authority Witness corresponding to `Action`
    //     assert!(tx_authority::is_module_authority<Witness, Action>(), ENO_MODULE_AUTHORITY);

    //     action::create_single_use<Action>(encode::type_into_address<Witness>(), ctx)
    // }

    // ======== Getter Functions ========

    public fun principal(organization: &Organization): address {
        rbac::principal(&organization.rbac)
    }

    public fun packages(organization: &Organization): vector<ID> {
        let (i, result) = (0, vector::empty<ID>());
        while (i < vector::length(&organization.packages)) {
            let package = vector::borrow(&organization.packages, i);
            vector::push_back(&mut result, package.package_id);
            i = i + 1;
        };

        result
    }

     // ======== Organization Endorsement System =====
    // This is part of Capsule's on-chain Trust and Safety system
    //
    // Organizations can be independently endorsed by trusted entities; the owner of the Organization object's
    // consent is not required to add or remove endorsements.
    //
    // Objects that originate from packages whose organizations are not endorsed by a trusted authority
    // should not be displayed in wallets / marketplaces, and should be viewed as spam.
    //
    // We use dynamic fields, rather than vectors, because it scales O(1) instead of O(n) for n endorsements.

    // Dynamic field key
    struct Endorsement has store, copy, drop { from: address }

    // Action type
    struct ENDORSE {}
    
    public fun add_endorsement(org: &mut Organization, from: address, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_address<ENDORSE>(from, auth), ENO_PERMISSION);

        dynamic_field2::set<Endorsement, bool>(&mut org.id, Endorsement { from }, true);
    }

    public fun remove_endorsement(org: &mut Organization, from: address, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_address<ENDORSE>(from, auth), ENO_PERMISSION);

        dynamic_field2::drop<Endorsement, bool>(&mut org.id, Endorsement { from });
    }

    public fun is_endorsed_by(org: &Organization, from: address): bool {
        dynamic_field::exists_(&org.id, Endorsement { from })
    }

    // Useful to see if this org has been endorsed by a minimum threshold of trusted entities
    public fun is_endorsed_by_num(org: &Organization, endorsers: vector<address>): u64 {
        let (count, i) = (0, 0);
        while (i < vector::length(&endorsers)) {
            if (is_endorsed_by(org, *vector::borrow(&endorsers, i))) {
                count = count + 1;
            };
            i = i + 1;
        };

        count
    }

    // FUTURE: Perhaps we should have an endorsement system for packages as well?
    // Perhaps to marke if a package is audited or not, or its current version / type, etc.?
    // FUTURE: we could possibly store upgrade-caps, publish-receipts, or Display-objects as well

    // ======== Extend Pattern ========

    public fun uid(organization: &Organization): &UID {
        &organization.id
    }

    public fun uid_mut(organization: &mut Organization, auth: &TxAuthority): &mut UID {
        assert!(ownership::can_borrow_uid_mut(&organization.id, auth), ENO_PERMISSION);

        &mut organization.id
    }

    public fun package_uid(package: &Package): &UID {
        &package.id
    }

    public fun package_uid_(organization: &Organization, package_id: ID): &UID {
        let i = 0;
        while (i < vector::length(&organization.packages)) {
            let package = vector::borrow(&organization.packages, i);
            if (package.package_id == package_id) {
                return &package.id
            };
            i = i + 1;
        };

        abort EPACKAGE_NOT_FOUND
    }

    public fun package_uid_mut(package: &mut Package): &mut UID {
        // No need for ownership check because Package is a single-writer object
        &mut package.id
    }

    public fun package_uid_mut_(organization: &mut Organization, package_id: ID, auth: &TxAuthority): &mut UID {
        assert!(ownership::can_borrow_uid_mut(&organization.id, auth), ENO_PERMISSION);

        let i = 0;
        while (i < vector::length(&organization.packages)) {
            let package = vector::borrow_mut(&mut organization.packages, i);
            if (package.package_id == package_id) {
                return &mut package.id
            };
            i = i + 1;
        };

        abort EPACKAGE_NOT_FOUND
    }

    // ======== Convenience Entry Functions For Creation / Deletion ========
    // These improve usability by making organization functions callable directly by the Sui CLI; no need
    // for client-side composition to construct a TxAuthority object.

    public entry fun create_from_receipt_(
        receipt: &mut PublishReceipt,
        ctx: &mut TxContext
    ) {
        let organization = create_from_receipt(receipt, tx_context::sender(ctx), ctx);
        return_and_share(organization);
    }

    public entry fun create_from_package_(
        stored: Package,
        ctx: &mut TxContext
    ) {
        let organization = create_from_package(stored, tx_context::sender(ctx), ctx);
        return_and_share(organization);
    }

    public entry fun add_package_(
        organization: &mut Organization,
        receipt: &mut PublishReceipt,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        add_package(receipt, organization, &auth, ctx)
    }

    public entry fun add_package_from_stored_(
        organization: &mut Organization,
        stored: Package,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        add_package_from_stored(organization, stored, &auth)
    }

    public entry fun remove_package_(
        organization: &mut Organization,
        package_id: ID,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        let package = remove_package(organization, package_id, &auth);
        transfer::transfer(package, recipient);
    }

    public entry fun destroy_(
        organization: Organization,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        destroy(organization, &auth);
    }

    // ========== Convenience Entry Functions For Managing Agents ==========

    public entry fun delete_agent_(
        organization: &mut Organization,
        agent: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        delete_agent(organization, agent, &auth);
    }

    public entry fun set_role_for_agent_(
        organization: &mut Organization,
        agent: address,
        role: String,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        set_role_for_agent(organization, agent, role, &auth);
    }

    public entry fun grant_action_to_role_<Action>(
        organization: &mut Organization,
        role: String,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        grant_action_to_role<Action>(organization, role, &auth)
    }

    public entry fun revoke_action_from_role_<Action>(
        organization: &mut Organization,
        role: String,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        revoke_action_from_role<Action>(organization, role, &auth)
    }

    public entry fun delete_role_and_agents_(
        organization: &mut Organization,
        role: String,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        delete_role_and_agents(organization, role, &auth)
    }

    // ========== Convenience Entry Functions For Managing Endorsements ==========

    public entry fun add_endorsement_(
        organization: &mut Organization,
        from: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        add_endorsement(organization, from, &auth)
    }

    public entry fun remove_endorsement_(
        organization: &mut Organization,
        from: address,
        ctx: &TxContext
    ) {
        let auth = tx_authority::begin(ctx);
        remove_endorsement(organization, from, &auth)
    }
}
