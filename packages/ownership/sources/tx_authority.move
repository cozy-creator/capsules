// TO DO: create a validator for witness types as strings or TypeNames?
// TO DO: once Sui adds the ability for multiple signers per transaction, this will have to be adjusted
// TO DO: we might be able to add addresses directly using signatures? I.e., submit some bytes + signature
// from some pubkey, so we treat that as a validation and then add that pubkey to our list of addresses

// Consummable authority? Peel off authority after being checked

// Capability pattern: type, id-number stored in cap, id-number stored in property

module ownership::tx_authority {
    use std::hash;
    use std::type_name;
    use std::vector;
    use sui::bcs;
    use sui::tx_context::{Self, TxContext};
    use sui::object;
    use sui_utils::vector::slice_vector;

    struct TxAuthority has drop {
        addresses: vector<address>
    }

    public fun begin(ctx: &TxContext): TxAuthority {
        TxAuthority { addresses: vector[tx_context::sender(ctx)] }
    }

    public fun add_object<T: key>(object: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(object::id_address(object), &mut new_auth);

        new_auth
    }

    public fun add_witness<Witness: drop>(_witness: Witness, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(type_into_addr<Witness>(), &mut new_auth);

        new_auth
    }

    public fun add_capability<Capability>(_cap: &Capability, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(type_into_addr<Capability>(), &mut new_auth);

        new_auth
    }

    // ========= Validity Checkers =========

    public fun is_valid_address(addr: address, auth: &TxAuthority): bool {
        let (exists, _) = vector::index_of(&auth.addresses, &addr);
        exists
    }

    public fun is_valid_object<T: key>(object: &T, auth: &TxAuthority): bool {
        is_valid_address(object::id_address(object), auth)
    }

    public fun is_valid_witness<Witness: drop>(auth: &TxAuthority): bool {
        is_valid_address(type_into_addr<Witness>(), auth)
    }

    public fun is_valid_capability<T>(auth: &TxAuthority): bool {
        is_valid_address(type_into_addr<T>(), auth)
    }

    public fun type_into_addr<T>(): address {
        let typename = type_name::get<T>();
        let typename_bytes = bcs::to_bytes(&typename);
        let hashed_typename = hash::sha2_256(typename_bytes);
        let truncated = slice_vector(&hashed_typename, 0, 20);
        bcs::peel_address(&mut bcs::new(truncated))
    }

    // ========= Internal Functions =========

    fun add_internal(addr: address, auth: &mut TxAuthority) {
        if (!vector::contains(&auth.addresses, &addr)) {
            vector::push_back(&mut auth.addresses, addr);
        };
    }
}

#[test_only]
module sui_playground::tx_authority_test {
    use sui::test_scenario;
    use sui_playground::tx_authority;

    struct Witness has drop {}

    #[test]
    public fun test1() {
        let scenario = test_scenario::begin(@0x69);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let auth = tx_authority::create(ctx);
            tx_authority::add_witness(Witness {}, &auth);
        };
        test_scenario::end(scenario);
    }
}