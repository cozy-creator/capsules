// These are authority-checks for server endpoints. Modules should use these for access-control.
// Server-authority is stored within Organization objects that control entire packages. They feature
// a sophisticated RBAC system that allows for fine-grained control of server actions by an
// administrator.

// This validity-checks should be used by modules to assert the correct actions are present.

module ownership::server {
    use std::option::{Self, Option};

    use sui::object::{ID};
    use sui::tx_context::TxContext;

    use ownership::organization::{Self, Organization};
    use ownership::tx_authority::{Self, TxAuthority};

    // Convenience function
    public fun assert_login<Action>(organization: &Organization, ctx: &TxContext): TxAuthority {
        let auth = tx_authority::begin(ctx);
        assert_login_<Action>(organization, &auth)
    }

    // Log the agent into the organization, and assert that they have the specified action
    public fun assert_login_<Action>(organization: &Organization, auth: &TxAuthority): TxAuthority {
        organization::assert_login_<Action>(organization, auth)
    }

    // Eliminates the need to specify `T` because the package is assumed to be from `Action`
    public fun can_act_as_own_package<Action>(auth: &TxAuthority): bool {
        tx_authority::can_act_as_package<Action, Action>(auth)
    }

    // `T` is any type from the package whose action we're checking for
    public fun can_act_as_package<T, Action>(auth: &TxAuthority): bool {
        tx_authority::can_act_as_package<T, Action>(auth)
    }

    public fun can_act_as_package_<Action>(package: ID, auth: &TxAuthority): bool {
        tx_authority::can_act_as_package_<Action>(package, auth)
    }

    // `T` is any type from the package whose action we're checking for
    public fun can_act_as_package_excluding_manager<T, Action>(auth: &TxAuthority): bool {
        can_act_as_package_excluding_manager<T, Action>(auth)
    }

    // Defaults to `true` if package is unspecified
    public fun can_act_as_package_opt<Action>(package: Option<ID>, auth: &TxAuthority): bool {
        if (option::is_none(&package)) { return true };
        tx_authority::can_act_as_package_<Action>(option::destroy_some(package), auth)
    }
}