module composable_game::aircraft_carrier {
    use sui_utils::vec_set2::{Self, VecSet2};

    const ENO_SERVER_AUTH: u64 = 0;
    const ENOT_OWNER: u64 = 1;

    // Shared, root-level object. Owned by the player. Can be extended
    struct Carrier has key {
        id: UID,
        name: String
    }

    // Shared, root-level object. Owned by the game-master
    struct Config has key {
        id: UID,
        schema: Schema
        // servers: VecSet2<address>
    }

    // Authority object
    struct Witness has drop {}

    // Static compiled schema
    const CARRIER_SCHEMA: vector<vector<vector<u8>>> = vector[
        vector[b"name", b"String"],
        vector[b"serial_number", b"String"],
        vector[b"class", b"String"],
        vector[b"displacement", b"u32"],
        vector[b"length", b"u16"],
        vector[b"beam", b"Option<u8>"],
        vector[b"draft", b"Option<u8>"],
        vector[b"speed", b"Option<u8>"]
    ];

    // Convenience entry function
    public entry fun create(
        data: vector<vector<u8>>,
        schema_fields: vector<vector<String>>,
        owner: address,
        config: &Config,
        ctx: &mut TxContext
    ) {
            public fun deserialize_and_set<Namespace>(
        uid: &mut UID,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {

        data::deserialize_and_set<Witness>(&mut carrier.id, data, schema_fields, auth);

        let schema = schema::create(schema_fields);
        let carrier = create_(data, schema, owner, config, ctx);
        transfer::share_object(carrier);
    }

    // A fixed schema is stored in the config object; the data supplied must conform to this shape
    public entry fun create_fixed_schema(
        data: vector<vector<u8>>,
        owner: address,
        config: &Config,
        ctx: &mut TxContext
    ) {
        let carrier = create_(data, config.schema, owner, config, ctx);
        transfer::share_object(carrier);
    }

    public fun create_(
        data: vector<vector<u8>>,
        schema: Schema,
        owner: address,
        config: &Config,
        ctx: &mut TxContext
    ): Carrier {
        let server = tx_context::sender(ctx);
        assert!(ownership::is_authorized_to_create(&server, &config.id), ENO_SERVER_AUTH);

        let schema = schema::create(schema_fields);
        let name = data::remove<String>(utf8(b"name"), &mut data, &mut schema, utf8(b"None"));

        let carrier = Carrier { 
            id: object::new(ctx), 
            name 
        };

        let typed_id = typed_id::new(&outlaw);
        let auth = tx_authority::begin_with_type(&Witness {});

        ownership::as_shared_object<SimplerTransfer>(&mut carrier.id, vector[owner], typed_id, &auth)
        data::attach_<Witness>(&mut carrier.id, data, schema, &auth);

        carrier
    }

    fun init(ctx: &mut TxContext) {
        let schema = schema::create_(CARRIER_SCHEMA);

        let config = Config {
            id: object::new(ctx),
            schema: schema
            // servers: vec_set2::empty()
        };
        
        ownership::as_shared_object<SimpleTransfer>(
            &mut config.id,
            vector[tx_context::sender(ctx)],
            typed_id::new(&config),
            &tx_authority::begin_with_type(&Witness {})
        );

        transfer::share_object(config);
    }

    // ==== Config Management ====

    // public entry fun modify_servers(
    //     &mut config,
    //     add_list: vector<address>,
    //     remove_list: vector<address>,
    //     ctx: &mut TxContext
    // ) {
    //     let auth = tx_authority::begin(ctx);
    //     modify_servers_(config, add_list, remove_list, &auth);
    // }

    // public fun modify_servers_(
    //     config: &mut Config,
    //     add_list: vector<address>,
    //     remove_list: vector<address>,
    //     auth: &TxAuthority
    // ) {
    //     assert!(ownership::is_authorized_by_owner(&config.id, auth), ENOT_OWNER);

    //     let (i, len) = (0, vector::length(&add_list));
    //     while (i < len) {
    //         vec_set2::add(&mut config.servers, *vector::borrow(&add_list, i));
    //         i = i + 1;
    //     };

    //     let (i, len) = (0, vector::length(&remove_list));
    //     while (i < len) {
    //         vec_set2::remove(&mut config.servers, *vector::borrow(&remove_list, i));
    //         i = i + 1;
    //     };
    // }

    // ==== Extend Pattern ====

    public fun carrier_uid(carrier: &Carrier): &UID {
        &carrier.id
    }

    public fun carrier_uid_mut(carrier: &mut Carrier, auth: &TxAuthority): &mut UID {
        assert!(ownership::is_authorized_by_owner_data(&carrier.id, auth), ENOT_OWNER);

        &mut carrier.id
    }
}