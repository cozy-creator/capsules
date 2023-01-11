// TxAuthority uses the convention that modules can sign for themselves using a struct named `Witness`,
// i.e., 0x899::my_module::Witness. Modules should always define a Witness struct, and carefully guard
// its access, as it represents the authority of the module at runtime.

module ownership::tx_authority {
    use std::ascii::{Self, String};
    use std::hash;
    use std::type_name;
    use std::vector;
    use sui::bcs;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID};
    use sui_utils::vector::slice;
    use sui_utils::encode;

    const WITNESS_STRUCT: vector<u8> = b"Witness";

    struct TxAuthority has drop {
        addresses: vector<address>
    }

    public fun begin(ctx: &TxContext): TxAuthority {
        TxAuthority { addresses: vector[tx_context::sender(ctx)] }
    }

    // Begins with a transaction-context object
    public fun begin_(): TxAuthority {
        TxAuthority { addresses: vector::empty<address>() }
    }

    public fun add_capability_id<T: key>(cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(object::id_address(cap), &mut new_auth);

        new_auth
    }

    public fun add_capability_type<T>(_cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(type_into_address<T>(), &mut new_auth);

        new_auth
    }

    // ========= Validity Checkers =========

    public fun is_signed_by(addr: address, auth: &TxAuthority): bool {
        vector::contains(&auth.addresses, &addr)
    }

    public fun is_signed_by_module<T>(auth: &TxAuthority): bool {
        is_signed_by(witness_addr<T>(), auth)
    }

    public fun is_signed_by_object<T: key>(id: ID, auth: &TxAuthority): bool {
        is_signed_by(object::id_to_address(&id), auth)
    }

    public fun is_signed_by_type<T>(auth: &TxAuthority): bool {
        is_signed_by(type_into_address<T>(), auth)
    }

    public fun has_k_of_n_addresses(addrs: &vector<address>, threshold: u64, auth: &TxAuthority): bool {
        let k = number_of_signers(addrs, auth);
        if (k >= threshold) true
        else false
    }

    // If you're doing a 'k of n' signature schema, pass your vector of the n signatures, and if this
    // returns >= k pass the check, otherwise fail the check
    public fun number_of_signers(addrs: &vector<address>, auth: &TxAuthority): u64 {
        let (total, i) = (0, 0);
        while (i < vector::length(addrs)) {
            let addr = *vector::borrow(addrs, i);
            if (is_signed_by(addr, auth)) { total = total + 1; };
            i = i + 1;
        };
        total
    }

    // ========= Convert Types to Addresses =========

    public fun type_into_address<T>(): address {
        let typename = type_name::into_string(type_name::get<T>());
        type_string_into_address(typename)
    }

    public fun type_string_into_address(type: String): address {
        let typename_bytes = bcs::to_bytes(&type);
        let hashed_typename = hash::sha3_256(typename_bytes);
        let truncated = slice(&hashed_typename, 0, 20);
        bcs::peel_address(&mut bcs::new(truncated))
    }

    // ========= Module-Signing Witness =========

    public fun witness_addr<T>(): address {
        let witness_type = witness_string<T>();
        type_string_into_address(witness_type)
    }

    public fun witness_addr_(type: String): address {
        let witness_type = witness_string_(type);
        type_string_into_address(witness_type)
    }

    public fun witness_string<T>(): String {
        encode::append_struct_name<T>(ascii::string(WITNESS_STRUCT))
    }

    public fun witness_string_(type: String): String {
        let (module_addr, _) = encode::decompose_type_name(type);
        encode::append_struct_name_(module_addr, ascii::string(WITNESS_STRUCT))
    }

    // ========= Internal Functions =========

    fun add_internal(addr: address, auth: &mut TxAuthority) {
        if (!vector::contains(&auth.addresses, &addr)) {
            vector::push_back(&mut auth.addresses, addr);
        };
    }
}

#[test_only]
module ownership::tx_authority_test {
    use sui::test_scenario;
    use ownership::tx_authority;

    struct Witness has drop {}

    #[test]
    public fun test1() {
        let scenario = test_scenario::begin(@0x69);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let auth = tx_authority::create(ctx);
            tx_authority::add_type(&Witness {}, &auth);
        };
        test_scenario::end(scenario);
    }
}