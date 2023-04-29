// Note that when an Outlaw asset is created, we do not return the Outlaw object or make it
// inspectable in the same transaction. This is so that the caller cannot inspect it,
// determine it if it has the attributes it wants or not, and then abort if it doesn't.
// This would be cheating the randomness-mechanic.

module games::outlaw_sky {

    // use sui::ecdsa_r1;
    use sui::ed25519;

    // struct Outlaw has key {
    //     id: UID,
    //     version: u64
    // }

    // // Pull Info struct; `pull_info` must conform to this shape for a tx to succeed.
    // // id: ID (32 bytes)
    // // premium: bool (1 byte)
    // // fixed-traits: vector<u8> (variable length)

    // // Events

    // // permission objects
    // struct EDIT {}

    // // PullInfo contains both the pre-selected traits, and regular VS premium.
    // public fun create(pull_info: PullInfo, auth: &TxAuthority) {
    //     assert!(server::has_namespace_permission<Outlaw, EDIT>(auth), ENO_SERVER_PERMISSION);

    // }
    
    // public entry fun regenerate(
    //     outlaw: &mut Outlaw,
    //     pull_info: vector<u8>,
    //     signature: vector<u8>,
    //     auth: &TxAuthority
    // ) {
    //     assert!(server::has_namespace_permission<Outlaw, EDIT>(auth), ENO_SERVER_PERMISSION);
    //     assert!(client::has_owner_permission<EDIT>(&outlaw.id, auth), ENO_OWNER_PERMISSION);
    // }

    // public fun destroy_temp(outlaw: &mut Outlaw) {

    // }

    // public entry fun destroy(outlaw: Outlaw) {

    // }

    // public fun verify_signature(message: vector<u8>, signature: vector<u8>, public_key: address): bool {
    //     // Check hash
    //     ecdsa_r1::secp256t1_verify(signature, public_key, message, 0u8);
    // }

    public fun check_signature(message: vector<u8>, signature: vector<u8>, public_key: vector<u8>): bool {
        ed25519::ed25519_verify(&signature, &public_key, &message)
    }
}