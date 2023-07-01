module outlaw_sky::warship {
    use std::string::{String, utf8};

    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;

    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::ownership::{Self, INITIALIZE};
    use ownership::action::ADMIN;

    use attach::data::{Self, WRITE};

    use transfer_system::simple_transfer::SimpleTransfer;

    use sui_utils::typed_id;
    
    use outlaw_sky::outlaw_sky::CREATOR;

    struct Warship has key {
        id: UID
    }

    struct Witness has drop {}

    const ENOT_OWNER: u64 = 0;
    const ENO_PACKAGE_AUTHORITY: u64 = 1;

    public fun create(
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        owner: address,
        auth: &TxAuthority,
        ctx: &mut TxContext
    ) {
        assert!(tx_authority::can_act_as_package<Warship, CREATOR>(auth), ENO_PACKAGE_AUTHORITY);

        let auth = tx_authority::add_package_witness<Witness, INITIALIZE>(Witness {}, auth);
        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, &auth);
        let warship = Warship { id: object::new(ctx) };
        let typed_id = typed_id::new(&warship);

        ownership::as_shared_object<Warship, SimpleTransfer>(&mut warship.id, typed_id, owner, &auth);
        data::deserialize_and_set<Warship>(&mut warship.id, data, fields, &auth);
        transfer::share_object(warship);
    }

    public fun rename(warship: &mut Warship, new_name: String, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&warship.id, auth), ENOT_OWNER);

        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, auth);
        data::set<Warship, String>(&mut warship.id, vector[utf8(b"name")], vector[new_name], &auth);
    }

    public fun change_size(warship: &mut Warship, new_size: u64, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&warship.id, auth), ENOT_OWNER);

        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, auth);
        data::set<Warship, u64>(&mut warship.id, vector[utf8(b"size")], vector[new_size], &auth);
    }

    public fun change_strength(warship: &mut Warship, new_strength: u64, auth: &TxAuthority) {
        assert!(ownership::can_act_as_owner<ADMIN>(&warship.id, auth), ENOT_OWNER);

        let auth = tx_authority::add_package_witness<Witness, WRITE>(Witness {}, auth);
        data::set<Warship, u64>(&mut warship.id, vector[utf8(b"strength")], vector[new_strength], &auth);
    }
}