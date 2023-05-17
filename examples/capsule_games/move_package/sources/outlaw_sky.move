// Note that when an Outlaw asset is created, we do not return the Outlaw object or make it
// inspectable in the same transaction. This is so that the caller cannot inspect it,
// determine it if it has the attributes it wants or not, and then abort if it doesn't.
// This would be cheating the randomness-mechanic.

module games::outlaw_sky {
    // use sui::ecdsa_r1;
    use sui::ed25519;

    struct Outlaw has key {
        id: UID
    }

    // Pull Info struct; `pull_info` must conform to this shape for a tx to succeed.
    // id: ID (32 bytes)
    // premium: bool (1 byte)
    // fixed-traits: vector<u8> (variable length)

    // Events
    struct OutlawUpdated has copy, drop {
        id: ID,
        attributes: VecMap<String, String>
    }

    // permission objects
    struct EDIT {}

    const URL_TEMPLATE: vector<u8> = b"https://files.outlaw-sky.com/";

    const INVENTORY: vector<vector<vector<u8>>> = vector[
        vector[ b"aqua", b"red", b"teal"], // background
        vector[ b"male"], // body
        vector[ b"Closed", b"Dead Stare", b"Red Serious"], // eyes
        vector[ b"Angeal", b"Spike", b"Wavey"], // hair
        vector[ b"Bodysuit", b"Bulletproof Vest", b"Cutoff"],// inner_clothing
        vector[ b"Grin", b"Hmm", b"Toothpick"], // mouth
        vector[ b"Fire Parka", b"Tactical Mech Suit", b"Winter Parka"], // outer_dress
        vector[ b"Mechanical Scythe", b"ODM Sword Titan Killer", b"Red Samurai"] // weapon
    ];

    // There is no way to enumerate over a struct's fields in Move, so we have to manually list them here
    // There is also no way to do some dynamic-field access, like struct[string] = value
    const LIST_OF_ATTRIBUTES: vector<vector<u8>> = vector[ b"background", b"body", b"eyes", b"hair", b"inner_clothing", b"mouth", b"outer_dress", b"weapon"];

    public entry fun create(ctx: &mut TxContext) {
        let outlaw = create_(ctx);
        transfer::transfer(outlaw, tx_context::sender(ctx));
    }

    public fun create_(ctx: &mut TxContext): Outlaw {
        let (i, attributes) = (0, vec_map::empty<String, String>());
        while (i < vector::length(&LIST_OF_ATTRIBUTES)) {
            let attribute = string::utf8(*vector::borrow(&LIST_OF_ATTRIBUTES, i));
            let value = select_random(*vector::borrow(&INVENTORY, i), ctx);
            vec_map::insert(&mut attributes, attribute, value);
            i = i + 1;
        };

        let id = object::new(ctx);

        let url = string::utf8(URL_TEMPLATE);
        string::append(&mut url, string2::from_id(object::uid_to_inner(&id)));
        string::append_utf8(&mut url, b".png");

        let metadata = OutlawMetadata { attributes, url };
        dynamic_field::add(&mut id, b"metadata", metadata);

        event::emit(MetadataUpdated {
            for: object::uid_to_inner(&id),
            metadata
        });

        Outlaw {
            id,
            name: string::utf8(b"Outlaw"),
            description: string::utf8(b"Demo for Sui Builder house Denver, 2023"),
            url: url::new_unsafe(string::to_ascii(url))
        }
    }

    // view functions must be public for a client to call it via devInspect.
    // This is better than the other view function because it gets serialized automatically with
    // useless prepended length bytes
    public fun view(outlaw: &Outlaw): &OutlawMetadata {
        dynamic_field::borrow<vector<u8>, OutlawMetadata>(&outlaw.id, b"metadata")
    }


    // TO DO: how do we verify that a user's LootTable is the right one?
    // How do we turn this into a client-side endpoint?

    // Server endpoint, no need to validate pull_info
    // Because this is a server-endpoint, we assume the server has selected the current LootTable
    public fun create(owner: address, pull_info: vector<u8>, inventory: &Inventory, auth: &TxAuthority, ctx: &mut TxContext) {
        assert!(server::has_namespace_permission<Outlaw, EDIT>(auth), ENO_SERVER_PERMISSION);

        let outlaw = Outlaw { 
            id: object::new(ctx) 
        };
        let typed_id = typed_id::new(&outlaw);
        auth = tx_authority::add_type(&Witness {}, auth);
        ownership::as_shared_object<Outlaw, SimpleTransfer>(&mut outlaw.id, typed_id, owner, &auth);

        // We have two drop-tables: premium (1) and regular (0)
        let table = if (deserialize::boolean(&pull_info, 1)) { 1 } else { 0 };
        let attributes = select_attributes(inventory, table);
        let namespace = option::some(??????);
        data::set_(&mut outlaw.id, namespace, vector[utf8(b"attributes")], vector[attributes], auth);

        event::emit(OutlawUpdated {
            id: object::id(&outlaw),
            attributes
        });

        transfer::share_object(outlaw);
    }

    
    
    public entry fun regenerate(
        outlaw: &mut Outlaw,
        pull_info: vector<u8>,
        signature: vector<u8>,
        auth: &TxAuthority
    ) {
        assert!(server::has_namespace_permission<Outlaw, EDIT>(auth), ENO_SERVER_PERMISSION);
        assert!(client::has_owner_permission<EDIT>(&outlaw.id, auth), ENO_OWNER_PERMISSION);
    }

    public fun destroy_temp(outlaw: &mut Outlaw) {

    }

    public entry fun destroy(outlaw: Outlaw) {

    }

    public fun verify_signature(message: vector<u8>, signature: vector<u8>, public_key: address): bool {
        // Check hash
        ecdsa_r1::secp256t1_verify(signature, public_key, message, 0u8);
    }

    public fun check_signature(message: vector<u8>, signature: vector<u8>, public_key: vector<u8>): bool {
        ed25519::ed25519_verify(&signature, &public_key, &message)
    }
}