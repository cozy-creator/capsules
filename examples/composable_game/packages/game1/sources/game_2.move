module composable_game::aircraft {
    // Owned object. Owned by a player. Stackable
    struct Aircraft has key, store {
        id: UID,
        quantity: u64
    }

    // Shared, root-level object. Owned by the game-master
    struct Config has key {
        id: UID,
        schema: Schema,
        servers: VecSet2<address>
    }

    struct Witness has drop {}

    // Convenience entry function
    public entry fun create(
        data: vector<vector<u8>>,
        schema_fields: vector<vector<String>>,
        owner: address,
        config: Config,
        ctx: &mut TxContext
    ) {
        let schema = schema::create(schema_fields);
        let aircraft = create_(data, schema, config, ctx);
        transfer::transfer(aircraft, owner);
    }

    public fun create_(
        data: vector<vector<u8>>,
        schema: Schema,
        config: &Config,
        ctx: &mut TxContext
    ): Aircraft {
        let server = tx_context::sender(ctx);
        assert!(ownership::is_authorized_to_create(&server, &config.id), ENO_SERVER_AUTH);

        let aircraft = Aircraft { id: object::new(ctx) };

        let auth = tx_authority::begin_with_type(&Witness {});
        data::attach_<Witness>(&mut aircraft.id, data, schema, &auth);

        aircraft
    }

    // The sender of this tx must own the aircraft (sui-level) and the carrier (shared-level)
    public entry fun store_aircraft(aircraft: Aircraft, carrier: &mut Carrier, ctx: &mut TxContext) {
        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        let uid = aircraft_carrier::carrier_uid_mut(carrier, &auth);

        let capacity = data::borrow_mut_fill<Witness, u64>(uid, utf8(b"capacity"), 45, &auth);
        let stored_aircraft = inventory::borrow<Witness, Aircraft>(uid);

        if (vector::length(stored_aircraft) < *capacity) {
            inventory::add<Witness, Aircraft>(uid, aircraft, &auth);
        } else {
            // Carrier is over capacity; return the plane to sender
            transfer::transfer(aircraft, tx_context::sender(ctx));
        };
    }

    // The sender of this tx must own the carrier (shared-level)
    // Aborts if there is not at least one aircraft in the carrier
    public fun remove_aircraft(carrier: &mut Carrier, ctx: &TxContext): Aircraft {
        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        let uid = aircraft_carrier::carrier_uid_mut(carrier, &auth);

        inventory::remove<Witness, Aircraft>(uid, &auth)
    }

    // The sender of this tx must be a game-server, and also must be authorized by the carrier's owner
    // to edit it
    public entry fun change_capacity(carrier: &mut Carrier, new_capacity: u64, config: &Config, ctx: &mut TxContext) {
        let server = tx_context::sender(ctx);
        assert!(ownership::is_authorized_to_edit(&server, &config.id), ENO_SERVER_AUTH);

        let auth = tx_authority::add_type(&Witness {}, &tx_authority::begin(ctx));
        let uid = aircraft_carrier::carrier_uid_mut(carrier, &auth);

        *data::borrow_or_fill<Witness, u64>(uid, utf8(b"capacity"), 0, &auth) = new_capacity;
        // data::set<Witness, u64>(uid, utf8(b"capacity"), new_capacity, &auth);
    }
}