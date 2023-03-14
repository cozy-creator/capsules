module glb_asset::glb_asset {
    use std::string::{String, utf8};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::typed_id;
    use sui::transfer;
    use sui::url::{Self, Url};

    use ownership::ownership;
    use ownership::tx_authority;

    use sui_utils::rand;

    // These are the items that can be returned by this module
    const INVENTORY: vector<vector<u8>> = vector[
        b"https://s3.eu-central-1.amazonaws.com/files.capsulecraft.dev/Chibi_Momo.glb",
        b"https://s3.eu-central-1.amazonaws.com/files.capsulecraft.dev/Chibi_Kyrie.glb",
        b"https://s3.eu-central-1.amazonaws.com/files.capsulecraft.dev/Fullsize_Momo.glb",
        b"https://s3.eu-central-1.amazonaws.com/files.capsulecraft.dev/Fullsize_Kyrie.glb",
        b"https://s3.eu-central-1.amazonaws.com/files.capsulecraft.dev/Fullsize_Crimson.glb",
        b"https://s3.eu-central-1.amazonaws.com/files.capsulecraft.dev/Fullsize_Fang.glb",
    ];

    const THUMBNAIL: vector<u8> = b"https://pbs.twimg.com/profile_images/1569727324081328128/7sUnJvRg_400x400.jpg";

    struct GLBAsset has key, store {
        id: UID,
        // Sui explorer recognizes these fields as the thumbnail and name of the asset
        url: Url,
        name: String,
        // We add the file url here as well for now; might make it easier to find the file url
        // But really you should be loading for the metadata dynamic field
        file_url: Url,
        // Ownership fields
        // Metadata fields
    }

    struct Witness has drop {}

    public entry fun create(ctx: &mut TxContext) {
        let file_url = select_random(INVENTORY, ctx);

        let glb_asset = GLBAsset { 
            id: object::new(ctx),
            url: url::new_unsafe_from_bytes(THUMBNAIL),
            name: utf8(b"Outlaw Sky Avatar"),
            file_url
        };
        let auth = tx_authority::begin_with_type(&Witness {});
        let typed_id = typed_id::new(&glb_asset);

        ownership::initialize_with_module_authority(&mut glb_asset.id, typed_id, &auth);

        // I'll enable this once we support urls
        // metadata::attach(&mut glb_asset.id, data, schema, &auth);

        ownership::as_owned_object(&mut glb_asset.id, &auth);

        transfer::transfer(glb_asset, tx_context::sender(ctx));
    }

    public fun select_random(item_list: vector<vector<u8>>, ctx: &mut TxContext): Url {
        let num = rand::rng(0, vector::length(&item_list), ctx);
        url::new_unsafe_from_bytes(*vector::borrow(&item_list, num))
    }
}