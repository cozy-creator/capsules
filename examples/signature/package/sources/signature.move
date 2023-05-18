module package::signature {
    use sui::bcs;
    use sui::hex;
    use sui::event;
    use sui::ed25519;

    struct Message has copy, drop {
        value: vector<u8>
    }

    struct Result has copy, drop {
        message: vector<u8>,
        is_verified: bool
    }

    public fun verify(signature: vector<u8>, public_key: vector<u8>, message: vector<u8>) {
        let message = Message { value: message };
        let is_verified = ed25519::ed25519_verify(&signature, &public_key, &hex::encode(bcs::to_bytes(&message)));

        event::emit(Result { is_verified, message: bcs::to_bytes(&message) });
    }
}