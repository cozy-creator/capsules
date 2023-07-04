// This illustrates the use of a custom factory to build metadata randomly

module outlaw_sky::demo_factory {
    use std::string::{Self, String};
    use std::vector;

    use sui::dynamic_field;
    use sui::url::{Self, Url};
    use sui::object::{Self, UID, ID};
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;

    use sui_utils::string2;
    use sui_utils::rand;

    // All of these are metadata properites and do not belong on this struct, but we include them here
    // anyway because the sui-explorer is built to read them (lol)
    struct Outlaw has key {
        id: UID,
        name: String,
        description: String,
        url: Url
    }

    // We should simplify this to a VecMap of attributes
    // struct OutlawMetadata has store, copy, drop {
    //     background: String,
    //     body: String,
    //     eyes: String,
    //     hair: String,
    //     inner_clothing: String,
    //     mouth: String,
    //     outer_dress: String,
    //     weapon: String,
    //     url: String
    // }

    struct OutlawMetadata has store, copy, drop {
        attributes: VecMap<String, String>,
        url: String
    }

    // Event
    struct MetadataUpdated has copy, drop {
        for: ID,
        metadata: OutlawMetadata
    }

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

    public fun select_random(item_list: vector<vector<u8>>, ctx: &mut TxContext): String {
        let num = rand::rng(0, vector::length(&item_list), ctx);
        string::utf8(*vector::borrow(&item_list, num))
    }
}