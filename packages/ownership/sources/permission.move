// Sui's permission system, used to delegate authority from a principal to an agent
//
// I wish that permissions could be typed, like Permission<T>, but that would make them hard
// to store, as vectors do not support heterogenous types. sui::Bag / sui::Table would work,
// but they're not droppable, so they'd have to explicitly be destroyed at the end of every tx.

module ownership::permission {
    use std::option;
    use std::string::String;
    use std::vector;

    // use sui::object::{Self, UID};
    // use sui::tx_context::TxContext;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::encode;
    use sui_utils::vector2;
    use sui_utils::vec_map2;

    friend ownership::delegation;
    friend ownership::organization;
    friend ownership::permission_set;
    friend ownership::rbac;
    friend ownership::tx_authority;

    // These are special system-level permissions.
    // If the principal gives an agent the MANAGER role, then they can act as
    // that agent for all permission-types (there is no scope), except for admin.
    // With the ADMIN role, an agent is indistinguishable from the delegating principal.
    // Granting the ADMIN role is potentially dangerous, as the agent can then grant _other_ agents
    // the rights of the principal as well, ad inifintum. If this occurs, it could be virtually impossible
    // to revoke the rights of the agent and make the principal secure again.
    struct ADMIN {}
    struct MANAGER {}

    // This has `store` + `copy` which could be dangerous? We need to keep all refs these private
    struct Permission has store, copy, drop {
        inner: String
    }

    // struct SingleUsePermission has key, store {
    //     id: UID,
    //     principal: address,
    //     permission: Permission
    // }

    public(friend) fun admin(): Permission {
        Permission { inner: encode::type_name<ADMIN>() }
    }

    public(friend) fun manager(): Permission {
        Permission { inner: encode::type_name<MANAGER>() }
    }

    public(friend) fun new<P>(): Permission {
        Permission { inner: encode::type_name<P>() }
    }
    
    // Delegations only extend an agent's power to equal or lower levels, never up.
    //
    // Example: Alice delegates [CREATE] to Bob--this means Bob can call in and perform a CREATE operation
    // as if he were Alice. Bob now delegates [CREATE, DELETE] to Charlie. This means Charlie can now call
    // in and do both CREATE and DELETE as Bob, and by inheritance, can also do CREATE as Alice as well.
    // However, Charlie cannot perform DELETE or any other action as Alice.
    //
    // That is, everything in `permissions` that is outside of the `filter` will be removed
    public(friend) fun intersection(permissions: &vector<Permission>, filter: &vector<Permission>): vector<Permission> {
        if (has_admin_permission(filter)) { return *permissions };

        if (has_manager_permission(filter)) {
            if (has_admin_permission(permissions)) { return vector[manager()] }; // Downgrade to manager
            return *permissions
        };

        if (has_admin_permission(permissions) || has_manager_permission(permissions)) { 
            return *filter
        };

        vector2::intersection(permissions, filter)
    }

    public(friend) fun vec_map_intersection<T: copy + drop>(
        self: &VecMap<T, vector<Permission>>, 
        general_filter: &vector<Permission>,
        specific_filter: &VecMap<T, vector<Permission>>
    ): VecMap<T, vector<Permission>> {
        let i = 0;
        let filtered = vec_map::empty<T, vector<Permission>>();
        while (i < vec_map::size(self)) {
            let (key, value) = vec_map::get_entry_by_idx(self, i);

            let specific_filter_maybe = vec_map::try_get(specific_filter, key);
            let filtered_value = if (option::is_some(&specific_filter_maybe)) {
                let this_specific_filter = option::destroy_some(specific_filter_maybe);
                let this_filter = add_(general_filter, this_specific_filter);
                intersection(value, &this_filter)
            } else {
                intersection(value, general_filter)
            };

            vec_map::insert(&mut filtered, *key, filtered_value);

            i = i + 1;
        };

        filtered
    }

    public(friend) fun add(existing: &mut vector<Permission>, new: vector<Permission>) {
        let (admin, manager) = (admin(), manager());

        // This prevents accidental permission downgrades
        if (has_admin_permission(existing)) { return };

        // These superseed and replace all existing permissions
        if (vector::contains(&new, &admin)) {
            *existing = vector[admin];
            return
        };
        if (vector::contains(&new, &manager)) { 
            *existing = vector[manager];
            return
        };

        vector2::merge(existing, new);
    }

    // Doesn't modify the existing vectors
    public(friend) fun add_(existing: &vector<Permission>, new: vector<Permission>): vector<Permission> {
        let (admin, manager) = (admin(), manager());

        // This prevents accidental permission downgrades
        if (has_admin_permission(existing)) { return *existing };

        // These superseed and replace all existing permissions
        if (vector::contains(&new, &admin)) {
            return vector[admin]
        };
        if (vector::contains(&new, &manager)) { 
            return vector[manager]
        };

        vector2::merge_(existing, &new)
    }

    public(friend) fun vec_map_add<K: copy + drop>(
        existing: &mut VecMap<K, vector<Permission>>,
        new: VecMap<K, vector<Permission>>
    ) {
        while (vec_map::size(&new) > 0) {
            let (key, value) = vec_map::pop(&mut new);
            let self = vec_map2::borrow_mut_fill(existing, &key, vector[]);
            add(self, value);
       };
    }

    public fun has_admin_permission(permissions: &vector<Permission>): bool {
        vector::contains(permissions, &admin())
    }

    public fun is_admin_permission<Permission>(): bool {
        encode::type_name<Permission>() == encode::type_name<ADMIN>()
    }

    public fun is_admin_permission_(permission: &Permission): bool {
        permission.inner == encode::type_name<ADMIN>()
    }

    public fun has_manager_permission(permissions: &vector<Permission>): bool {
        vector::contains(permissions, &manager())
    }

    public fun is_manager_permission<Permission>(): bool {
        encode::type_name<Permission>() == encode::type_name<MANAGER>()
    }

    public fun is_manager_permission_(permission: &Permission): bool {
        permission.inner == encode::type_name<MANAGER>()
    }

    public fun has_permission<P>(permissions: &vector<Permission>): bool {
        if (has_admin_permission(permissions) || has_manager_permission(permissions)) {
            return true
        };

        let type_name = encode::type_name<P>();
        let i = 0;
        while (i < vector::length(permissions)) {
            let permission = vector::borrow(permissions, i);
            if (permission.inner == type_name) {  return true };
            i = i + 1;
        };

        false
    }

    public fun has_permission_excluding_manager<P>(permissions: &vector<Permission>): bool {
        if (has_manager_permission(permissions)) { return false };
        has_permission<P>(permissions)
    }

    #[test_only]
    public fun new_for_testing<P>(): Permission {
        new<P>()
    }

    // =========== Single-use permissions ===========
    // Created by ownership::organization, destroyed by ownership::tx_authority to be added to TxAuthority
    // These make up for the fact that Sui cannot do multi-party transactions; we can split one-party's
    // half of the transaction into a single-use permission, and then have the second party complete it

    // public(friend) fun create_single_use<P>(
    //     principal: address,
    //     ctx: &mut TxContext
    // ): SingleUsePermission {
    //     SingleUsePermission {
    //         id: object::new(ctx),
    //         principal,
    //         permission: new<P>()
    //     }
    // }

    // public(friend) fun consume_single_use(permission: SingleUsePermission): (address, Permission) {
    //     let SingleUsePermission { id, principal, permission } = permission;
    //     object::delete(id);
    //     (principal, permission)
    // }

    // public fun destroy_single_use(permission: SingleUsePermission) {
    //     let SingleUsePermission { id, principal: _, permission: _ } = permission;
    //     object::delete(id);
    // }
}

    // Can be stored, but not copied. Used as a template to produce Permission structs
    // Anyone who can obtain a reference to this can use it; store it somewhere private
    // struct StoredPermission has store, drop {
    //     inner: String
    // }

    // Turns persistent (Stored) permissions into ephemeral permissions. Ephemeral permissions are always
    // dropped at the end of a transaction.
    // public(friend) fun clone(stored: &vector<StoredPermission>): vector<Permission> {
    //     let i = 0;
    //     let permissions = vector::empty<Permission>();
    //     while (i < vector::length(&stored)) {
    //         let inner = vector::borrow(&stored, i).inner;
    //         vector::push_back(&mut permissions, Permission { inner });
    //         i = i + 1;
    //     };
    // }