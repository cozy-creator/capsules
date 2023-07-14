// This is a MCM (Market Confounding Mechanism) employed by royalty markets to prevent
// unathorized reselling.
// Note that there is no 'reclaim' function here; that must be implemented individually
// by any module that uses this.

module transfer_system::reclaimer {
    use sui::object::UID;

    use ownership::ownership;
    use ownership::tx_authority::{TxAuthority};
    use ownership::permission::ADMIN;

    // error constants
    const ENO_TRANSFER_AUTHORITY: u64 = 0;

    public fun add_claim(uid: &mut UID, _sender: address, _claim: vector<u8>, auth: &TxAuthority) {
        assert!(ownership::has_transfer_permission<ADMIN>(uid, auth), ENO_TRANSFER_AUTHORITY);
    }

    public fun remove_claims(uid: &mut UID, auth: &TxAuthority) {
        assert!(ownership::has_transfer_permission<ADMIN>(uid, auth), ENO_TRANSFER_AUTHORITY);
    }

    // ====== Validity Checkers ======

    public fun is_valid_claim(_sender: address, _claim: vector<u8>): bool {
        true
    }

    public fun is_valid_reveal(_new_owner: address, _claim: vector<u8>, _reveal: vector<u8>): bool {
        false
    }

    // ====== Getters ======

    public fun has_claims(_uid: &UID): bool {
        false
    }

    public fun get_claims(_uid: &UID) {

    }
}