module package::signature {
    use sui::event;
    use sui::ed25519;

    struct IsValid has copy, drop {
        is_valid: bool
    }

    public fun verify(signature: vector<u8>, public_key: vector<u8>, msg: vector<u8>) {
        let is_valid = ed25519::ed25519_verify(&signature, &public_key, &msg);
        event::emit(IsValid { is_valid })
    }
}