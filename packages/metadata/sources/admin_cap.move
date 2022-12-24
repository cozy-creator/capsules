// AdminCaps are subbordinate to BossCaps. Access can be granted or revoked by the BossCap.
// AdminCaps are used to (1) edit object-metadata, (2) edit object-data, and (3) edit object-inventories
// on behalf of a world. They are a method for BossCaps to delegate control to other accounts, either
// humans or machines (such as a game server).
// AdminCaps are scoped to package IDs

module metadata::admin_cap {
    use metadata::boss_cap;

    const ENO_AUTHORITY_OVER_PACKAGE: u64 = 0;
    const ENOT_ADMIN_ADDRESS: u64 = 1;

    // This object is shared so that the boss-cap can revoke access
    struct AdminAccess has key {
        id: UID,
        package: ID,
        // <address> : bool <- stores addresses authorized to access the AdminCap
    }

    public entry fun create(boss_cap: &BossCap, package: ID, admins: vector<address>, ctx: &mut TxContext) {
        assert!(boss_cap::is_valid(boss_cap, package), ENO_AUTHORITY_OVER_PACKAGE);

        let access = AdminAccess {
            id: object::new(ctx),
            package
        };

        add_admins(boss_cap, &mut access, admins);
        transfer::share_object(access);
    }

    public entry fun add_admins(boss_cap: &BossCap, access: &mut AdminAccess, admins: vector<address>) {
        assert!(boss_cap::is_valid(boss_cap, &access.package), ENO_AUTHORITY_OVER_PACKAGE);

        let i = 0;
        while (i < vector::length(&admins)) {
            let addr = *vector::borrow(&admins, i);

            if (!dynamic_field::exists_(&access.id, addr)) {
                dynamic_field::add(&mut access.id, addr, true);
            };

            i = i + 1;
        };
    }

    public entry fun remove_admins(boss_cap: &BossCap, access: &mut AdminAccess, admins: vector<address>) {
        assert!(boss_cap::is_valid(boss_cap, &access.package), ENO_AUTHORITY_OVER_PACKAGE);

        let i = 0;
        while (i < vector::length(&admins)) {
            let addr = *vector::borrow(&admins, i);

            if (dynamic_field::exists_(&access.id, addr)) {
                dynamic_field::remove<address, bool>(&mut access.id, addr);
            };

            i = i + 1;
        };
    }

    public fun is_valid(access: &AdminAccess, package: ID, addr: address): bool {
        if (*access.package != package) { return false; };

        dynamic_field::exists_with_type<address, bool>(&access.id, addr)
    }
}