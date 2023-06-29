module outlaw_sky::outlaw_sky {
    use std::string::{String, utf8};
    use std::option::Option;

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::typed_id;
    use sui_utils::vec_map2;

    use ownership::ownership::{Self, INITIALIZE};
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::publish_receipt;

    use transfer_system::simple_transfer::SimpleTransfer;

    use attach::data::{Self, WRITE};

    // use outlaw_sky::warship::Witness as Namespace;
    // use outlaw_sky::warship::Warship;

    // Error constants
    const ENOT_OWNER: u64 = 0;
    const ENO_PACKAGE_AUTHORITY: u64 = 1;

    // Genesis-witness and module-authority witness
    struct OUTLAW_SKY has drop {}
    struct Witness has drop { }

    // Shared, root-level object
    struct Outlaw has key, store {
        id: UID
    }

    // Action Types
    struct CREATOR {} // used by the package-id / org owning the package to create and edit Outlaws
    struct USER {} // used by the Outlaw owner to edit properties of the Outlaw

    // ==== Creator Functions ====
    // In production, you would gate each of these functions to make sure they're being called by an
    // authorized party rather than just anyone.

    // Creates an Outlaw with the specified data, and sets the owner
    public fun create(
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        owner: address,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        assert!(tx_authority::can_act_as_package<Outlaw, CREATOR>(auth), ENO_PACKAGE_AUTHORITY);

        let auth = tx_authority::add_package_witness<Witness, INITIALIZE>(Witness {}, auth);
        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, &auth);
        let outlaw = Outlaw { id: object::new(ctx) };
        let typed_id = typed_id::new(&outlaw);

        ownership::as_shared_object<Outlaw, SimpleTransfer>(&mut outlaw.id, typed_id, owner, &auth);
        data::deserialize_and_set<Outlaw>(&mut outlaw.id, data, fields, &auth);
        transfer::share_object(outlaw);
    }

    // This is a sample of how atomic updates work; the existing value is borrowed and then modified,
    // rather than simply being overwritten. This is safter for concurrently running processes.
    public fun increment_power_level(outlaw: &mut Outlaw, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<Outlaw, CREATOR>(auth), ENO_PACKAGE_AUTHORITY);

        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, auth);
        let power_level = data::borrow_mut_fill<Outlaw, u64>(&mut outlaw.id, utf8(b"power_level"), 0, &auth);
        *power_level = *power_level + 1;
    }

    // Note that rather than asserting that the caller has CREATOR authority and then crafting a
    // package-id auth that can do data::WRITE, like we did above, we could instead just skip both of those
    // and let data::borrow_mut_fill do the auth-checking for us. In this case, the caller must have
    // WRITE action on behalf of this package.
    public fun increment_power_level_2(outlaw: &mut Outlaw, auth: &TxAuthority) {
        let power_level = data::borrow_mut_fill<Outlaw, u64>(&mut outlaw.id, utf8(b"power_level"), 0, auth);
        *power_level = *power_level + 1;
    }

    public fun add_attribute(outlaw: &mut Outlaw, key: String, value: String, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<Outlaw, CREATOR>(auth), ENO_PACKAGE_AUTHORITY);

        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, auth);
        let attributes = data::borrow_mut_fill<Outlaw, VecMap<String, String>>(
            &mut outlaw.id,
            utf8(b"attributes"),
            vec_map::empty(),
            &auth);

        vec_map2::set(attributes, &key, value);
    }

    public fun remove_attribute(outlaw: &mut Outlaw, key: String, auth: &TxAuthority) {
        assert!(tx_authority::can_act_as_package<Outlaw, CREATOR>(auth), ENO_PACKAGE_AUTHORITY);

        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, auth);
        let attributes = data::borrow_mut_fill<Outlaw, VecMap<String, String>>(
            &mut outlaw.id,
            utf8(b"attributes"),
            vec_map::empty(),
            &auth);
            
        vec_map2::remove_maybe(attributes, &key);
    }

    // ====== Primary Sale For Outlaws ======

    public fun load_dispenser() { 
        // TO DO
    }

    // ====== Secondary Sale of Outlaws ======

    // ====== User Functions ======
    // Sample functions for how to edit data

    // This will overwrite the field 'name' in the `Witness` namespace with a new string
    // Because this is not an entry function, and uses auth, the owner can delegate control
    // of the asset to another address to perform this action
    public fun rename(outlaw: &mut Outlaw, new_name: String, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<USER>(&outlaw.id, auth), ENOT_OWNER);

        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, auth);
        data::set<Outlaw, String>(&mut outlaw.id, vector[utf8(b"name")], vector[new_name], &auth);
    }
    
    // This is using a delegation from Foreign -> Witness
    // public entry fun edit_other_namespace(outlaw: &mut Outlaw, new_name: String, store: &DelegationStore) {
    //     let auth = tx_authority::begin_with_type(&Witness {});
    //     auth = tx_authority::add_from_delegation_store(store, &auth);
    //     let namespace_addr = tx_authority::type_into_address<Namespace>();
    //     data::set_(&mut outlaw.id, option::some(namespace_addr), vector[utf8(b"name")], vector[new_name], &auth);
    // }

    // This is using a delegation from Foreign -> address
    // public entry fun edit_other_namespace2(outlaw: &mut Outlaw, new_name: String, store: &DelegationStore, ctx: &mut TxContext) {
    //     let auth = tx_authority::begin(ctx);
    //     auth = tx_authority::add_from_delegation_store(store, &auth);
    //     let namespace_addr = tx_authority::type_into_address<Namespace>();
    //     data::set_(&mut outlaw.id, option::some(namespace_addr), vector[utf8(b"name")], vector[new_name], &auth);
    // }

    // public entry fun edit_as_someone_else(warship: &mut Warship, new_name: String, store: &DelegationStore) {
    //     // Get a different namespace
    //     let auth = tx_authority::begin_from_type(&Witness {});
    //     auth = tx_authority::add_from_delegation_store(store, &auth);
    //     let namespace_addr = tx_authority::type_into_address<Namespace>();

    //     // We have a permission added to this warship; warship.owner has granted our ctx-address permission to edit
    //     // Delegation { for: our-ctx }
    //     let uid = warship::uid_mut(warship, &auth);
    //     data::set_(&mut warship.id, option::some(namespace_addr), vector[utf8(b"name")], vector[new_name], &auth);

    //     // warship.owner has granted Witness permission to edit
    //     // Delegation { for: Witness }

    //     // Warship module has granted our ctx-address permission to edit
    //     // DelegationStore { for: our-ctx }

    //     // Warship module has granted Witness permission to edit
    //     // DelegationStore { for: Witness }
    // }

    // ==== General Functions ====

    // I believe we can use UIDs directly in devInspect transactions now, and no longer need this
    public fun view_all(outlaw: &Outlaw, namespace: Option<ID>): vector<u8> {
        data::view_all(&outlaw.id, namespace)
    }

    public fun uid(outlaw: &Outlaw): (&UID) {
        &outlaw.id
    }

    public fun uid_mut(outlaw: &mut Outlaw, auth: &TxAuthority): &mut UID {
        assert!(ownership::can_borrow_uid_mut(&outlaw.id, auth), ENOT_OWNER);

        &mut outlaw.id
    }

    // ======== Initialize ========

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&genesis, ctx);
        transfer::public_transfer(receipt, tx_context::sender(ctx));
    }
}

// ========= Helper Module =========
// Functions like these need to be hardcoded; they can't be done via client-side composition
// unfortunately, because Sui does not support returning mutable references yet (or perhaps ever).
// Note that these functions accept `auth` and rely on the `data` module itself to make sure only
// callers that have the `WRITE` action delegated to them by the package-itself can call these
// functions.

module outlaw_sky::outlaw_sky_helper {
    use std::string::String;
    use ownership::tx_authority::TxAuthority;
    use attach::data;
    use outlaw_sky::outlaw_sky::{Self, Outlaw};

    public fun update(
        outlaw: &mut Outlaw,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        let uid = outlaw_sky::uid_mut(outlaw, auth);
        data::deserialize_and_set<Outlaw>(uid, data, fields, auth);
    }

    // We cannot delete shared objects yet, like the Outlaw itself, but we _can_ delete metadata
    public fun remove_all(outlaw: &mut Outlaw, auth: &TxAuthority) {
        let uid = outlaw_sky::uid_mut(outlaw, auth);
        data::remove_all<Outlaw>(uid, auth);
    }
}

#[test_only]
module outlaw_sky::tests {
    use std::string::{String, utf8};

    use sui::test_scenario;

    use ownership::tx_authority;

    use display::schema;
    use display::display;

    use outlaw_sky::outlaw_sky;

    // Test constants
    const DATA: vector<vector<u8>> = vector[ vector[6, 79, 117, 116, 108, 97, 119], vector[1, 65, 84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], vector[77, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], vector[199, 0, 0, 0, 0, 0, 0, 0], vector[0] ];

    #[test]
    public fun test_rename() {
        let schema_fields = vector[ vector[utf8(b"name"), utf8(b"String")], vector[utf8(b"description"), utf8(b"String")], vector[utf8(b"image"), utf8(b"String")], vector[utf8(b"power_level"), utf8(b"u64")], vector[utf8(b"attributes"), utf8(b"VecMap")] ];

        let scenario = test_scenario::begin(@0x79);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            
            let schema = schema::create_from_strings(schema_fields, ctx);
            outlaw_sky::create(DATA, &schema, ctx);
            schema::freeze_(schema);
        };

        test_scenario::next_tx(&mut scenario, @0x79);
        {
            let outlaw = test_scenario::take_shared<outlaw_sky::Outlaw>(&scenario);
            let schema = test_scenario::take_immutable<schema::Schema>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);

            outlaw_sky::rename(&mut outlaw, utf8(b"New Name"), &schema, ctx);
            let auth = tx_authority::begin(ctx);
            let uid = outlaw_sky::extend(&mut outlaw, &auth);
            let name = display::borrow<String>(uid, utf8(b"name"));
            assert!(*name == utf8(b"New Name"), 0);

            test_scenario::return_shared(outlaw);
            test_scenario::return_immutable(schema);
        };

        test_scenario::end(scenario);
    }
}