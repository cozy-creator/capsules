// Sui's permission system, used to delegate authority from a principal to an agent
//
// I wish that permissions could be typed, like Permission<T>, but that would make them hard
// to store, as vectors do not support heterogenous types. sui::Bag / sui::Table would work,
// but they're not droppable, so they'd have to explicitly be destroyed at the end of every tx.

module ownership::permissions {
    use sui::object::{Self, UID};

    friend ownership::rbac;
    friend ownership::tx_authority;
    friend ownership::namespace;

    // These are reserved role names. If the principal gives an agent the ALL role, then they can act as that
    // agent for all permission-types (there is no scope), except for admin.
    // With the ADMIN role, a delegate is indistinguishable from the principal.
    // Granting the ADMIN role is potentially dangerous, as the agent can then grant _other_ agents
    // the rights of the principal as well, ad inifintum. If this occurs, it could be virtually impossible
    // to revoke the rights of the agent and make the principal secure again.
    const ADMIN: vector<u8> = b"ADMIN";
    const ALL: vector<u8> = b"ALL";

    // Can be stored, but not copied. Used as a template to produce Permission structs
    // Anyone who can obtain a reference to this can use it; store it somewhere private
    // struct StoredPermission has store, drop {
    //     inner: String
    // }

    // This has `store` which could be dangerous? We need to keep all refs these private
    struct Permission has store, copy, drop {
        inner: String
    }

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

    public(friend) fun admin(): Permission {
        Permission { inner: utf8(ADMIN) }
    }

    public(friend) fun all(): Permission {
        Permission { inner: utf8(ALL) }
    }

    public(friend) fun add(existing: &mut vector<Permission>, new: vector<Permission>) {
        if (has_admin_permission(existing)) { return };
        if (new.inner != utf8(ADMIN) && has_all_permission(existing)) { return };

        vector2::merge(existing, new);
    }

    // This works, because ADMIN replaces all other permissions in this array
    public fun has_admin_permission(permissions: &vector<Permission>): bool {
        if (vector::length(permissions) > 0) {
            let permission = vector::borrow(&permissions, 0);
            permission.inner == utf8(ADMIN)
        } else {
            false
        }
    }

    // This works, because ALL replaces all other permissions in this array
    public fun has_all_permission(permissions: &vector<Permission>): bool {
        if (vector::length(permissions) > 0) {
            let permission = vector::borrow(&permissions, 0);
            permission.inner == utf8(ALL)
        } else {
            false
        }
    }

    public fun has_permission<Permission>(permissions: &vector<Permission>): bool {
        if (has_admin_permission(permissions) || has_all_permission(permissions)) {
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


}