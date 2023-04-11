module sui_utils::access_control_list {
    // error enums
    const EROLE_NUMBER_TOO_LARGE: u64 = 0;

    public fun add_role(acl: &mut u16, role: u8) {
        assert!(role < 16, EROLE_NUMBER_TOO_LARGE);

        *acl = *acl | (1 << role);
    }

    public fun remove_role(acl: &mut u16, role: u8) {
        assert!(role < 16, EROLE_NUMBER_TOO_LARGE);

        *acl = *acl - (1 << role);
    }

    public fun has_role(acl: &u16, role: u8): bool {
        if (role >= 16) { return false };

        *acl & (1 << role) > 0
    }

    public fun or_merge(acl: &mut u16, other: &u16) {
        *acl = *acl | *other;
    }

    public fun and_merge(acl: &mut u16, other: &u16) {
        *acl = *acl & *other;
    }
}