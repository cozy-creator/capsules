module vault::vault {
    use std::vector;
    use std::ascii;
    use std::type_name;

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::dynamic_object_field as dof;

    use metadata::publish_receipt;

    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::simple_transfer::Witness as SimpleTransferWitness;

    struct Vault has key {
        id: UID
    }

    struct VAULT has drop { }

    const ENOT_VAULT_OWNER: u64 = 0;
    const EINVALID_KEY: u64 = 1;

    fun init(witness: VAULT, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&witness, ctx);
        transfer::transfer(receipt, tx_context::sender(ctx));
    }

    public entry fun create_vault(ctx: &mut TxContext) {
        let vault = Vault { id: object::new(ctx) };

        let proof = ownership::setup(&vault);
        let auth = tx_authority::begin(ctx);

        ownership::initialize(&mut vault.id, proof, &auth);
        ownership::initialize_owner_and_transfer_authority<SimpleTransferWitness>(&mut vault.id, tx_context::sender(ctx), &auth);

        transfer::share_object(vault);
    }

    public entry fun deposit_coin<T>(vault: &mut Vault, coins: vector<Coin<T>>, amount: u64, ctx: &mut TxContext) {
        let (i, len) = (0, vector::length(&coins));
        let coin = vector::pop_back(&mut coins);
        
        while(i < len) {
            coin::join(&mut coin, vector::pop_back(&mut coins));
            i = i + 1;
        };
        vector::destroy_empty(coins);

        let payment = coin::split(&mut coin, amount, ctx);

        let type_name = type_name::into_string(type_name::get<T>());
        let key = ascii::into_bytes(type_name);

        if(dof::exists_with_type<vector<u8>, Coin<T>>(&vault.id, key)) {
            let existing_coin = dof::borrow_mut<vector<u8>, Coin<T>>(&mut vault.id, key);
            coin::join(existing_coin, payment);
        } else {
            dof::add<vector<u8>, Coin<T>>(&mut vault.id, key, payment);
        };

        transfer::transfer(coin, tx_context::sender(ctx));
    }

    public entry fun transfer_coin<T>(vault: &mut Vault, amount: u64, recipient: address, ctx: &mut TxContext) {
        assert!(ownership::is_authorized_by_owner(&vault.id, &tx_authority::begin(ctx)), ENOT_VAULT_OWNER);

        let type_name = type_name::into_string(type_name::get<T>());
        let key = ascii::into_bytes(type_name);
        assert!(dof::exists_with_type<vector<u8>, Coin<T>>(&vault.id, key), EINVALID_KEY);

        let coin = dof::borrow_mut<vector<u8>, Coin<T>>(&mut vault.id, key);
        let split = coin::split(coin, amount, ctx);

        if(coin::value(coin) == 0) {
            coin::destroy_zero(dof::remove<vector<u8>, Coin<T>>(&mut vault.id, key));
        };

        transfer::transfer(split, recipient);
    }

    public entry fun deposit_object<O: key + store>(vault: &mut Vault, object: O, _ctx: &mut TxContext) {
        let object_id = object::id(&object);
        dof::add<ID, O>(&mut vault.id, object_id, object);
    }

    public entry fun transfer_object<O: key + store>(vault: &mut Vault, object_id: address, recipient: address, ctx: &mut TxContext) {
        assert!(ownership::is_authorized_by_owner(&vault.id, &tx_authority::begin(ctx)), ENOT_VAULT_OWNER);

        let key = object::id_from_address(object_id);
        assert!(dof::exists_with_type<ID, O>(&vault.id, key), EINVALID_KEY);

        let object = dof::remove<ID, O>(&mut vault.id, key);
        transfer::transfer(object, recipient);
    }
}