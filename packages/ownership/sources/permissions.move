// Sui's permission system, used to delegate authority from a principal to an agent
//
// I wish that permissions could be typed, like Permission<T>, but that would make them hard
// to store, as vectors do not support heterogenous types. sui::Bag / sui::Table would work,
// but they're not droppable, so they'd have to explicitly be destroyed at the end of every tx.

module ownership::permissions {
    use std::string::{String, utf8};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    use sui_utils::encode;

    friend ownership::rbac;
    friend ownership::tx_authority;
    friend ownership::namespace;

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

    struct SingleUsePermission has key, store {
        id: UID,
        principal: address,
        permission: Permission
    }

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

        if (has_admin_permission(permissions) || has_manager_permissions(permissions)) { 
            return *filter
        };

        vector2::intersection(permissions, filter)
    }

    public(friend) fun add(existing: &mut vector<Permission>, new: vector<Permission>) {
        let (admin, manager) = (admin(), manager());

        // This prevents accidental permission downgrades
        if (has_admin_permission(existing)) { return };

        // These superseed and replace all existing permissions
        if (vector::contains(&new, admin)) {
            *existing = vector[admin];
            return;
        };
        if (vector::contains(&new, manager)) { 
            *existing = vector[manager];
            return
        };

        vector2::merge(existing, new);
    }

    // This works because ADMIN replaces all other permissions in this array
    public fun has_admin_permission(permissions: &vector<Permission>): bool {
        if (vector::length(permissions) > 0) {
            let permission = vector::borrow(&permissions, 0);
            is_admin_permission(permission)
        } else {
            false
        }
    }

    public fun is_admin_permission(permission: &Permission): bool {
        permission.inner == encode::type_name<ADMIN>()
    }

    // This works because MANAGER replaces all other permissions in this array
    public fun has_manager_permission(permissions: &vector<Permission>): bool {
        if (vector::length(permissions) > 0) {
            let permission = vector::borrow(&permissions, 0);
            is_manager_permission(permission)
        } else {
            false
        }
    }

    public fun is_manager_permission(permission: &Permission): bool {
        permission.inner == encode::type_name<MANAGER>()
    }

    public fun has_permission<Permission>(permissions: &vector<Permission>): bool {
        if (has_admin_permission(permissions) || has_manager_permission(permissions)) {
            return true
        };

        let type_name = encode::type_name<Permission>();
        let i = 0;
        while (i < vector::length(&permissions)) {
            let permission = vector::borrow(&permissions, i);
            if (&permission.inner == &type_name) {  return true };
            i = i + 1;
        };

        false
    }

    public fun has_permission_excluding_manager<Permission>(permissions: &vector<Permission>): bool {
        if (has_manager_permission(permissions)) { return false };
        has_permission<Permission>(permissions)
    }

    // =========== Single-use permissions ===========
    // Created by ownership::namespace, destroyed by ownership::tx_authority to be added to TxAuthority
    // These make up for the fact that Sui cannot do multi-party transactions; we can split one-party's
    // half of the transaction into a single-use permission, and then have the second party complete it

    public(friend) fun create_single_use<Permission>(
        principal: address,
        ctx: &mut TxContext
    ): SingleUsePermission {
        SingleUsePermission {
            id: object::new(ctx),
            principal,
            permission: new<Permission>()
        }
    }

    public(friend) fun consume_single_use(permission: SingleUsePermission): (principal, Permission) {
        let SingleUsePermission { id, principal, permission } = permission;
        object::delete(id);
        (principal, permission)
    }

    public fun destroy_single_use(permission: SingleUsePermission) {
        let SingleUsePermission { id, principal: _, permission: _ } = permission;
        object::delete(id);
    }
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