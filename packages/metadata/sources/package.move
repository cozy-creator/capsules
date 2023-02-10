module metadata::package {
    use std::ascii::{Self, String};

    use sui::tx_context::TxContext;
    use sui::object::{Self, UID, ID};
    use sui::dynamic_field;

    use metadata::publish_receipt::{Self, PublishReceipt};
    use metadata::creator::{Creator};
    
    use ownership::ownership;
    use ownership::tx_authority;

    use sui_utils::ascii2;

    // Error enums
    const EBAD_WITNESS: u64 = 0;
    const EPACKAGE_ALREADY_DEFINED: u64 = 1;

    struct Package has key, store {
        id: UID,
        name: String,
        creator_id: ID,
    }
    
    struct Key has store, copy, drop { 
        slot: String
    }

    public fun define<W: drop>(witness: &W, receipt: &mut PublishReceipt, creator: &Creator, _name: vector<u8>, ctx: &mut TxContext) {
        let (name) = (ascii::string(_name));

        let package = define_(creator, name, ctx);

        setup_ownership_and_capability(witness, &mut package, ctx);


        let key = get_key(receipt);
        let receipt_uid = publish_receipt::extend(receipt);

        assert!(!dynamic_field::exists_(receipt_uid, key), EPACKAGE_ALREADY_DEFINED);
        dynamic_field::add(receipt_uid, key, package);
    }

    fun define_(creator: &Creator, name: String, ctx: &mut TxContext): Package {
        let package = Package { 
            id: object::new(ctx),
            name,
            creator_id: object::id(creator)
        };

        package   
    }

    fun get_key(receipt: &PublishReceipt): Key {
        let id_address = object::id_to_address(&publish_receipt::into_package_id(receipt));

        Key { 
            slot: ascii2::addr_into_string(&id_address) 
        }
    }

    fun setup_ownership_and_capability<W: drop>(witness: &W, package: &mut Package, ctx: &mut TxContext) {
        let proof = ownership::setup(package);
        let auth = tx_authority::add_capability_type<W>(witness, &tx_authority::begin(ctx));

        ownership::initialize(&mut package.id, proof, &auth);
    }
}