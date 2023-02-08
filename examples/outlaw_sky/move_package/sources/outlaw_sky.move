module outlaw_sky::outlaw_sky {
    use std::ascii::{Self};
    use std::string::String;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use metadata::metadata;
    use metadata::schema::Schema;
    use metadata::publish_receipt;
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
        let outlaw = Outlaw { id: object::new(ctx) };
        let owner = tx_context::sender(ctx);
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        let proof = ownership::setup(&outlaw);

        ownership::initialize(&mut outlaw.id, proof, &auth);
        metadata::attach(&mut outlaw.id, data, schema, &auth);
        ownership::initialize_owner_and_transfer_authority<SimpleTransfer>(&mut outlaw.id, owner, &auth);
        transfer::share_object(outlaw);
    }

    // This function is needed until we can use UID's directly in devInspect transactions
    public fun view_all(outlaw: &Outlaw, schema: &Schema): vector<u8> {
        metadata::view_all(&outlaw.id, schema)
    }

    // We need this wrapper because (1) we need &mut outlaw.id from an entry function, which is not possible until
    // Programmable Transactions are available, and (2) the metadata program requires that we, the creator module, sign off
    // on all changes to metadata.
    public entry fun update(outlaw: &mut Outlaw, keys: vector<ascii::String>, data: vector<vector<u8>>, schema: &Schema, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        metadata::update(&mut outlaw.id, keys, data, schema, true, &auth);
    }

    // We cannot delete shared objects yet, like the Outlaw itself, but we _can_ delete metadata
    public entry fun delete_all(outlaw: &mut Outlaw, schema: &Schema, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness {}, &tx_authority::begin(ctx));
        metadata::delete_all(&mut outlaw.id, schema, &auth);
    }

    public fun load_dispenser() { 
        // TO DO
    }

    // Public extend
    public fun extend<T: store>(outlaw: &mut Outlaw, auth: &TxAuthority): (&mut UID) {
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
    public entry fun rename(outlaw: &mut Outlaw, new_name: ascii::String, schema: &Schema, ctx: &TxContext) {
        let keys = vector[ascii::string(b"name")];
        let data = vector[ascii::into_bytes(new_name)];
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));

        metadata::update(&mut outlaw.id, keys, data, schema, true, &auth);
    }

    // This is a sample of how atomic updates work, versus overwrite-updates
    public entry fun add_attribute(outlaw: &mut Outlaw, key: String, value: String, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));
        let attributes = metadata::borrow_mut<VecMap<String,String>>(&mut outlaw.id, ascii::string(b"attributes"), &auth);
        vec_map::insert(attributes, key, value);
    }

    public entry fun remove_attribute(outlaw: &mut Outlaw, key: String, ctx: &mut TxContext) {
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));
        let attributes = metadata::borrow_mut<VecMap<String,String>>(&mut outlaw.id, ascii::string(b"attributes"), &auth);
        vec_map::remove(attributes, &key);
    }

    public entry fun increment_power_level(outlaw: &mut Outlaw, ctx: &mut TxContext) {
        let slot = ascii::string(b"power_level");
        let auth = tx_authority::add_type_capability(&Witness { }, &tx_authority::begin(ctx));

        let power_level = metadata::borrow_mut<u64>(&mut outlaw.id, slot, &auth);

        *power_level = *power_level + 1;
    }
}