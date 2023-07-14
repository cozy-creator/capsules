#[test_only]
module transfer_system::market_account_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::sui::SUI;

    use transfer_system::test_utils;
    use transfer_system::market_account::{Self, MarketAccount};

    const SENDER: address = @0xBABE;

    public fun create_account(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        market_account::create(ctx);
    }

    // ========== Test functions ==========

    #[test]
    fun create_market_account() {
        let scenario = test_utils::init_scenario(SENDER);

        create_account(&mut scenario);
        test_utils::end_scenario(scenario)
    }

    #[test]
    fun deposit_to_market_account() {
        let deposit = 135000;
        let scenario = test_utils::init_scenario(SENDER);

        create_account(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            market_account::deposit<SUI>(&mut market_account, test_utils::mint_coin(&mut scenario, deposit));

            let balance = market_account::balance<SUI>(&market_account);
            assert!(balance == deposit, 0);
            
            test_scenario::return_shared(market_account);
        };

        test_utils::end_scenario(scenario)
    }

    #[test]
    fun take_from_market_account() {
        let (deposit, take_amount) = (135000, 35000);
        let scenario = test_utils::init_scenario(SENDER);

        create_account(&mut scenario);
        test_scenario::next_tx(&mut scenario, SENDER);

        {
            let market_account = test_scenario::take_shared<MarketAccount>(&scenario);
            market_account::deposit<SUI>(&mut market_account, test_utils::mint_coin(&mut scenario, deposit));

            let balance = market_account::balance<SUI>(&market_account);
            assert!(balance == deposit, 0);
            
            let coin = market_account::take_for_testing<SUI>(&mut market_account, take_amount, test_scenario::ctx(&mut scenario));
            test_utils::burn_coin(coin);

            let balance = market_account::balance<SUI>(&market_account);
            assert!(balance == (deposit - take_amount), 0);

            test_scenario::return_shared(market_account);
        };

        test_utils::end_scenario(scenario)
    }
}