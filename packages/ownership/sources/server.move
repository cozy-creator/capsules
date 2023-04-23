// These are authority-checks for server endpoints. Modules should use these for access-control.
// Server-authority is stored within Namespace objects that control entire packages. They feature
// a sophisticated RBAC system that allows for fine-grained control of server permissions by an
// administrator.

module ownership::server {
    // ======== Validity Checkers ========
    // This should be used by modules to assert the correct permissions are present

    // Convenience function
    public fun assert_login<Permission>(namespace: &Namespace, ctx: TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);
        assert_login_<Permission>(namespace, &auth)
    }

    // Log the agent into the namespace, and assert that they have the specified permission
    public fun assert_login_<Permission>(namespace: &Namespace, auth: &TxAuthority): TxAuthority {
        let auth = claim_permissions_(namespace, auth);
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

    public fun has_permission_excluding_manager<NamespaceType, Permission>(auth: &TxAuthority): bool {
        let principal_maybe = tx_authority::lookup_namespace_for_package<NamespaceType>(auth);
        if (option::is_none(&principal_maybe)) { return false };
        let principal = option::destroy_some(principal_maybe);

        tx_authority::has_permission_excluding_manager<Permission>(principal, auth)
    }
}