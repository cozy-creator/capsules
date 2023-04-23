module composable_game::multi_signer_transactions {
    // Sui does not currently support multi-party transactions, so we cannot do this atomically in a single
    // atomic transaction; we can use single-use permissions to get around this limitation however.
    // Step-1: ToNamespace must add a role with SINGLE_USE + ADD_PACKAGE as permissions; assign this role to one of its agents.
    // Step 2: That agent must call into namespace::issue_single_use_permission<ADD_PACKAGE>(), and transfer it to one of FromNamespace's agents. This will give that agent the ability to add (ToNamespace, ADD_PACKAGE) to its permissions.
    // Step 3: FromNamespace must add a role with REMOVE_PACKAGE and assign that role to this agent.
    // Step 4: This agent must consume its stored single-use-permission, and call into its namespace to retrieve its role (as usual). It may then call namespace::transfer_package() specifying the package-id to transfer.
    //
    // It is possible to do this in reverse, i.e., the FromNamespace issues a permission to ToNamespace, and ToNamespace does the final transaction, HOWEVER this is dangerous! That's because the single use permission does not specify WHICH package is changing hands; essentially ToNamespace will be able to pick any package they want and take that. Note that this also true in our preferred method; however, ToNamespace receiving a package it was not expecting does no harm because its control is expanding rather than shrinking.
    //
    // Note that if there is an admin that controls both namespaces, this is a lot more trivial of an operation.
    public fun transfer_package<FromNamespace, ToNamespace>(
        from: &mut Namespace,
        to: &mut Namespace,
        package_id: ID,
        auth: &TxAuthority
    ) {
        assert!(namespace::has_permission_excluding_manager<FromNamespace, REMOVE_PACKAGE>(auth), ENO_NAMESPACE_PERMISSION);
        assert!(namespace::has_permission_<ToNamespace, ADD_PACKAGE>(auth), ENO_NAMESPACE_PERMISSION);

        let package = vector::remove(&mut from.packages, package_id);
        vector::push_back(&mut to.packages, package);
    }
}