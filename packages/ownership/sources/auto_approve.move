// This could also be called 'delegate'.
// Let's supose we have Capsule, whose Owner is 0x59. He can add an auto-approval;
// this is a pair of <address, access control list>. This means that any transaction coming
// from the specified address will be treated _as if it were signed by the owner himself_
// for the access specified in the access control list.
//
// The access-control list allows you to grant partial-permission to an address, without
// giving it full control over your object.

module ownership::auto_aprove {
    use std::string::{String, utf8};
    use std::vector;
    use sui::dynamic_field;
    use sui::object::UID;
    use sui::tx_context::TXContext;
    use sui_utils::map::{Self, Map};
    use ownership::tx_authority::TxAuthority;
    use ownership::ownership;

    // Error structs
    const ENOT_OWNER: u64 = 0;
    const EROLE_NUMBER_TOO_LARGE: u64 = 1;

    struct Key has store, copy, drop { } // Map<address, u16>

    // "roles" is the role-indexes that should be flipped to 1 for this address
    public fun grant(uid: &mut UID, addr: address, roles: vector<String>, auth: &TxAuthority, ctx: &mut TxContext) {
        assert!(ownership::is_valid_owner(uid, auth), ENOT_OWNER);

        if (!dynamic_field::exists_(uid, Key {})) {
            dynamic_field::add(uid, Key {}, map::empty<addres, u16>(ctx));
        };
        let map = dynamic_field::borrow_mut<Key, Map<address, u16>>(uid, Key {})

        if (!map::exists_(map, addr)) { map::add(map, addr, 0u16); };

        let (acl, i) = (map::borrow_mut(map, addr), 0);
        while (i < vector::length(&roles)) {
            let role = get_role_index(*vector::borrow(&roles, i));
            if (role < 16) { add_role(&mut acl, role); };
            i = i + 1;
        };
    }

    public fun revoke(uid: &mut UID, addr: address, roles: vector<String>, auth: &TxAuthority) {
        assert!(ownership::is_valid_owner(uid, auth), ENOT_OWNER);

        if (!dynamic_field::exists_(uid, Key {})) { return };
        let map = dynamic_field::borrow_mut<Key, Map<address, u16>>(uid, Key {});

        if (!map::exists_(map, addr)) { return };

        let (acl, i) = (map::borrow_mut(map, addr), 0);
        while (i < vector::length(&roles)) {
            let role = get_role_index(*vector::borrow(&roles, i));
            if (role < 16) { remove_role(&mut acl, role); };
            i = i + 1;
        };
    }

    public fun revoke_address(uid: &mut UID, addr: address, auth: &TxAuthority) {
        assert!(ownership::is_valid_owner(uid, auth), ENOT_OWNER);

        if (!dynamic_field::exists_(uid, Key {})) { return };
        let map = dynamic_field::borrow_mut<Key, Map<address, u16>>(uid, Key {});

        if (!map::exists_(map, addr)) { return };

        map::remove(map, addr);
    }

    public fun revoke_all(uid: &mut UID, auth: &TxAuthority) {
        assert!(ownership::is_valid_owner(uid, auth), ENOT_OWNER);

        if (!dynamic_field::exists_(uid, Key {})) { return };
        let map = dynamic_field::remove<Key, Map<address, u16>>(uid, Key {});
        map::delete(map);
    }

    // ============ Validity Checkers ============

    public fun has_role(id: &UID, addr: address, role: u8): bool {
        if (role >= 16) { return false };

        if (!dynamic_field::exists_(uid, Key {})) { return false };
        let map = dynamic_field::borrow_mut<Key, Map<address, u16>>(uid, Key {});

        if (!map::exists_(map, addr)) { return false };

        *map::borrow(map, addr) & (1 << role) > 0
    }

    // ============ ACL Functions ============

    // We use a u16 as an access control list. We treat each bit as a role (or lack thereof)
    // These are the corresponding indexes for each role.
    const OPEN: u8 = 0; // can open capsules
    const EXTEND: u8 = 1; // can extend capsules
    const METADATA: u8 = 2; // can approve the proposed edit of metadata
    const DATA: u8 = 3; // can edit data
    const INVENTORY: u8 = 4; // can edit inventory

    // Move doesn't yet support enums, so we'll use Strings for now instead
    public fun get_role_index(role_name: String): u8 {
        if (role_name == utf8(b"OPEN")) { OPEN }
        else if (role_name == utf8(b"EXTEND")) { EXTEND }
        else if (role_name == utf8(b"METADATA")) { METADATA }
        else if (role_name == utf8(b"DATA")) { DATA }
        else if (role_name == utf8(b"INVENTORY")) { INVENTORY }
        else { 255 } // Error, role not found == 255
    }

    public fun add_role(acl: &mut u16, role: u8) {
        assert!(role < 16, EROLE_NUMBER_TOO_LARGE);

        *acl = *acl | (1 << role);
    }

    public fun remove_role(acl: &mut u16, role: u8) {
        assert!(role < 16, EROLE_NUMBER_TOO_LARGE);

        *acl = *acl - (1 << role);
    }
}