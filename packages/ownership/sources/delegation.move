// Store delegation -> claim delegation -> merge-into tx_authority -> check tx_authority

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

// ===== Permission Chaining =====
//
// `Owner` signs EDIT control to `Organization`. `Organization` then signs EDIT control to `Server`.
// `Server` logs into `Organization` and claims EDIT control as Organization; this adds
// `EDIT as Organization` to TxAuthority.
// The server then logs into `Owner` delegation, and retrieves `EDIT` on behalf of the Organization.
// The server now has `EDIT as Owner`.
// We call this sort of A -> B -> C indirect delegation "delegation chaining" and it is a powerful
// primitive.
// Chaining even works for objects! Not just 'general'

// We currently restrict adding ADMIN or MANAGER permissions in delegation generally, as this would be
// too dangerous and would allow phishers to take over another person's entire account. HOWEVER we do
// allow it for specific types and objects.

module ownership::delegation {
    use std::vector;

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use sui_utils::struct_tag::StructTag;

    use ownership::permission::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority, PermissionSet};

    // Error codes
    const ENO_ADMIN_AUTHORITY: u64 = 0;
    const EINSUFFICIENT_AUTHORITY_FOR_AGENT: u64 = 1;
    const EINVALID_DELEGATION: u64 = 2;
    const EPERMISSION_NOT_FOUND: u64 = 3;

    // Root-level, shared object. The owner is the principle, and is immutable (non-transferable).
    // This serves a purpose similar to RBAC, in that it stores permissions
    struct DelegationStore has key {
        id: UID,
        principal: address
    }

    // Stores  `PermissionSet` inside of DelegationStore
    struct Key has store, copy, drop { agent: address } 

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

    // ======= Add Agent Permissions =======

    public fun add_permission<Permission>(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        assert!(!permissions::is_admin_permission<Permission>() &&
            !permissions::is_manager_permission<Permission>(), EINVALID_DELEGATION);

        let general = permission_set::general(permission_set_mut(store, agent));
        vector2::push_back_unique(general, permissions::new<Permission>());
    }

    public fun add_permission_for_type<ObjectType, Permission>(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {
        let types = vector[struct_tag::get<ObjectType>()];
        add_permission_for_types<Permission>(store, agent, types, auth);
    }

    // Using struct-tag allows for us to match entire classes of types; adding an abstract type without
    // its generics will match all concrete-types that implement it. Missing generics are treated as *
    // wildcard when type-matching.
    //
    // Example: StructTag { address: 0x2, module_name: coin, struct_name: Coin, generics: [] } will match
    // all Coin<*> types. Effectively, this grants the permission over all Coin types. If you don't want
    // this behavior, simply specify the generics, like Coin<SUI>.
    public fun add_permission_for_types<Permission>(
        store: &mut DelegationStore,
        agent: address,
        types: vector<StructTag>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);

        let permission = permissions::new<Permission>();
        let types_map = permission_set::types(permission_set_mut(store, agent));

        while (vector::length(&types) > 0) {
            let type = vector::pop_back(&mut types, i);
            let type_permissions = vec_map::borrow_mut_fill(types_map, type, vector[]);
            vector2::push_back_unique(&mut type_permissions, permission);
        };
    }

    public fun add_permission_for_objects<Permission>(
        store: &mut DelegationStore,
        agent: address,
        objects: vector<ID>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);

        let permission = permissions::new<Permission>();
        let objects_map = permission_set::objects(permission_set_mut(store, agent));

        while (vector::length(&objects) > 0) {
            let object_id = vector::pop_back(&mut objects, i);
            let object_permissions = vec_map::borrow_mut_fill(objects_map, object_id, vector[]);
            vector2::push_back_unique(&mut object_permissions, permission);
        };
    }

    // ======= Remove Agent Permissions =======

    public fun remove_general_permission_from_agent<Permission>(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let general = permission_set::general(permission_set_mut(store, agent));
        vector2::remove_maybe(general, permission::new<Permission>());
    }

    public fun remove_all_general_permissions_from_agent(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let general = permission_set::general(permission_set_mut(store, agent));
        
        while(!vector::is_empty(general)) {
            vector::pop_back(general)
        }
    }

    public fun remove_permission_for_type_from_agent<ObjectType, Permission>(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let types_map = permission_set::types(permission_set_mut(store, agent));

        let type_key = struct_tag::get<ObjectType>();
        let permissions_maybe = vec_map2::get_maybe(types_map, &type_key);

        if(option::is_some(&permissions_maybe)) {
            let permissions = option::destroy_some(permissions_maybe);
            vector2::remove_maybe(permissions, permission::new<Permission>());
        }
    }

    public fun remove_permission_for_types_from_agent<Permission>(
        store: &mut DelegationStore,
        agent: address,
        types: vector<StructTag>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let types_map = permission_set::types(permission_set_mut(store, agent));

        while(vector::is_empty(&types)) {
            let type_key = vector::pop_back(&mut types);
            let permissions_maybe = vec_map2::get_maybe(types_map, &type_key);

            if(option::is_some(&permissions_maybe)) {
                let permissions = option::destroy_some(permissions_maybe);
                vector2::remove_maybe(permissions, permission::new<Permission>());
            }
        }
    }

    public fun remove_type_from_agent<ObjectType>(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority
    ) {
       assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let types_map = permission_set::types(permission_set_mut(store, agent));
        let type_key = struct_tag::get<ObjectType>();

        vec_map2::remove_maybe(types_map, &type_key);
    }

    public fun remove_types_from_agent(
        store: &mut DelegationStore,
        agent: address,
        types: vector<StructTag>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let types_map = permission_set::types(permission_set_mut(store, agent));

        while(vector::is_empty(&types)) {
            let type_key = vector::pop_back(&mut types);
            vec_map2::remove_maybe(types_map, &type_key)
        }
    }

    public fun remove_permission_for_objects_from_agent<Permission>(
        store: &mut DelegationStore,
        agent: address,
        objects: vector<ID>,
        auth: &TxAuthority,
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let objects_map = permission_set::objects(permission_set_mut(store, agent));

        while(vector::is_empty(&objects)) {
            let object_key = vector::pop_back(&mut objects);
            let permissions_maybe = vec_map2::get_maybe(objects_map, &object_key);

            if(option::is_some(&permissions_maybe)) {
                let permissions = option::destroy_some(permissions_maybe);
                vector2::remove_maybe(permissions, permission::new<Permission>());
            }
        }
    }

    public fun remove_objects_from_agent(
        store: &mut DelegationStore,
        agent: address,
        objects: vector<ID>,
        auth: &TxAuthority,
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        let objects_map = permission_set::objects(permission_set_mut(store, agent));

        while(vector::is_empty(&objects)) {
            let object_key = vector::pop_back(&mut objects);
            vec_map2::remove_maybe(objects_map, &object_key)
        }
    }

    public fun remove_agent(
        store: &mut DelegationStore,
        agent: address,
        auth: &TxAuthority,
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_ADMIN_AUTHORITY);
        dynamic_field2::drop_(&mut store.id, agent);
    }

    // ======= For Agents =======

    public fun claim_delegation(store: &DelegationStore, ctx: &TxContext): TxAuthority {
        let for = tx_context::sender(ctx);
        let auth = tx_authority::begin(ctx);
        claim_delegation_(store, for, &auth)
    }

    // By asserting ADMIN we prevent permission-chaining, which simplifies things
    public fun claim_delegation_(store: &DelegationStore, for: address, auth: &TxAuthority): TxAuthority {
        assert!(tx_authority::has_permission<ADMIN>(for, auth), EINSUFFICIENT_AUTHORITY_FOR_AGENT);

        let set = permission_set_value(store, for);
        tx_authority::merge_permission_set_internal(store.principal, set, auth)
    }

    // ======= Internal Helper Functions =======

    fun permission_set_mut(store: &mut DelegationStore, agent: address): &mut PermissionSet {
        let fallback = tx_authority::new_permission_set_empty();
        dynamic_field2::borrow_mut_fill(&mut store.id, agent, fallback)
    }

    fun permission_set_value(store: &DelegationStore, for: address): PermissionSet {
        let set_maybe = dynamic_field2::get_maybe(&store.id, agent);
        if (option::is_none(&set_maybe)) {
            tx_authority::new_permission_set_empty()
        } else {
            option::destroy_some(set_maybe)
        }
    }

    // ======= Getters =======

    // ======= Extend Pattern =======

    // ======= Convenience Entry Functions =======
    // TO DO: provide entry functions for all public API functions

}