// These are authority-checks for server endpoints. Modules should use these for access-control.
// Server-authority is stored within Organization objects that control entire packages. They feature
// a sophisticated RBAC system that allows for fine-grained control of server permissions by an
// administrator.

// This validity-checks should be used by modules to assert the correct permissions are present.

module ownership::server {
    use sui::tx_context::TxContext;

    use ownership::organization::{Self, Organization};
    use ownership::tx_authority::{Self, TxAuthority};

    // Convenience function
    public fun assert_login<Permission>(organization: &Organization, ctx: &TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);
        assert_login_<Permission>(organization, &auth)
    }

    // Log the agent into the organization, and assert that they have the specified permission
    public fun assert_login_<Permission>(organization: &Organization, auth: &TxAuthority): TxAuthority {
        organization::assert_login_<Permission>(organization, auth)
    }

    // Convenience function.
    public fun has_org_permission<Permission>(auth: &TxAuthority): bool {
        tx_authority::has_org_permission_<Permission, Permission>(auth)
    }

    public fun has_org_permission_<OrganizationType, Permission>(auth: &TxAuthority): bool {
        tx_authority::has_org_permission_<OrganizationType, Permission>(auth)
    }

    public fun has_org_permission_excluding_manager<OrganizationType, Permission>(auth: &TxAuthority): bool {
        tx_authority::has_org_permission_excluding_manager<OrganizationType, Permission>(auth)
    }

    public fun has_package_permission_opt<Permission>(
        package: Option<ID>,
        auth: &TxAuthority
    ): bool {
        if (option::is_none(package)) { return true; };
        tx_authority::has_package_permission_<Permission>(package, auth)
    }

    public fun has_package_permission<Permission>(
        package: ID,
        auth: &TxAuthority
    ): bool {
        tx_authority::has_package_permission_<Permission>(package, auth)
    }
}