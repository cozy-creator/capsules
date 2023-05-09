// These are authority-checks for server endpoints. Modules should use these for access-control.
// Server-authority is stored within Namespace objects that control entire packages. They feature
// a sophisticated RBAC system that allows for fine-grained control of server permissions by an
// administrator.

// This validity-checks should be used by modules to assert the correct permissions are present.

module authorization::server {

    use ownership::tx_authority::{Self, TxAuthority};

    use namespace::rbac;
    use namespace::namespace::{Self, Namespace};

    // Convenience function
    public fun assert_login<Permission>(namespace: &Namespace, ctx: TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);
        assert_login_<Permission>(namespace, &auth)
    }

    // Log the agent into the namespace, and assert that they have the specified permission
    public fun assert_login_<Permission>(namespace: &Namespace, auth: &TxAuthority): TxAuthority {
        namespace::assert_login_<Permission>(namespace, auth)
    }

    // public fun has_namespace_admin_permission<NamespaceType>(auth: &TxAuthority): bool {
    //     tx_authority::has_namespace_admin_permission<NamespaceType>(auth)
    // }

    // Convenience function. Permission and Namespace are the same module, so this is checking if
    // the same module authorized this operation as the module that declared this permission type.
    public fun has_namespace_permission<Permission>(auth: &TxAuthority): bool {
        has_namespace_permission_<Permission, Permission>(auth)
    }

    // `NamespaceType` can be literally any type declared in any package belonging to that Namespace;
    // we merely use this type to figure out the package-id, so that we can lookup the Namespace that
    // owns that type (assuming it has been added to TxAuthority already).
    // In this case, Namespace is the principal.
    public fun has_namespace_permission_<NamespaceType, Permission>(auth: &TxAuthority): bool {
        tx_authority::has_namespace_permission<NamespaceType, Permission>(auth)
    }

    // This is best used for sensitive operations, where you want the agent to either explicitly have
    // the permission, or be an admin. We do not want to automatically grant this permission by default
    // by being a manager.
    public fun has_namespace_permission_excluding_manager<NamespaceType, Permission>(auth: &TxAuthority): bool {
        tx_authority::has_namespace_permission_excluding_manager<NamespaceType, Permission>(auth)
    }
}