#[test_only]
module transfer_system::royalty_market_tests {
    use std::vector;
    use std::option;

    use sui::transfer;
    use sui::sui::SUI;
    use sui::tx_context;
    use sui::object::UID;
    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self, Scenario};

    use ownership::ownership;
    use ownership::tx_authority;
    use ownership::publish_receipt::{Self, PublishReceipt};

    use transfer_system::test_utils;
    use transfer_system::market_account_tests;
    use transfer_system::royalty_market::{Self, Royalty};
    use transfer_system::capsule_baby::{Self, CapsuleBaby};
    use transfer_system::market_account::{Self, MarketAccount};
    
    struct Witness has drop {}

    struct FakeCapsuleBaby has key {
        id: UID
    }

    const BUYER_ADDR: address = @0xCAFE;
    const SELLER_ADDR: address = @0xFACE;

    fun claim_publish_receipt(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        let sender = tx_context::sender(ctx);

        let receipt = publish_receipt::test_claim(&Witness {}, ctx);
        transfer::public_transfer(receipt, sender)
    }

    fun create_royalty<T>(scenario: &mut Scenario, recipient: address, royalty_bps: u16, marketplace_bps: u16) {
        claim_publish_receipt(scenario);
        let ctx = test_scenario::ctx(scenario);
        test_scenario::next_tx(scenario, tx_context::sender(ctx));

        {
            let receipt = test_scenario::take_from_sender<PublishReceipt>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let royalty = royalty_market::create_royalty_<T>(&receipt, recipient, royalty_bps, marketplace_bps, ctx);
            transfer::public_share_object(royalty);
            test_scenario::return_to_sender(scenario, receipt)
        }
    }

    fun create_sell_offer_<T, C>(scenario: &mut Scenario, uid: &mut UID, royalty: &Royalty<T>, seller: address, price: u64) {
        let auth = tx_authority::begin(test_scenario::ctx(scenario));
        royalty_market::create_sell_offer<T, C>(uid, royalty, seller, price, &auth)
    }

    fun fill_sell_offer_<T, C>(scenario: &mut Scenario, uid: &mut UID, buyer: address, royalty: &Royalty<T>, coin: Coin<C>, marketplace: address) {
        let ctx = test_scenario::ctx(scenario);
        royalty_market::fill_sell_offer<T, C>(uid, buyer, royalty, coin, marketplace, ctx)
    }

    fun fill_buy_offer_<T, C>(scenario: &mut Scenario, uid: &mut UID, market_account: &mut MarketAccount, buyer: address, royalty: &Royalty<T>, marketplace: address) {
        let ctx = test_scenario::ctx(scenario);
        royalty_market::fill_buy_offer<T, C>(uid, market_account, buyer, royalty, marketplace, ctx)
    }

    fun create_buy_offer_<T, C>(scenario: &mut Scenario, uid: &mut UID, market_account: &mut MarketAccount, royalty: &Royalty<T>, buyer: address, price: u64) {
        let auth = tx_authority::begin(test_scenario::ctx(scenario));
        royalty_market::create_buy_offer<T, C>(uid, market_account, royalty, buyer, price, &auth)
    }

    fun create_capsule_baby(scenario: &mut Scenario) {
        capsule_baby::create(test_scenario::ctx(scenario))
    }


    // ========== Tests start ==========

    #[test]
    fun create_sell_offer() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, SELLER_ADDR);
        
        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);

            assert!(ownership::get_owner(uid) == option::some(vector[SELLER_ADDR]), 0);

            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::EOFFER_ALREADY_EXIST)]
    fun create_multiple_sell_offer_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, SELLER_ADDR);
        
        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);
            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);
            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);

            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::EITEM_TYPE_MISMATCH)]
    fun create_sell_offer_invalid_type_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<FakeCapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, SELLER_ADDR);

        {
            let royalty = test_scenario::take_shared<Royalty<FakeCapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            create_sell_offer_<FakeCapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);

            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::ENO_OWNER_AUTHORITY)]
    fun create_sell_offer_invalid_owner_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, @0xCAFE);

        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);

            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);       
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    fun fill_sell_offer() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, SELLER_ADDR);
        
        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            assert!(ownership::get_owner(uid) == option::some(vector[SELLER_ADDR]), 0);
            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);

            let (marketplace, coin) = (@0xDEED, test_utils::mint_coin<SUI>(&mut scenario, 3000000));
            test_scenario::next_tx(&mut scenario, BUYER_ADDR);

            {
                // Fill the sell offer
                fill_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, BUYER_ADDR, &royalty, coin, marketplace);
                assert!(ownership::get_owner(uid) == option::some(vector[BUYER_ADDR]), 0);
                test_scenario::next_tx(&mut scenario, BUYER_ADDR);
            };

            let seller_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let royalty_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let buyer_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, BUYER_ADDR);
            let marketplace_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, marketplace);

            // Royalty paid to the royalty recipient
            // i.e 1000 bps of 2000000 = 200000
            assert!(coin::value(&royalty_coin) == 200_000, 0);

            // Amount refunded to the buyer
            // i.e 3000000 - (2000000 + (200000 / 2))
            assert!(coin::value(&buyer_coin) == 900_000, 0);

            // Amount paid to the marketplace
            // i.e 200 bs of 2000000 = 40000
            assert!(coin::value(&marketplace_coin) == 40_000, 0);

            // final sale amount (offer_price - (total_royalty / 2) - marketplace_fee)
            // i.e 2000000 - (200000 / 2) - 40000
            assert!(coin::value(&seller_coin) == 1_860_000, 0);

            test_scenario::return_to_address(SELLER_ADDR, royalty_coin);
            test_scenario::return_to_address(SELLER_ADDR, seller_coin);
            test_scenario::return_to_address(BUYER_ADDR, buyer_coin);
            test_scenario::return_to_address(marketplace, marketplace_coin);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    fun fill_sell_offer_with_exact_payment() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, SELLER_ADDR);
        
        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);
            assert!(ownership::get_owner(uid) == option::some(vector[SELLER_ADDR]), 0);

            let (marketplace, coin) = (@0xDEED, test_utils::mint_coin<SUI>(&mut scenario, 2100000));
            test_scenario::next_tx(&mut scenario, BUYER_ADDR);

            {
                // Fill the sell offer
                fill_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, BUYER_ADDR, &royalty, coin, marketplace);
                assert!(ownership::get_owner(uid) == option::some(vector[BUYER_ADDR]), 0);
                test_scenario::next_tx(&mut scenario, BUYER_ADDR);
            };

            let seller_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let royalty_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let marketplace_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, marketplace);
            let buyer_coins = test_scenario::ids_for_address<Coin<SUI>>(BUYER_ADDR);

            // Buyer makes exact payment, so no refund and the coin object is destroyed
            assert!(vector::length(&buyer_coins) == 0, 0);

            // Royalty paid to the royalty recipient
            // i.e 1000 bps of 2000000 = 200000
            assert!(coin::value(&royalty_coin) == 200_000, 0);

            // Amount paid to the marketplace
            // i.e 200 bs of 2000000 = 40000
            assert!(coin::value(&marketplace_coin) == 40_000, 0);

            // final sale amount (offer_price - (total_royalty / 2) - marketplace_fee)
            // i.e 2000000 - (200000 / 2) - 40000
            assert!(coin::value(&seller_coin) == 1_860_000, 0);

            test_scenario::return_to_address(SELLER_ADDR, royalty_coin);
            test_scenario::return_to_address(SELLER_ADDR, seller_coin);
            test_scenario::return_to_address(marketplace, marketplace_coin);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };        

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::EINSUFFICIENT_PAYMENT)]
    fun fill_sell_offer_insufficient_payment_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, SELLER_ADDR);
        
        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            create_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &royalty, SELLER_ADDR, price);

            let (marketplace, coin) = (@0xDEED, test_utils::mint_coin<SUI>(&mut scenario, 1000000));
            test_scenario::next_tx(&mut scenario, BUYER_ADDR);

            // Fill the sell offer
            fill_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, BUYER_ADDR, &royalty, coin, marketplace);

            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::EOFFER_DOES_NOT_EXIST)]
    fun fill_sell_offer_does_not_exist_failure() {
        let (royalty_bps, marketplace_bps) =  (1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, SELLER_ADDR);

        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            let (marketplace, coin) = (@0xDEED, test_utils::mint_coin<SUI>(&mut scenario, 1000000));
            test_scenario::next_tx(&mut scenario, BUYER_ADDR);

            // Fill the sell offer
            fill_sell_offer_<CapsuleBaby, SUI>(&mut scenario, uid, BUYER_ADDR, &royalty, coin, marketplace);

            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    fun create_buy_offer() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);
        market_account_tests::create_account(&mut scenario);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);

        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            assert!(ownership::get_owner(uid) == option::some(vector[SELLER_ADDR]), 0);

            market_account::deposit<SUI>(&mut market_account, test_utils::mint_coin(&mut scenario, 20000000));
            create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);

            test_scenario::return_shared(market_account);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::EOFFER_ALREADY_EXIST)]
    fun create_multiple_single_user_buy_offer_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario,BUYER_ADDR);
        market_account_tests::create_account(&mut scenario);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);

        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            market_account::deposit<SUI>(&mut market_account, test_utils::mint_coin(&mut scenario, 20000000));
            create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);
            create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);

            test_scenario::return_shared(market_account);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    fun create_multiple_different_user_buy_offer_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);
        market_account_tests::create_account(&mut scenario);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);

        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            market_account::deposit<SUI>(&mut market_account, test_utils::mint_coin(&mut scenario, 20000000));
            create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);
            
            let other_addr = @0xFADE;
            test_scenario::next_tx(&mut scenario, other_addr);
            market_account_tests::create_account(&mut scenario);
            test_scenario::next_tx(&mut scenario, other_addr);
            {
                let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
                market_account::deposit<SUI>(&mut market_account, test_utils::mint_coin(&mut scenario, 20000000));
                create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, other_addr, price);
                test_scenario::return_shared(market_account);
            };

            test_scenario::return_shared(market_account);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::EINSUFFICIENT_BALANCE)]
    fun create_buy_offer_insufficient_balance_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(BUYER_ADDR);

        create_capsule_baby(&mut scenario);
        market_account_tests::create_account(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);

        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            market_account::deposit<SUI>(&mut market_account, test_utils::mint_coin(&mut scenario, 100000));
            create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);

            test_scenario::return_shared(market_account);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    #[expected_failure(abort_code = royalty_market::EITEM_TYPE_MISMATCH)]
    fun create_buy_offer_invalid_type_failure() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(BUYER_ADDR);

        create_capsule_baby(&mut scenario);
        market_account_tests::create_account(&mut scenario);
        create_royalty<FakeCapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);

        {
            let royalty = test_scenario::take_shared<Royalty<FakeCapsuleBaby>>(&scenario);
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            create_buy_offer_<FakeCapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);

            test_scenario::return_shared(market_account);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    fun fill_buy_offer() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);
        market_account_tests::create_account(&mut scenario);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);
        
        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            assert!(ownership::get_owner(uid) == option::some(vector[SELLER_ADDR]), 0);

            market_account::deposit(&mut market_account, test_utils::mint_coin<SUI>(&mut scenario, 3400000));
            create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);

            let marketplace = @0xDEED;
            test_scenario::next_tx(&mut scenario, SELLER_ADDR);

            {
                // Fill the buy offer
                fill_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, BUYER_ADDR, &royalty, marketplace);
            assert!(ownership::get_owner(uid) == option::some(vector[BUYER_ADDR]), 0);
                test_scenario::next_tx(&mut scenario, SELLER_ADDR);
            };

            let seller_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let royalty_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let marketplace_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, marketplace);

            // Royalty paid to the royalty recipient
            // i.e 1000 bps of 2000000 = 200000
            assert!(coin::value(&royalty_coin) == 200_000, 0);

            // Amount paid to the marketplace
            // i.e 200 bs of 2000000 = 40000
            assert!(coin::value(&marketplace_coin) == 40_000, 0);

            // final sale amount (offer_price - (total_royalty / 2) - marketplace_fee)
            // i.e 2000000 - (200000 / 2) - 40000
            assert!(coin::value(&seller_coin) == 1_860_000, 0);

            assert!(market_account::balance<SUI>(&market_account) == 1_300_000, 0);

            test_scenario::return_to_address(SELLER_ADDR, royalty_coin);
            test_scenario::return_to_address(SELLER_ADDR, seller_coin);
            test_scenario::return_to_address(marketplace, marketplace_coin);
            test_scenario::return_shared(market_account);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };        

        test_utils::end_scenario(scenario)
    }

    #[test]
    fun fill_buy_offer_with_exact_balance() {
        let (price, royalty_bps, marketplace_bps) = (2000000, 1000, 200);
        let scenario = test_utils::init_scenario(SELLER_ADDR);

        create_capsule_baby(&mut scenario);
        create_royalty<CapsuleBaby>(&mut scenario, SELLER_ADDR, royalty_bps, marketplace_bps);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);
        market_account_tests::create_account(&mut scenario);
        test_scenario::next_tx(&mut scenario, BUYER_ADDR);
        
        {
            let royalty = test_scenario::take_shared<Royalty<CapsuleBaby>>(&scenario);
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            let capsule_baby = test_scenario::take_shared<CapsuleBaby>(&scenario);
            let uid = capsule_baby::extend(&mut capsule_baby);

            assert!(ownership::get_owner(uid) == option::some(vector[SELLER_ADDR]), 0);

            market_account::deposit(&mut market_account, test_utils::mint_coin<SUI>(&mut scenario, 2100000));
            create_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, &royalty, BUYER_ADDR, price);

            let marketplace = @0xDEED;
            test_scenario::next_tx(&mut scenario, SELLER_ADDR);

            {
                // Fill the buy offer
                fill_buy_offer_<CapsuleBaby, SUI>(&mut scenario, uid, &mut market_account, BUYER_ADDR, &royalty, marketplace);
                assert!(ownership::get_owner(uid) == option::some(vector[BUYER_ADDR]), 0);
                test_scenario::next_tx(&mut scenario, SELLER_ADDR);
            };

            let seller_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let royalty_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, SELLER_ADDR);
            let marketplace_coin = test_scenario::take_from_address<Coin<SUI>>(&scenario, marketplace);

            // Royalty paid to the royalty recipient
            // i.e 1000 bps of 2000000 = 200000
            assert!(coin::value(&royalty_coin) == 200_000, 0);

            // Amount paid to the marketplace
            // i.e 200 bs of 2000000 = 40000
            assert!(coin::value(&marketplace_coin) == 40_000, 0);

            // final sale amount (offer_price - (total_royalty / 2) - marketplace_fee)
            // i.e 2000000 - (200000 / 2) - 40000
            assert!(coin::value(&seller_coin) == 1_860_000, 0);

            assert!(market_account::balance<SUI>(&market_account) == 0, 0);

            test_scenario::return_to_address(SELLER_ADDR, royalty_coin);
            test_scenario::return_to_address(SELLER_ADDR, seller_coin);
            test_scenario::return_to_address(marketplace, marketplace_coin);
            test_scenario::return_shared(market_account);
            test_scenario::return_shared(capsule_baby);
            test_scenario::return_shared(royalty);
        };        

        test_utils::end_scenario(scenario)
    }
}