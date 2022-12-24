module ownership::delegate {
    use sui::object::ID;
    use std::string::String;

    // Creator fields, used to grant authority
    struct DelegateAddress has store, copy, drop { addr: address }
    struct DelegateID has store, copy, drop { id: ID }
    struct DelegateWitness has store, copy, drop { witness: String }
}