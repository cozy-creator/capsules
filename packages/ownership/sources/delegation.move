module ownership::delegation {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use sui_utils::struct_tag::StructTag;

    use ownership::permission::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};

    const ENO_ADMIN_AUTHORITY: u8 = 0;

    // Root-level, shared object. The owner is the principle, and is immutable (non-transferable).
    // This serves a purpose similar to RBAC, in that it stores permissions
    struct DelegationStore has key {
        id: UID,
        principal: address,
        agent_delegations: VecMap<address, Delegation>,
    }

    // `types` or `objects` being empty means that all types / all object-ids are allowed, in other
    // words, no constraint is imposed.
    // This struct is analgous to RBAC in ownership::organization
    //
    // Example: I want you to be able to edit all Capsuleverse objects
    // permissions: [EDIT], types: [Capsuleverse], objects: [ANY]
    //
    // I want you to be able to withdraw from a set of accounts:
    // permissions: [WITHDRAW], types: [ANY], objects: [account1, account2]
    //
    // I want you to be able to sell any of my Outlaws:
    // permissions: [SELL], types: [Outlaw], objects: []
    //
    // Result: [EDIT, WITHDRAW, SELL], types: [Capsuleverse, Outlaw], objects: [account1, account2]
    //
    // I want you to be able to sell any object I own:
    // permission: [SELL], types: [ANY], objects: [ANY] (<-- risky)
    //
    struct Delegation has store, copy, drop {
        permissions: vector<Permission>,
        types: vector<StructTag>,
        objects: vector<ID>
    }

    // ======= For Owners =======

    public fun create(ctx: &mut TxContext): DelegationStore {
        DelegationStore {
            id: object::new(ctx),
            principal: tx_context::sender(ctx)
        }
    }

    public fun create_(principal: address, auth: &TxAuthority, ctx: &mut TxContext): DelegationStore {
        assert!(tx_authority::has_permission<ADMIN>(principal, auth), ENO_ADMIN_AUTHORITY);

        DelegationStore {
            id: object::new(ctx),
            principal
        }
    }

    public fun return_and_share(store: DelegationStore) {
        transfer::share_object(store);
    }

    // This won't work yet, but it will once Sui supports deleting shared objects (late 2023)
    public fun destroy(store: DelegationStore, auth: &TxAuthority) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_OWNER_AUTHORITY);

        let DelegationStore = { id, principal: _, agent_delegations: _ } = store;
        object::delete(id);
    }

    // ======= Modify Agent Permissions =======
    // We currently restrict adding ADMIN or MANAGER permissions generally, as this would be too
    // dangerous and would allow phishers to take over another person's account. We do however allow
    // it for specific types and objects.

    public fun add_general_permission<Permission>(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {

    }

    public fun add_permission_for_type<ObjectType, Permission>(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {

    }

    // Using struct-tag allows for us to match entire classes of types; adding an abstract type without
    // its generics will match all concrete-types that implement it. Missing generics are treated as *
    // wildcard when type-matching.
    // For example: StructTag { address: 0x2, module_name: coin, struct_name: Coin, generics: [] } will match
    // all Coin<*> types. Effectively, this grants the permission over all Coin types. If you don't want this
    // behavior, simpliy specify the generics, like Coin<SUI>.
    public fun add_permission_for_type_<Permission>(
        store: &mut DelegationStore,
        agent: address,
        type: StructTag,
        auth: &TxAuthority
    ) {

    }

    public fun add_permission_for_objects<Permission>(
        store: &mut DelegationStore,
        agent: address,
        objects: vector<ID>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_OWNER_AUTHORITY);

        let fallback = tx_authority::new_permission_set_empty();
        let permission_set = dynamic_field2::borrow_mut_fill<address, PermissionSet>(
            &mut store.id, agent, fallback);

        let i = 0;
        while (i < vector::length(&objects)) {
            let object_id = *vector::borrow(&objects, i);
            let object_permissions = vec_map::borrow_mut_fill(&mut permission_set.objects, object_id, vector[]);
            let permission = permissions::new<Permission>();
            vector2::push_back_unique(&mut object_permissions, permission);
            i = i + 1;
        };
        vector2::merge(&permission_set, objects);
    }

    public fun revoke_general_permission() {

    }

    public fun revoke_all_general_permissions() {

    }

    public fun remove_permission_for_types() {

    }

    public fun remove_permission_for_types_() {

    }

    public fun revoke_all_permissions_for_types() {

    }

    public fun revoke_all_permissions_for_types_() {

    }

    public fun revoke_permission_for_objects() {

    }

    public fun revoke_all_permissions_for_objects() {

    }

    public fun remove_agent() {

    }

    // ?????????
    public fun add_to_delegation<Permission>(
        store: &mut DelegationStore,
        agent: address,
        permitted_types: vector<StructTag>,
        permitted_objects: vector<ID>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_OWNER_AUTHORITY);

        let delegation = Delegation {
            permissions: vec![Permission],
            types: vec![],
            objects: vec![]
        };

        vec_map::insert(store.agent_delegations, agent, delegation);
    }

    // ======= For Agents =======

    public fun claim_delegation(store: &DelegationStore, ctx: &TxContext): TxAuthority {
        let for = tx_context::sender(ctx);
    }

    public fun claim_delegation<T>(store: &DelegationStore, auth: &TxAuthority): TxAuthority {
        let type = encode::type_name<T>();
        let agents = tx_authority::agents(auth);
        let i = 0;
        while (i < vector::length(&agents)) {   
            let agent = *vector::borrow(&agents, i);
            let permissions = get_permissions(store, agent);
            auth = tx_authority::add_type_permissions(type, permissions, auth);
            i = i + 1;
        };

        auth
    }

    public fun claim_delegation(store: &DelegationStore, object_id: ID, auth: &TxAuthority): TxAuthority {
        let for = tx_authority::for(auth);// Doesn't exist
        let permissions = dynamic_field::borrow(&store.id, Key { for, object_id });
        tx_authority::add_permissions(permissions, auth);
    }

    // ======= Convenience Entry Functions =======

}