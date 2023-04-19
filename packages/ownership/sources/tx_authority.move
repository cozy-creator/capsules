// TxAuthority uses the convention that modules can sign for themselves using the reserved struct name
//  `Witness`, i.e., 0x899::my_module::Witness. Modules should always define a Witness struct, and
// carefully guard access to it, as it represents the authority of the module at runtime.

module ownership::tx_authority {
    use std::option::{Self, Option};
    use std::string::{Self, String, utf8};
    use std::vector;

    use sui::bcs;
    use sui::hash;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID};

    use sui_utils::encode;
    use sui_utils::string2;
    use sui_utils::struct_tag::{Self, StructTag};

    const WITNESS_STRUCT: vector<u8> = b"Witness";

    // agents: [ addresses that have given full authority to this transaction ]
    // delegations: (principle, types corresponding to functions allowed to be called on behalf of principal)
    // namespaces: (package ID, principal for that package; the ID (as an address) of its namespace object)
    struct TxAuthority has drop {
        agents: vector<address>,
        delegations: VecMap<address, vector<Permission>>,
        namespaces: VecMap<ID, address>
    }

    // ========= Begin =========

    // Begins with a transaction-context object
    public fun begin(ctx: &TxContext): TxAuthority {
        TxAuthority { addresses: vector[tx_context::sender(ctx)] }
    }

    // Begins with a capability-id
    public fun begin_with_id<T: key>(cap: &T): TxAuthority {
        TxAuthority { addresses: vector[object::id_address(cap)] }
    }

    public fun begin_with_uid(uid: &UID): TxAuthority {
        TxAuthority { addresses: vector[object::uid_to_address(uid)] }
    }

    // Begins with a capability-type
    public fun begin_with_type<T>(_cap: &T): TxAuthority {
        TxAuthority { addresses: vector[type_into_address<T>()] }
    }

    public fun empty(): TxAuthority {
        TxAuthority { addresses: vector::empty<address>() }
    }

    // ========= Add Authorities =========

    public fun add_id_capability<T: key>(cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(object::id_address(cap), &mut new_auth);

        new_auth
    }

    public fun add_uid(uid: &UID, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(object::uid_to_address(uid), &mut new_auth);

        new_auth
    }

    public fun add_type_capability<T>(_cap: &T, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: *&auth.addresses };
        add_internal(type_into_address<T>(), &mut new_auth);

        new_auth
    }

    // ========= Delegation System =========

    friend ownership::delegation;
    friend ownership::namespace;

    // This is a reserverd role name; if a principal gives an agent this role, then they can act as that agent
    // for every permission; there is no scope / limitation. Note that this sitll doesn't make the agent identical to the
    // princpal. Doing that would be dangerous, as the agent could then give other agents unlimited permissions as well,
    // ad infinitum.
    const ALL: vector<u8> = b"ALL";

    // Can be stored, but not copied. Used as a template to produce Permission structs
    struct StoredPermission has store, drop {
        inner: String
    }

    // Does not have store, and hence must be dropped at the end of tx-execution
    struct Permission has copy, drop {
        inner: String
    }

    // This can only be used by the `ownership::delegation`
    public(friend) fun add_permissions(
        principal: address,
        roles: vector<String>,
        role_permissions: VecMap<String, vector<StoredPermission>>,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { agents: auth.agents, delegations: auth.delegations, namespaces: auth.namespaces };

        let i = 0;
        while (i < vector::length(roles)) {
            let role = *vector::borrow(roles, i);
            if (role == utf8(ALL)) {
                // We don't need any other delegations
                vec_map2::set(&mut new_auth.delegations, principal, vector[Permission { inner: utf8(ALL) }]);
                break;
            }
            let stored = vec_map::get(role_permissions, role);
            let permissions = copy_permissions(stored);
            vec_map2::merge(&mut new_auth.delegations, principal, permissions);
            i = i + 1;
        };

        new_auth
    }
    
    // Internal function so that only this module can turn StoredPermission into Permission objects
    fun copy_permissions(stored: &vector<StoredPermission>): vector<Permission> {
        let i = 0;
        let permissions = vector::empty<Permission>();
        while (i < vector::length(&stored)) {
            let inner = vector::borrow(&stored, i).inner;
            vector::push_back(&mut permissions, Permission { inner });
            i = i + 1;
        };
    }

    public(friend) fun add_namespace(
        packages: vector<ID>,
        principal: address,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { agents: auth.agents, delegations: auth.delegations, namespaces: auth.namespaces };
        while (!vector::is_empty(&packages)) {
            let package = vector::pop_back(&mut packages);
            vec_map2::insert_maybe(&mut new_auth.namespaces, package, principal);
        };

        new_auth
    }

    // ========= Validity Checkers =========

    public fun is_signed_by(addr: address, auth: &TxAuthority): bool {
        vector::contains(&auth.addresses, &addr)
    }

    // Defaults to `true` if the signing address is option::none
    public fun is_signed_by_(addr: Option<address>, auth: &TxAuthority): bool {
        if (option::is_none(&addr)) return true;
        is_signed_by(option::destroy_some(addr), auth)
    }

    public fun is_signed_by_module<T>(auth: &TxAuthority): bool {
        is_signed_by(witness_addr<T>(), auth)
    }

    // type can be any type belonging to the module, such as 0x599::my_module::StructName
    public fun is_signed_by_module_(type: String, auth: &TxAuthority): bool {
        is_signed_by(witness_addr_(type), auth)
    }

    public fun is_signed_by_object<T: key>(id: ID, auth: &TxAuthority): bool {
        is_signed_by(object::id_to_address(&id), auth)
    }

    public fun is_signed_by_type<T>(auth: &TxAuthority): bool {
        is_signed_by(type_into_address<T>(), auth)
    }

    public fun has_k_of_n_signatures(addrs: &vector<address>, threshold: u64, auth: &TxAuthority): bool {
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

    public fun has_permission<Permission>(principal: address, auth: &TxAuthority): bool {
        if (is_signed_by(principal, auth)) { return true };

        let permissions_maybe = vec_map2::get_maybe(&auth.delegations, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        let type_name = encode::type_name<Permission>();
        let i = 0;
        while (i < vector::length(&permissions)) {
            let permission = vector::borrow(&permissions, i);
            if (permission.inner == utf8(ALL) || permission.inner == type_name ) { 
                return true
            };
            i = i + 1;
        };

        false
    }

    public fun is_allowed<T, Principal>(function: u8, auth: &TxAuthority): bool {
        let principal = type_into_address<Principal>();
        is_allowed_<T>(principal, function, auth)
    }

    // Unlike the above validity-checkers, this also checks against delegations
    public fun is_allowed_<T>(principal: address, function: u8, auth: &TxAuthority): bool {
        if (is_signed_by(principal, auth)) { return true };

        let permissions_maybe = vec_map2::get_maybe(&auth.delegations, principal);
        if (option::is_none(&permissions_maybe)) { return false };
        let permissions = option::destroy_some(permissions_maybe);

        // TO DO: improve efficiency here
        let (package, module_name, _, _) = encode::type_name_decomposed<T>();
        let i = 0;
        while (i < vector::length(&permissions)) {
            let perm = vector::borrow(&permissions, i);
            if (package == perm.package &&
                module_name == perm.module_name && 
                acl::has_role(&perm.functions, function)
            ) { return true; }

            i = i + 1;
        };

        false
    }

    // Same as above except the principal is optional and defaults to true if it's none
    public fun is_allowed__<T>(principal_maybe: Option<address>, function: u8, auth: &TxAuthority): bool {
        if (option::is_none(&principal_maybe)) { return true };
        let principal = option::destroy_some(principal_maybe);
        is_allowed_<T>(principal, function, auth)
    }

    public fun is_signed_by_namespace<AnyStructFromNamespace, T>(function: u8, auth: &TxAuthority): bool {
        let package = encode::package_id<AnyStructFromNamespace>();
        let namespace_maybe = vec_map2::get_maybe(&auth.namespaces, package);
        if (option::is_none(&namespace_maybe)) { return false };
        let namespace = option::destroy_some(namespace_maybe);

        is_allowed<T>(namespace, function, auth)
    }

    // ========= Getter Functions =========

    public fun agents(auth: &TxAuthority): vector<address> {
        auth.agents
    }

    public fun delegations(auth: &TxAuthority): VecMap<address, Permission> {
        auth.delegations
    }

    // May return option::none if the namespace hasn't been added to this TxAuthority object
    public fun get_principal<P>(auth: &TxAuthority): Option<address> {
        vec_map::get_maybe(&auth.namespaces, encode::package_id<P>());
    }

    // ========= Convert Types to Addresses =========

    public fun type_into_address<T>(): address {
        let typename = encode::type_name<T>();
        type_string_into_address(typename)
    }

    public fun type_string_into_address(type: String): address {
        let typename_bytes = string::bytes(&type);
        let hashed_typename = hash::blake2b256(typename_bytes);
        // let truncated = vector2::slice(&hashed_typename, 0, address::length());
        bcs::peel_address(&mut bcs::new(hashed_typename))
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

    public fun witness_addr_from_struct_tag(tag: &StructTag): address {
        let witness_type = string2::empty();
        string::append(&mut witness_type, string2::from_id(struct_tag::package_id(tag)));
        string::append(&mut witness_type, utf8(b"::"));
        string::append(&mut witness_type, struct_tag::module_name(tag));
        string::append(&mut witness_type, utf8(b"::"));
        string::append(&mut witness_type, utf8(WITNESS_STRUCT));

        type_string_into_address(witness_type)
    }

    public fun witness_string<T>(): String {
        encode::append_struct_name<T>(string::utf8(WITNESS_STRUCT))
    }

    public fun witness_string_(type: String): String {
        let module_addr = encode::package_id_and_module_name_(type);
        encode::append_struct_name_(module_addr, string::utf8(WITNESS_STRUCT))
    }

    // ========= Delegation System =========

    struct Delegations<Witness: drop> has key {
        inner: VecMap<address, u16>
    }

    // Convenience function
    public fun begin_with_delegation(stored: &Delegations<Witness>, ctx: &TxContext): TxAuthority {
        let auth = begin(ctx);
        claim_delegation(stored, &auth)
    }

    public fun claim_delegation<Witness: drop>(
        stored: &Delegations<Witness>,
        auth: &TxAuthority
    ): TxAuthority {
        let new_auth = TxAuthority { 
            addresses: auth.addresses,
            delegations: auth.delegations
        };

        let i = 0;
        while (i < vector::length(&new_auth.addresses)) {
            let addr = *vector::borrow(&new_auth.addresses, i);
            acl::or_merge(&mut new_auth.delegations, vec_map::get(stored, for));
            i = i + 1;
        };

        new_auth
    }

    // ========= Internal Functions =========

    fun add_internal(addr: address, auth: &mut TxAuthority) {
        if (!vector::contains(&auth.addresses, &addr)) {
            vector::push_back(&mut auth.addresses, addr);
        };
    }

    #[test_only]
    public fun begin_for_testing(addr: address): TxAuthority {
        TxAuthority { addresses: vector[addr] }
    }

    #[test_only]
    public fun add_for_testing(addr: address, auth: &TxAuthority): TxAuthority {
        let new_auth = TxAuthority { addresses: auth.addresses };
        add_internal(addr, &mut new_auth);

        new_auth
    }
}

#[test_only]
module ownership::tx_authority_test {
    use sui::test_scenario;
    use sui::sui::SUI;
    use ownership::tx_authority;
    use sui_utils::encode;

    const SENDER1: address = @0x69;
    const SENDER2: address = @0x420;

    struct SomethingElse has drop {}
    struct Witness has drop {}

    #[test]
    public fun signer_authority() {
        let scenario = test_scenario::begin(SENDER1);
        let ctx = test_scenario::ctx(&mut scenario);
        {
            let auth = tx_authority::begin(ctx);
            assert!(tx_authority::is_signed_by(SENDER1, &auth), 0);
            assert!(!tx_authority::is_signed_by(SENDER2, &auth), 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    public fun module_authority() {
        let scenario = test_scenario::begin(@0x69);
        let _ctx = test_scenario::ctx(&mut scenario);
        {
            let auth = tx_authority::begin_with_type<Witness>(&Witness {});
            let type = encode::type_name<SomethingElse>();
            assert!(tx_authority::is_signed_by_module_(type, &auth), 0);

            let type = encode::type_name<SUI>();
            assert!(!tx_authority::is_signed_by_module_(type, &auth), 0);

            assert!(tx_authority::is_signed_by_module<SomethingElse>(&auth), 0);
            assert!(!tx_authority::is_signed_by_module<SUI>(&auth), 0);
        };
        test_scenario::end(scenario);
    }
}