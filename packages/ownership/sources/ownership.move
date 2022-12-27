module ownership::ownership {
    use std::option::{Self, Option};
    use std::string::String;
    use sui::object::{Self, ID, UID};
    use sui::dynamic_field;
    use sui::tx_context::{Self, TxContext};
    use capsule::module_authority;
    use sui_utils::encode;
    use sui_utils::df_set;

    // error enums
    const ECREATOR_ALREADY_SET: u64 = 0;
    const ENO_MODULE_AUTHORITY: u64 = 0;
    const ENOT_OWNER: u64 = 1;
    const EOWNER_ALREADY_SET: u64 = 2;
    const ENO_TRANSFER_AUTHORITY: u64 = 3;
    const EMISMATCHED_HOT_POTATO: u64 = 4;

    struct Key has store, copy, drop { slot: u8 } // value is an Authority

    // Slots for Key
    const OWNER: u8 = 0; // Can open the Capsule, add/remove to delegates. Address for a pubkey / object-id, or witness-type string
    const TRANSFER: u8 = 1; // Can edit Owner field, which wipes delegates. Address for a pubkey / object-id, or witness-type string
    const CREATOR: u8 = 2; // Creator consent is needed to edit Metadata, Data, and Inventory. Address for pubkey / object-id
    const CREATOR_WITNESS: u8 = 3; // Same as above, but a witness-type string

    // Used to borrow and return ownership. capsule_id ensures you cannot mismatch HotPotato's
    // and capsules, and obj_addr is the address of the original authority object
    struct HotPotato { 
        capsule_id: ID, 
        original_addr: Option<address> 
    }

    // ======= Creator Authority =======
    // If creator authority is left blank, then anyone can claim it

    public fun bind_creator(id: &mut UID, addr: address) {
        assert!(!dynamic_field::exists_(id, Key { slot: CREATOR }), ECREATOR_ALREADY_SET);

        dynamic_field::add(id, Key { slot: CREATOR }, addr);
    }

    public fun bind_creator_witness(id: &mut UID, addr: address) {
        assert!(!dynamic_field::exists_(id, Key { slot: CREATOR }), ECREATOR_ALREADY_SET);

        dynamic_field::add(id, Key { slot: CREATOR }, addr);
    }

    // Change with signer authority
    public fun change_creator(id: &mut UID, new_addr: address, ctx: &TxContext) {
        assert!(is_valid_creator(id, tx_context::sender(ctx)), ECREATOR_ALREADY_SET);

        df_set::set(id, Key { slot: CREATOR }, new_addr);
    }

    // Change with authority object
    public fun change_creator_<T: key>(id: &mut UID, new_addr: address, obj: &T) {
        assert!(is_valid_creator(id, object::id_address(obj)), ECREATOR_ALREADY_SET);

        df_set::set(id, Key { slot: CREATOR }, new_addr);
    }

    // ======= Transfer Authority =======

    // ======= Ownership Authority =======
    // Binding requires (1) creator consent, and (2) that an owner does not already exist

        ownership::bind_creator_(&mut creator.id, id_bytes);
        ownership::bind_transfer_witness<Self>(&mut creator.id, id_bytes);
        ownership::bind_owner_(&mut creator.id, id_bytes, &creator_cap);

    // Wish I didn't have to multiply this interface with 6 functions, but these were needed to support
    // all the possible auth-types (3; signer, object, witness) and value-types (2; address or string)
    public fun bind_owner(id: &mut UID, owner: address, ctx: &TxContext) {
        assert!(is_valid_creator(id, tx_context::sender(ctx)), ENO_CREATOR_AUTHORITY);

        bind_owner_internal(id, owner);
    }

    public fun bind_owner_<T: key>(id: &mut UID, owner: address, obj: &T) {
        assert!(is_valid_creator(id, object::id_address(obj)), ENO_CREATOR_AUTHORITY);

        bind_owner_internal(id, owner);
    }

    public fun bind_owner__<Creator: drop>(id: &mut UID, owner: address, _creator: Creator) {
        assert!(is_valid_creator__<Creator>(id), ENO_CREATOR_AUTHORITY);

        bind_owner_internal(id, owner);
    }

    public fun bind_owner_witness<Witness: drop>(id: &mut UID, ctx: &TxContext) {
        assert!(is_valid_creator(id, tx_context::sender(ctx)), ENO_CREATOR_AUTHORITY);

        bind_owner_internal_<Witness>(id);
    }

    public fun bind_owner_witness_<T: key, Witness: drop>(id: &mut UID, obj: &T) {
        assert!(is_valid_creator(id, object::id_address(obj)), ENO_CREATOR_AUTHORITY);

        bind_owner_internal_<Witness>(id);
    }

    public fun bind_owner__<Creator: drop, Witness: drop>(id: &mut UID, _creator: Creator) {
        assert!(is_valid_creator__<Creator>(id), ENO_CREATOR_AUTHORITY);

        bind_owner_internal_<Witness>(id);
    }

    fun bind_owner_internal(id: &mut UID, owner: address) {
        let key = Key { slot: OWNER };
        assert!(!dynamic_field::exists_(id, key), EOWNER_ALREADY_SET);

        dynamic_field::add(id, key, owner);
    }

    fun bind_owner_internal_<Witness: drop>(id: &mut UID, owner: String) {
        let key = Key { slot: OWNER };
        assert!(!dynamic_field::exists_(id, key), EOWNER_ALREADY_SET);

        dynamic_field::add(id, key, type_name::encode<Witness>());
    }

    // Bind ownership to an arbitrary address
    // Requires module authority. Only works if no owner is currently set
    public fun bind_owner<World: drop>(id: &mut UID, addr: address): World {
        assert!(module_authority::is_valid<World>(id), ENO_MODULE_AUTHORITY);
        assert!(!dynamic_field::exists_(id, Key { slot: OWNER }), EOWNER_ALREADY_SET);

        dynamic_field::add(id, Key { slot: OWNER }, addr);

        witness
    }

    // Bind ownership to an arbitrary authority object
    public fun bind_owner_<World: drop, Object: key>(witness: World, id: &mut UID, auth: &Object): World {
        bind_owner(witness, id, object::id_address(auth))
    }

    // Takes a capsule id, and if the authority object is valid, it changes the owner to be the
    // sender of this transaction. Returns a hot potato to make sure the ownership is set back to
    // the original authority object by calling `return_ownership()`
    public fun borrow_ownership<Object: key>(id: &mut UID, auth: &Object, ctx: &TxContext): HotPotato {
        assert!(is_valid_owner_(id, auth), ENOT_OWNER);

        let key = Key { slot: OWNER };

        let original_addr = if (dynamic_field::exists_(id, key)) {
            option::some(dynamic_field::remove<Key, address>(id, key))
        } else { 
            option::none()
        };

        dynamic_field::add(id, key, tx_context::sender(ctx));

        HotPotato { 
            capsule_id: object::uid_to_inner(id),
            original_addr
        }
    }

    public fun return_ownership(id: &mut UID, hot_potato: HotPotato) {
        let HotPotato { capsule_id, original_addr } = hot_potato;

        assert!(object::uid_to_inner(id) == capsule_id, EMISMATCHED_HOT_POTATO);

        if (option::is_some(&original_addr)) {
            let addr = option::destroy_some(original_addr);
            *dynamic_field::borrow_mut<Key, address>(id, Key { slot: OWNER }) = addr;
        } else {
            dynamic_field::remove<Key, address>(id, Key { slot: OWNER});
        };
    }

    public fun into_owner_address(id: &UID): Option<address> {
        if (dynamic_field::exists_(id, Key { slot: OWNER })) {
            option::some(*dynamic_field::borrow(id, Key { slot: OWNER}))
        } else {
            option::none()
        }
    }

    public fun is_valid_owner(id: &UID, addr: address): bool {
        if (!dynamic_field::exists_(id, Key { slot: OWNER})) { 
            return true 
        };

        addr == *dynamic_field::borrow<Key, address>(id, Key { slot: OWNER })
    }

    public fun is_valid_owner_<Object: key>(id: &UID, auth: &Object): bool {
        let addr = object::id_address(auth);
        is_valid_owner(id, addr)
    }

    // ======= Transfer Authority =======

    // Requires module authority.
    // Requires owner authority if a transfer authority is already set
    public fun bind_transfer_authority<World: drop, Transfer: drop>(
        witness: World,
        id: &mut UID,
        ctx: &TxContext
    ): World {
        let witness = unbind_transfer_authority(witness, id, ctx);
        let transfer_witness = encode::type_name<Transfer>();

        dynamic_field::add(id, Key { slot: TRANSFER }, transfer_witness);

        witness
    }

    // Requires both module and owner authority
    public fun unbind_transfer_authority<World: drop>(
        witness: World,
        id: &mut UID,
        ctx: &TxContext
    ): World {
        assert!(module_authority::is_valid<World>(id), ENO_MODULE_AUTHORITY);

        if (dynamic_field::exists_with_type<Key, String>(id, Key { slot: TRANSFER })) {
            assert!(is_valid_owner(id, tx_context::sender(ctx)), ENOT_OWNER);

            dynamic_field::remove<Key, String>(id, Key { slot: TRANSFER });
        };

        witness
    }

    public fun into_transfer_type(id: &UID): Option<String> {
        let key = Key { slot: TRANSFER };

        if (dynamic_field::exists_with_type<Key, String>(id, key)) {
            option::some(*dynamic_field::borrow<Key, String>(id, key))
        }
        else {
           option::none()
        }
    }

    // If there is no transfer module set, then transfers are not allowed
    public fun is_valid_transfer_authority<Transfer: drop>(id: &UID): bool {
        let key = Key { slot: TRANSFER };

        if (!dynamic_field::exists_with_type<Key, String>(id, key)) {
            false 
        } else {
            encode::type_name<Transfer>() == *dynamic_field::borrow<Key, String>(id, key)
        }
    }

    // Requires transfer authority.
    // Does NOT require ownership authority or module authority; meaning the delegated transfer module
    // can transfer arbitrarily, without the owner being the sender of the transaction. This is useful for
    // marketplace sales, reclaimers, and collateral-repossession
    public fun transfer<Transfer: drop>(witness: Transfer, id: &mut UID, new_owner: address): Transfer {
        assert!(is_valid_transfer_authority<Transfer>(id), ENO_TRANSFER_AUTHORITY);

        let owner = dynamic_field::borrow_mut<Key, address>(id, Key { slot: OWNER });
        *owner = new_owner;

        witness
    }

    // Bytes could be an address, an object ID, or a utf8 witness string. We abort if none of these match
    fun set_internal<Key: store + copy + drop>(id: &mut UID, key: Key, bytes: vector<u8>) {
        
    }

    // ========== Authority Checker Functions =========

    public fun is_valid_creator(): bool {}

    public fun is_valid_creator__<Witness: drop>(): bool {}
}