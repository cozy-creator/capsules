module composable_game::exportable {

    const ENO_IMPORT_PERMISSION: u64 = 0;
    const ENO_EXPORT_PERMISSION: u64 = 1;

    struct Character has store {
        id: UID,
        name: String,
        level: u64
    }

    struct Capsule<T> has key {
        id: UID,
        contents: option<T>
    }

    // Module authority
    struct Witness {}

    // permission objects
    struct IMPORT {}
    struct EXPORT {}
    struct EDIT {}

    // Event object
    struct ChracterImported has copy, drop {
        id: ID,
        owner: address,
        name: String,
        level: u64
    }

    public fun import_from_sui(capsule: &mut Capsule<Character>, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<IMPORT>(&capsule.id, auth), ENO_IMPORT_PERMISSION);

        let Character { id, name, level } = option::extract(&mut capsule.contents);

        // TO DO: mark the capsule as deleted since we can't actually delete it

        // Lets our server know that a Character needs to be imported
        let owner = option::destroy_some(ownership::get_owner(&capsule.id));
        event::emit(CharacterImported { id: object::uid_to_inner(&id), owner, name, level });
        object::delete(id);
    }

    // TO DO: does the person own the capsule, or the object inside the capsule?
    // I would think the contents, not the capsule itself
    public fun export_into_sui(
        owner: address,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        assert!(namespace::has_permission<EXPORT>(auth), ENO_EXPORT_PERMISSION);

        let name = data::peel_string(utf8(b"name"), &mut data, &mut fields, utf8(b"None"));
        let level = data::peel_u64(utf8(b"level"), &mut data, &mut fields, 0);

        let character = Character { id: object::new(ctx), name, level };

        // TO DO: capsule pattern can be simplified here
        let capsule = Capsule {
            id: object::new(ctx),
            contents: option::some(character)
        };

        let typed_id = typed_id::new(&capsule);
        auth = tx_authority::add_type(&Witness {}, auth);
        ownership::as_shared_object<Capsule<Character>>, SimpleTransfer>(&mut capsule.id, typed_id, owner, auth);
        transfer::share_object(capsule);
    }

    // client endpoint
    public fun edit_name(capsule: &mut Capsule<Character>, new_name: String, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<EDIT>(&capsule.id, auth), ENO_EDIT_PERMISSION);

        let character = option::borrow_mut(&mut capsule.contents);
        *character.name = new_name;
    }

    // server endpoint
    public fun level_up(capsule: &mut Capsule<Character>, auth: &TxAuthority) {
        assert!(namespace::has_permission<EDIT>(auth), ENO_EDIT_PERMISSION);

        let character = option::borrow_mut(&mut capsule.contents);
        *character.level = *character.level + 1;
    }
}