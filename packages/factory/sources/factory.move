module factory::factory {
    use std::ascii;
    use std::vector;
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::url::{Self, Url};
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;

    use sui_utils::rand;

    struct Factory<phantom T> has key {
        id: UID,
        /// Data to be used for the metadata generation
        data: FactoryData,
        /// The factory configuration
        config: FactoryConfig
    }

    struct FactoryData has store {
        attributes: vector<vector<u8>>,
        data: vector<vector<vector<u8>>>,
        config: FactoryDataConfig
    }

    struct FactoryDataConfig has store {
        url: Url,
        name: String,
        description: String,
        url_suffix_attr: Option<vector<u8>>,
        url_extension: Option<vector<u8>>
    }

    struct FactoryConfig has store {
        schema: Option<vector<vector<u8>>>
    }

    struct DataOutput has copy, drop {
        url: Url,
        name: String,
        description: String,
        metadata: VecMap<vector<u8>, vector<u8>>
    }

    const SLASH_BYTE: vector<u8> = x"2F";

    public fun intitialize<T: drop>(
        _witness: &T,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        attributes: vector<vector<u8>>,
        data: vector<vector<vector<u8>>>,
        url_suffix_attr: Option<vector<u8>>,
        url_extension: Option<vector<u8>>,
        ctx: &mut TxContext
    ): Factory<T> {
        let data = FactoryData {
            data,
            attributes,
            config: FactoryDataConfig {
                name: string::utf8(name),
                url: url::new_unsafe_from_bytes(url),
                description: string::utf8(description),
                url_suffix_attr:  option::none() ,
                url_extension: option::none(),
            }
        };

        if(option::is_some(&url_suffix_attr)) {
           option::fill(&mut data.config.url_suffix_attr, option::extract(&mut url_suffix_attr))
        };
        
        if(option::is_some(&url_extension)) {
             option::fill(&mut data.config.url_extension, option::extract(&mut url_extension))
        };
        
        let factory = Factory<T> {
            id: object::new(ctx),
            data,
            config: FactoryConfig {
                schema: option::none()
            }
        };

        factory
    }

    public fun generate<T>(self: &Factory<T>, _witness: &T, ctx: &mut TxContext): DataOutput {
        let (i, len) = (0, vector::length(&self.data.attributes));

        let url_bytes = ascii::into_bytes(url::inner_url(&self.data.config.url));
        let metadata = vec_map::empty<vector<u8>, vector<u8>>();

        while(i < len) {
            let attribute = *vector::borrow(&self.data.attributes, i);
            let attribute_data = vector::borrow(&self.data.data, i);

            let data_length = vector::length(attribute_data);

            let rand = rand::rng(0, data_length, ctx);
            let selected_data = *vector::borrow(attribute_data, rand);

            if(option::is_some(&self.data.config.url_suffix_attr)) {
                if(&attribute == option::borrow(&self.data.config.url_suffix_attr)) {
                    vector::append(&mut url_bytes, selected_data)
                }
            };

            vec_map::insert(&mut metadata, attribute, selected_data);

            i = i + 1;
        };

        if(option::is_some(&self.data.config.url_extension)) {
            vector::append(&mut url_bytes, *option::borrow(&self.data.config.url_extension))
        };

         DataOutput {
            name: self.data.config.name,
            description: self.data.config.description,
            url: url::new_unsafe_from_bytes(url_bytes),
            metadata
        }
    }

    public fun publish<T>(self: Factory<T>) {
        transfer::share_object(self)
    }

    public fun metadata(data: &DataOutput): VecMap<vector<u8>, vector<u8>> {
        data.metadata
    }
}

#[test_only]
module factory::factory_test {
    use std::option;
    use std::vector;
    use std::string;

    use sui::test_scenario::{Self, Scenario};
    use sui::vec_map;

    use factory::factory::{Self, Factory};

    struct Witness has drop {}

    const DATA: vector<vector<vector<u8>>> = vector[
        vector[b"cvgdteg", b"eh74ygd", b"eu476tdg", b"42thjid8", b"087gsfs5w6h", b"0uehdyedy"], // id
        vector[b"aqua", b"red", b"teal"], // background
        vector[b"male", b"female"], // body
        vector[b"Closed", b"Dead Stare", b"Red Serious"], // eyes
        vector[b"Angeal", b"Spike", b"Wavey"], // hair
        vector[b"Bodysuit", b"Bulletproof Vest", b"Cutoff"],// inner_clothing
        vector[b"Grin", b"Hmm", b"Toothpick"], // mouth
        vector[b"Fire Parka", b"Tactical Mech Suit", b"Winter Parka"], // outer_dress
        vector[b"Mechanical Scythe", b"ODM Sword Titan Killer", b"Red Samurai"] // weapon
    ];

   const ATTRIBUTES: vector<vector<u8>> = vector[
        b"id",
        b"background",
        b"body",
        b"eyes",
        b"hair",
        b"inner_clothing",
        b"mouth",
        b"outer_dress",
        b"weapon"
    ];

    fun intitialize_scenario(sender: address): Scenario {
        let scenario = test_scenario::begin(sender);
        let ctx = test_scenario::ctx(&mut scenario);

        {
            let witness = Witness {};
            let factory = factory::intitialize(
                &witness,
                b"Outlaw",
                b"Outlaw demo example",
                b"https://someurl.com/",
                ATTRIBUTES,
                DATA,
                option::some(b"id"),
                option::some(b".png"),
                ctx
            );

            factory::publish(factory);
            test_scenario::next_tx(&mut scenario, sender);
        };

        scenario
    }

    #[test]
    fun generate_metadata() {
        let scenario = intitialize_scenario(@0xFACE);
        {
            let witness = Witness {};
            let factory = test_scenario::take_shared<Factory<Witness>>(&scenario);
            let data = factory::generate(&mut factory, &witness, test_scenario::ctx(&mut scenario));

            let (k, v) = vec_map::into_keys_values(factory::metadata(&data));

            let (i, l) = (0, vector::length(&k));
            while(i < l) {
                
                std::debug::print(&string::utf8(*vector::borrow(&k, i)));
                std::debug::print(&string::utf8(*vector::borrow(&v, i)));
                std::debug::print(&string::utf8(b"=========="));

                i = i + 1;
            };

            test_scenario::return_shared(factory);
        };

        test_scenario::end(scenario);
    }
}