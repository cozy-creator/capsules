module metadata::creator {
    use std::ascii::{Self, String};

    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::dynamic_field;
    use sui::transfer;
    use sui::types::is_one_time_witness;

    use metadata::publish_receipt::{Self, PublishReceipt};
    
    use ownership::ownership;
    use ownership::tx_authority;

    use sui_utils::ascii2;

    // Error enums
    const EBAD_WITNESS: u64 = 0;
    const ECREATOR_ALREADY_DEFINED: u64 = 1;

    struct Creator has key, store {
        id: UID,
        name: String,
        logo: String,
        description: String,
        website_url: String
    }
    
    struct Key has store, copy, drop { 
        slot: String
    }

    public fun define<W: drop>(witness: &W, receipt: &mut PublishReceipt, _name: vector<u8>, _description: vector<u8>,  _logo: vector<u8>, _website_url: vector<u8>, ctx: &mut TxContext) {
        assert!(is_one_time_witness(witness), EBAD_WITNESS);

        let (name, description, logo, website_url) = (ascii::string(_name), ascii::string(_description), ascii::string(_logo), ascii::string(_website_url));
        let creator = define_(receipt, name, description, logo, website_url, ctx);

        setup_ownership_and_capability<W>(witness, &mut creator, ctx);

        transfer::share_object(creator);
    }

    fun define_(receipt: &mut PublishReceipt, name: String, description: String, logo: String, website_url: String, ctx: &mut TxContext): Creator {
        let creator = Creator { 
            id: object::new(ctx),
            name,
            logo, 
            description,
            website_url
        };

        let key = get_key(receipt);
        let receipt_uid = publish_receipt::extend(receipt);

        assert!(!dynamic_field::exists_(receipt_uid, key), ECREATOR_ALREADY_DEFINED);
        dynamic_field::add(receipt_uid, key, true);

        creator
    }

    fun get_key(receipt: &PublishReceipt): Key {
        let id_address = object::id_to_address(&publish_receipt::into_package_id(receipt));

        Key { 
            slot: ascii2::addr_into_string(&id_address) 
        }
    }

    fun setup_ownership_and_capability<W: drop>(witness: &W, creator: &mut Creator, ctx: &mut TxContext) {
        let proof = ownership::setup(creator);
        let auth = tx_authority::add_capability_type<W>(witness, &tx_authority::begin(ctx));

        ownership::initialize(&mut creator.id, proof, &auth);
    }
}