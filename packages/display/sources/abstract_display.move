// Abstract Display objects are Display objects that can be used:
// (1) as fallbacks for non-existing concrete-Display objects
// (2) to define concrete Display objects
//
// For example, `Coin<T>` is an abstract type; `T` can be filled with anything to produce a boundless number of
// concrete types.
// `Coin<T>` is an abstract type, while Coin<0x2::sui::SUI> and Coin<0xc0ffee::diem::DIEM> are concrete types
// that instantiate the abstract type.
//
// Suppose we are querying a Sui Fullnode on `Coin<PaulCoin>`. If a Display<Coin<PaulCoin>> object exists, the
// Fullnode should use that as the template for the Display data, as it is more specific. However, if it doesn't
// exist, then the Fullnode should use the `Coin<T>` AbstractDisplay object instead.
//
// Because AbstractDisplay's are used as templates for Display's, we construct AbstractDisplay as a root-level
// shared object.

module display::abstract_display {
    use std::string::String;
    use std::option::{Self, Option};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::vec_map::VecMap;

    use sui_utils::encode;
    use sui_utils::typed_id;
    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::vec_map2;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::publish_receipt::{Self, PublishReceipt};

    use attach::data;
    use attach::schema;

    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    // Error constants
    const ENO_OWNER_AUTHORITY: u64 = 0;
    const EINVALID_PUBLISH_RECEIPT: u64 = 1;
    const ETYPE_IS_NOT_ABSTRACT: u64 = 2;
    const ETYPE_ALREADY_DEFINED: u64 = 3;
    const EVEC_LENGTH_MISMATCH: u64 = 4;
    const ETYPE_IN_RESOLVER_NOT_SPECIFIED: u64 = 7;

    // Shared root-level object. Cannot be destroyed. Single, unique on its `type` field.
    // We could potentially make these storeable / owned as well; it depends if the Sui Fullnode will be able
    // to find it to do resolution.
    struct AbstractDisplay has key {
        id: UID,
        type: StructTag,
        // These will be used as the default display template when defining a concrete type
        resolvers: VecMap<String, vector<String>>
    }

    // Added to publish receipt to ensure an abstract type is only created once
    struct Key has store, copy, drop { slot: String } // slot is a module + struct name

    // Module authority
    struct Witness has drop { }

    // When create an abstract type like `Coin<E>`, the `E` can be filled in as anything for the
    // type argument.
    // T must be abstract, in the sense that it has at least one generic

    public entry fun claim<T>(
        publisher: &mut PublishReceipt,
        owner_maybe: Option<address>,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        let abstract_type = claim_<T>(publisher, keys, resolver_strings, ctx);

        // If `owner` is not set, it will default to the transaction-sender
        let owner = if (option::is_some(&owner_maybe)) { 
            option::destroy_some(owner_maybe) 
        } else { 
            tx_context::sender(ctx)
        };

        return_and_share(abstract_type, owner);
    }

    public fun claim_<T>(
        publisher: &mut PublishReceipt,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>,
        ctx: &mut TxContext
    ): AbstractDisplay {
        assert!(encode::package_id<T>() == publish_receipt::into_package_id(publisher), EINVALID_PUBLISH_RECEIPT);
        assert!(encode::has_generics<T>(), ETYPE_IS_NOT_ABSTRACT);

        // Ensures that this abstract type can only ever be created once
        let key = Key { slot: encode::module_and_struct_name<T>() };
        let uid = publish_receipt::uid_mut(publisher);
        assert!(!dynamic_field::exists_(uid, key), ETYPE_ALREADY_DEFINED);
        dynamic_field::add(uid, key, true);

        // Input validation
        let i = 0;
        while (i < vector::length(&keys)) {
            let resolver = *vector::borrow(&resolver_strings, i);
            assert!(vector::length(&resolver) > 0, ETYPE_IN_RESOLVER_NOT_SPECIFIED);
            i = i + 1;
        };

        AbstractDisplay { 
            id: object::new(ctx),
            type: struct_tag::get_abstract<T>(),
            resolvers: vec_map2::create(keys, resolver_strings)
        }
    }

    public fun return_and_share(abstract_type: AbstractDisplay, owner: address) {
        let auth = tx_authority::begin_with_type(&Witness { });
        let typed_id = typed_id::new(&abstract_type);
        ownership::as_shared_object<AbstractDisplay, SimpleTransfer>(
            &mut abstract_type.id,
            typed_id,
            vector[owner],
            &auth
        );
        transfer::share_object(abstract_type);
    }

    // ====== Modify Resolvers ======
    // This is Display's own custom API for editing the resolvers stored on the Display object.

    // Convenience function
    public entry fun set_resolvers(
        self: &mut AbstractDisplay,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>,
        ctx: &mut TxContext
    ) {
        set_resolvers_(self, keys, resolver_strings, &tx_authority::begin(ctx));
    }

    // Combination of add and edit. If a key already exists, it will be overwritten, otherwise
    // it will be added.
    public fun set_resolvers_(
        self: &mut AbstractDisplay,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), ENO_OWNER_AUTHORITY);

        let (i, len) = (0, vector::length(&keys));
        assert!(len == vector::length(&resolver_strings), EVEC_LENGTH_MISMATCH);

        while (i < len) {
            vec_map2::set(
                &mut self.resolvers,
                vector::borrow(&keys, i),
                *vector::borrow(&resolver_strings, i)
            );
            i = i + 1;
        };
    }

    // Convenience function
    public entry fun remove_resolvers(self: &mut AbstractDisplay, keys: vector<String>, ctx: &mut TxContext) {
        remove_resolvers_(self, keys, &tx_authority::begin(ctx));
    }

    /// Remove keys from the Type object
    public fun remove_resolvers_(self: &mut AbstractDisplay, keys: vector<String>, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), ENO_OWNER_AUTHORITY);

        let (i, len) = (0, vector::length(&keys));
        while (i < len) {
            vec_map2::remove_maybe(&mut self.resolvers, vector::borrow(&keys, i));
            i = i + 1;
        };
    }

    // ======== Accessor Functions =====

    public fun borrow_resolvers(self: &AbstractDisplay): &VecMap<String, vector<String>> {
        &self.resolvers
    }

    public fun borrow_mut_resolvers<T>(
        self: &mut AbstractDisplay,
        auth: &TxAuthority
    ): &mut VecMap<String, vector<String>> {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), ENO_OWNER_AUTHORITY);

        &mut self.resolvers
    }

    public fun into_struct_tag(self: &AbstractDisplay): StructTag {
        self.type
    }

    // ======== View Functions =====

    // AbstractDisplay objects serve as convenient view-function fallbacks
    public fun view_with_default<T>(
        uid: &UID,
        namespace: Option<address>,
        display: &AbstractDisplay
    ): vector<u8> {
        data::view_with_default(uid, &display.id, namespace, schema::into_keys(uid, namespace))
    }

    // ======== For Owners ========

    public fun uid(self: &AbstractDisplay): &UID {
        &self.id
    }

    public fun uid_mut(self: &mut AbstractDisplay, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner(&self.id, auth), ENO_OWNER_AUTHORITY);

        &mut self.id
    }
}

#[test_only]
module display::abstract_display_tests {
    use std::vector;
    use std::option::{Self, Option};
    use std::string::{utf8, String};

    use sui::test_scenario::{Self, Scenario};
    use sui::vec_map;
    use sui::transfer;

    use display::abstract_display::{Self, AbstractDisplay};

    use ownership::publish_receipt::{Self, PublishReceipt};

    struct TEST_OTW has drop {}

    struct TestAbstractDisplay<phantom T> {}
    struct Base has drop {}

    const SENDER: address = @0xBABE;

    public fun create_publish_receipt(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        let receipt = publish_receipt::test_claim(&TEST_OTW {}, ctx);

        transfer::public_transfer(receipt, SENDER);
    }

    fun get_keys_and_resolvers(): (vector<String>, vector<vector<String>>) {
        let keys = vector[utf8(b"name"), utf8(b"url"), utf8(b"description")];
        let resolvers = vector[
            vector[utf8(b"Project name")],
            vector[utf8(b"https://projecturl.com")],
            vector[utf8(b"Project description")],
        ];

        (keys, resolvers)
    }

    public fun create_abstract_display(
        scenario: &mut Scenario,
        publisher: &mut PublishReceipt,
        owner_maybe: Option<address>,
        keys: vector<String>,
        resolver_strings: vector<vector<String>>
    ) {
        let ctx = test_scenario::ctx(scenario);
        abstract_display::create<TestAbstractDisplay<Base>>(publisher, owner_maybe, keys, resolver_strings, ctx);
    }

    fun assert_abstract_display_resolvers(abstract_display: &AbstractDisplay, keys: vector<String>, resolver_strings: vector<vector<String>>) {
        let resolvers = abstract_display::borrow_resolvers(abstract_display);
        let (i, len) = (0, vector::length(&keys));

        while(i < len) {
            let key = vector::borrow(&keys, i);
            let resolver_str = vector::borrow(&resolver_strings, i);

            assert!(vec_map::get(resolvers, key) == resolver_str, 0);

            i = i + 1;
        };
    }


    #[test]
    fun test_create_abstract_display() {
        let scenario = test_scenario::begin(SENDER);
        let (keys, resolvers) = get_keys_and_resolvers();

        create_publish_receipt(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let receipt = test_scenario::take_from_sender<PublishReceipt>(&scenario);
            create_abstract_display(&mut scenario, &mut receipt, option::none(), keys, resolvers);
            test_scenario::next_tx(&mut scenario, SENDER);
            
            {
                let abstract_display = test_scenario::take_shared<AbstractDisplay>(&scenario);
                
                assert_abstract_display_resolvers(&abstract_display, keys, resolvers);
                test_scenario::return_shared(abstract_display);
            };

            test_scenario::return_to_sender(&scenario, receipt);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_abstract_display_resolvers() {
        let scenario = test_scenario::begin(SENDER);
        let (keys, resolvers) = get_keys_and_resolvers();

        create_publish_receipt(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let receipt = test_scenario::take_from_sender<PublishReceipt>(&scenario);
            create_abstract_display(&mut scenario, &mut receipt, option::none(), keys, resolvers);
            test_scenario::next_tx(&mut scenario, SENDER);
            
            {
                let abstract_display = test_scenario::take_shared<AbstractDisplay>(&scenario);
                assert_abstract_display_resolvers(&abstract_display, keys, resolvers);

                let ctx = test_scenario::ctx(&mut scenario);
                abstract_display::remove_resolvers(&mut abstract_display, keys, ctx);
                assert!(vec_map::is_empty(abstract_display::borrow_resolvers(&abstract_display)), 0);

                test_scenario::return_shared(abstract_display);
            };

            test_scenario::return_to_sender(&scenario, receipt);
        };

        test_scenario::end(scenario);
    }
}