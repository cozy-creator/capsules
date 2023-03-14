module glb_asset::glb_asset {
    use std::option::{Self, Option};
    use std::vector;

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::typed_id;
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::dynamic_field;

    // use ownership::ownership;
    use ownership::tx_authority;

    use sui_utils::rand;
    // use sui_utils::struct_tag;

    const INVENTORY: vector<vector<u8>> = vector[
        b"https://drive.google.com/uc?export=download&id=1x5N20EiHcErylC224A7CYkXjS__hVt96"
    ];

    struct GLBAsset has key, store {
        id: UID,
        // We add the file url here as well for now; might make it easier to find the file url
        // But really you should be loading for the metadata dynamic field
        file_url: Url,
        // Ownership fields
        // Metadata fields
    }

    struct Witness has drop {}

    struct Key has store, copy, drop {}

    struct Ownership has store, copy, drop {
        module_auth: vector<address>,
        owner: vector<address>,
        transfer_auth: vector<address>,
        is_shared: Option<bool>
    }


    public entry fun create(ctx: &mut TxContext) {
        let file_url = select_random(INVENTORY, ctx);

        let glb_asset = GLBAsset { 
            id: object::new(ctx),
            file_url
        };
        let auth = tx_authority::begin_with_type(&Witness {});
        let _typed_id = typed_id::new(&glb_asset);

        // ownership::initialize_with_module_authority(&mut glb_asset.id, typed_id, &auth);

        // I'll enable this once we support urls
        // metadata::attach(&mut glb_asset.id, data, schema, &auth);

        // ownership::as_owned_object(&mut glb_asset.id, &auth);

        // let _ = struct_tag::get<GLBAsset>();

        let ownership = Ownership {
            module_auth: vector::empty(),
            owner: vector::empty(),
            transfer_auth: vector::empty(),
            // this won't be determined until we call `as_shared_object` or `as_owned_object`
            is_shared: option::none()
        };

        dynamic_field::add(&mut glb_asset.id, Key { }, ownership);

        // let _ = ownership::is_initialized(&glb_asset.id);
        // let _ = (object::uid_to_inner(&glb_asset.id) == typed_id::to_id(typed_id));
        let _ = tx_authority::is_signed_by_module<GLBAsset>(&auth);

        transfer::transfer(glb_asset, tx_context::sender(ctx));
    }

    public fun select_random(item_list: vector<vector<u8>>, ctx: &mut TxContext): Url {
        let num = rand::rng(0, vector::length(&item_list), ctx);
        url::new_unsafe_from_bytes(*vector::borrow(&item_list, num))
    }
}