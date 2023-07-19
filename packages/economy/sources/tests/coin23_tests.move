#[test_only]
module economy::coin23_tests {
  use sui::coin;
  use sui::balance;
  use sui::sui::SUI;
  use sui::test_scenario;
  // use sui::tx_context::TxContext;

  use economy::coin23::{Self, Coin23};
  use ownership::tx_authority;

  #[test]
  fun test_create_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let coin23 = coin23::create<SUI>(ctx);
    assert!(coin23::balance_available(&coin23) == 0, 0);

    coin23::return_and_share(coin23, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_coin_import_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let coin23 = coin23::create<SUI>(ctx);
    coin23::import_from_coin(&mut coin23, coin::mint_for_testing(1000, ctx));

    assert!(coin23::balance_available(&coin23) == 1000, 0);

    coin23::return_and_share(coin23, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_balance_import_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let coin23 = coin23::create<SUI>(ctx);
    coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));

    assert!(coin23::balance_available(&coin23) == 1000, 0);

    coin23::return_and_share(coin23, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EACCOUNT_FROZEN)]
  fun test_coin_import_for_frozen_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let coin23 = coin23::create<SUI>(ctx);
    coin23::freeze_for_testing(&mut coin23);
    coin23::import_from_coin(&mut coin23, coin::mint_for_testing(1000, ctx));

    coin23::return_and_share(coin23, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EACCOUNT_FROZEN)]
  fun test_balance_import_for_frozen_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let coin23 = coin23::create<SUI>(ctx);
    coin23::freeze_for_testing(&mut coin23);
    coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));

    coin23::return_and_share(coin23, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_coin23_tranfer() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let to = coin23::create<SUI>(ctx);
    let from = coin23::create<SUI>(ctx);
    let auth = tx_authority::begin(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::import_from_balance(&mut from, balance::create_for_testing(1000));
    coin23::transfer(&mut from, &mut to, 500, &registry, &auth, ctx);

    assert!(coin23::balance_available(&from) == 500, 0);
    assert!(coin23::balance_available(&to) == 500, 0);

    coin23::destroy_currency_registry_for_testing(registry);
    coin23::return_and_share(from, @0x0);
    coin23::return_and_share(to, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EACCOUNT_FROZEN)]
  fun test_coin23_tranfer_with_frozen_coin23s() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let to = coin23::create<SUI>(ctx);
    let from = coin23::create<SUI>(ctx);
    let auth = tx_authority::begin(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::import_from_balance(&mut from, balance::create_for_testing(1000));

    coin23::freeze_for_testing(&mut from);
    coin23::freeze_for_testing(&mut to);
    coin23::transfer(&mut from, &mut to, 500, &registry, &auth, ctx);

    coin23::destroy_currency_registry_for_testing(registry);
    coin23::return_and_share(from, @0x0);
    coin23::return_and_share(to, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EINVALID_TRANSFER)]
  fun test_coin23_tranfer_with_invalid_transfer_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let to = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let from = test_scenario::take_shared<Coin23<SUI>>(&scenario);

      coin23::import_from_balance(&mut from, balance::create_for_testing(1000));

      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::transfer(&mut from, &mut to, 500, &registry, &auth, ctx);
      };

      test_scenario::return_shared(from);
      test_scenario::return_shared(to);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_coin_export_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let coin23 = coin23::create<SUI>(ctx);
    let auth = tx_authority::begin(ctx);

    coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
    
    let exported = coin23::export_to_coin(&mut coin23, &registry, 500, &auth, ctx);

    assert!(coin23::balance_available(&coin23) == 500, 0);
    assert!(coin::value(&exported) == 500, 0);

    coin23::destroy_currency_registry_for_testing(registry);
    coin23::return_and_share(coin23, @0x0);
    coin::burn_for_testing(exported);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_balance_export_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let coin23 = coin23::create<SUI>(ctx);
    let auth = tx_authority::begin(ctx);

    coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
    
    let exported = coin23::export_to_balance(&mut coin23, &registry, 500, &auth);

    assert!(coin23::balance_available(&coin23) == 500, 0);
    assert!(balance::value(&exported) == 500, 0);

    coin23::destroy_currency_registry_for_testing(registry);
    coin23::return_and_share(coin23, @0x0);
    balance::destroy_for_testing(exported);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EINVALID_EXPORT)]
  fun test_coin23_export_coin_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));

      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin::burn_for_testing(coin23::export_to_coin(&mut coin23, &registry, 500, &auth, ctx))
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EINVALID_EXPORT)]
  fun test_coin23_export_balance_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));

      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        balance::destroy_for_testing(coin23::export_to_balance(&mut coin23, &registry, 500, &auth))
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EACCOUNT_FROZEN)]
  fun test_balance_export_frozen_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let coin23 = coin23::create<SUI>(ctx);
    let auth = tx_authority::begin(ctx);

    coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
    
    coin23::freeze_for_testing(&mut coin23);
    balance::destroy_for_testing(coin23::export_to_balance(&mut coin23, &registry, 500, &auth));

    coin23::destroy_currency_registry_for_testing(registry);
    coin23::return_and_share(coin23, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EACCOUNT_FROZEN)]
  fun test_coin_export_frozen_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let coin23 = coin23::create<SUI>(ctx);
    let auth = tx_authority::begin(ctx);

    coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
    
    coin23::freeze_for_testing(&mut coin23);
    coin::burn_for_testing(coin23::export_to_coin(&mut coin23, &registry, 500, &auth, ctx));

    coin23::destroy_currency_registry_for_testing(registry);
    coin23::return_and_share(coin23, @0x0);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_destroy_empty_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    let coin23 = coin23::create<SUI>(ctx);
    let auth = tx_authority::begin(ctx);

    coin23::destroy_empty(coin23, &auth);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_OWNER_AUTHORITY)]
  fun test_destroy_empty_coin23_with_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);

    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x1);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::destroy_empty(coin23, &auth);
    };

    test_scenario::end(scenario);
  }

  #[test]
  fun test_destroy_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let coin23 = coin23::create<SUI>(ctx);
    coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));

    let auth = tx_authority::begin(ctx);
    balance::destroy_for_testing(coin23::destroy(coin23, &registry, &auth));

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EACCOUNT_FROZEN)]
  fun test_destroy_frozen_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let coin23 = coin23::create<SUI>(ctx);
    coin23::freeze_for_testing(&mut coin23);

    let auth = tx_authority::begin(ctx);
    balance::destroy_for_testing(coin23::destroy(coin23, &registry, &auth));

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EINVALID_EXPORT)]
  fun test_destroy_coin23_with_invalid_export_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x1);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      balance::destroy_for_testing(coin23::destroy(coin23, &registry, &auth));
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }
}