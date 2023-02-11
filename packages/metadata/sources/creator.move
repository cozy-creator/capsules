module metadata::creator {
    use std::ascii::String;
    use std::vector;

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;

    use metadata::publish_receipt::{Self, PublishReceipt};
    use metadata::metadata;
    use metadata::schema::Schema;
    
    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::simple_transfer::Witness;

    use sui_utils::ascii2;

    // Error enums
    const EBAD_WITNESS: u64 = 0;
    const ECREATOR_ALREADY_DEFINED: u64 = 1;
    const ESENDER_UNAUTHORIZED: u64 = 2;

    struct Creator has key, store {
        id: UID,
        packages: vector<ID>
    }
    
    struct Key has store, copy, drop { 
        slot: String
    }

    public fun define(schema: &Schema, data: vector<vector<u8>>, ctx: &mut TxContext) {
        let creator = Creator { 
            id: object::new(ctx),
            packages: vector::empty()
        };

        setup_ownership_and_metadata(&mut creator, schema, data, ctx);
        transfer::share_object(creator);
    }

    fun setup_ownership_and_metadata(creator: &mut Creator, schema: &Schema, data: vector<vector<u8>>, ctx: &mut TxContext) {
        let proof = ownership::setup(creator);
        let auth = tx_authority::begin(ctx);

        ownership::initialize(&mut creator.id, proof, &auth);
        metadata::define(&mut creator.id, schema, data, &auth);
        ownership::initialize_owner_and_transfer_authority<Witness>(&mut creator.id, tx_context::sender(ctx), &auth);
    }

    fun key(receipt: &PublishReceipt): Key {
        let id_address = object::id_to_address(&publish_receipt::into_package_id(receipt));

        Key { 
            slot: ascii2::addr_into_string(&id_address) 
        }
    }
}