module outlaw_sky::outlaw_sky {
    use std::string::{String, utf8};
    use sui::bcs;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::typed_id;
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use display::display;
    use display::schema::Schema;
    use display::publish_receipt;
    use transfer_system::simple_transfer::Witness as SimpleTransfer;

    // Error constants
    const ENOT_OWNER: u64 = 0;

    // Genesis-witness and witness
    struct OUTLAW_SKY has drop {}
    struct Witness has drop { }

    struct Outlaw has key, store {
        id: UID
        // Ownership fields
        // Metadata fields
    }

    public entry fun create(data: vector<vector<u8>>, schema: &Schema, ctx: &mut TxContext) {
        let auth = tx_authority::begin_with_type(&Witness {});
        let outlaw = Outlaw { 
            id: object::new(ctx) 
        };
        let typed_id = typed_id::new(&outlaw);

        ownership::initialize_with_module_authority(&mut outlaw.id, typed_id, &auth);

        display::attach(&mut outlaw.id, data, schema, &auth);

        let owner = vector[tx_context::sender(ctx)];
        ownership::as_shared_object<SimpleTransfer>(&mut outlaw.id, owner, &auth);

        transfer::share_object(outlaw);
    }

    // This function is needed until we can use UID's directly in devInspect transactions
    public fun view_all(outlaw: &Outlaw, schema: &Schema): vector<u8> {
        display::view_all(&outlaw.id, schema)
    }

    // We need this wrapper because (1) we need &mut outlaw.id from an entry function, which is not possible until
    // Programmable Transactions are available, and (2) the metadata program requires that we, the creator module, sign off
    // on all changes to metadata.
    public entry fun update(
        outlaw: &mut Outlaw,
        keys: vector<String>,
        data: vector<vector<u8>>,
        schema: &Schema,
        ctx: &mut TxContext
    ) {
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        display::update(&mut outlaw.id, keys, data, schema, true, &auth);
    }

    // We cannot delete shared objects yet, like the Outlaw itself, but we _can_ delete metadata
    public entry fun detach(outlaw: &mut Outlaw, schema: &Schema, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        display::detach(&mut outlaw.id, schema, &auth);
    }

    public fun load_dispenser() { 
        // TO DO
    }

    // Public extend
    public fun extend(outlaw: &mut Outlaw, auth: &TxAuthority): (&mut UID) {
        assert!(ownership::is_authorized_by_owner(&outlaw.id, auth), ENOT_OWNER);

        &mut outlaw.id
    }

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&genesis, ctx);
        transfer::transfer(receipt, tx_context::sender(ctx));
    }

    // ====== User Functions ====== 
    // Note that these functions assume that the metadata schema used includes the specified strings, of the specified types
    // These assumptions are hardcoded here

    // This is a sample of how a user-facing function would work
    // This is an overwrite-update, which means that the entire metadata field is replaced
    public entry fun rename(outlaw: &mut Outlaw, new_name: String, schema: &Schema, ctx: &TxContext) {
        let keys = vector[utf8(b"name")];
        let data = vector[bcs::to_bytes(&new_name)];
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));

        display::update(&mut outlaw.id, keys, data, schema, true, &auth);
    }

    // This is a sample of how atomic updates work, versus overwrite-updates
    public entry fun add_attribute(outlaw: &mut Outlaw, key: String, value: String, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));
        let attributes = display::borrow_mut<VecMap<String, String>>(&mut outlaw.id, utf8(b"attributes"), &auth);
        vec_map::insert(attributes, key, value);
    }

    public entry fun remove_attribute(outlaw: &mut Outlaw, key: String, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));
        let attributes = display::borrow_mut<VecMap<String, String>>(&mut outlaw.id, utf8(b"attributes"), &auth);
        vec_map::remove(attributes, &key);
    }

    public entry fun increment_power_level(outlaw: &mut Outlaw, ctx: &mut TxContext) {
        let slot = utf8(b"power_level");
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));

        let power_level = display::borrow_mut<u64>(&mut outlaw.id, slot, &auth);

        *power_level = *power_level + 1;
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