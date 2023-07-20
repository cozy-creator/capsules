#[test_only]
module economy::coin23_tests {
  use std::vector;
  use std::option;

  use sui::coin;
  use sui::clock;
  use sui::balance;
  use sui::sui::SUI;
  use sui::test_scenario;
  // use sui::tx_context::TxContext;

  use economy::coin23::{Self, Coin23};
  use ownership::tx_authority;

  struct TESTC has drop { }
  struct Witness has drop { }

  struct FAKE_ACTION { }

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

  #[test]
  fun test_add_rebill() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin(ctx);
    let coin23 = coin23::create<SUI>(ctx);
    let clock = clock::create_for_testing(ctx);

    coin23::add_rebill(&mut coin23, @0x1, 10000, 5000, &clock, &registry, &auth);
    let merchants = coin23::merchants_with_rebills(&coin23);
    let merchant_rebills = coin23::rebills_for_merchant(&coin23, @0x1);
    let (_, refresh_amount, refresh_cadence, _) = coin23::inspect_rebill(vector::borrow(merchant_rebills, 0));

    assert!(vector::contains(&merchants, &@0x1), 0);
    assert!(refresh_amount == 10000, 0);
    assert!(refresh_cadence == 5000, 0);

    clock::destroy_for_testing(clock);
    coin23::destroy_currency_registry_for_testing(registry);
    balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_OWNER_AUTHORITY)]
  fun test_add_rebill_invalid_coin23_owner() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x1);
    {
      let ctx = test_scenario::ctx(&mut scenario);

      let auth = tx_authority::begin(ctx);
      let clock = clock::create_for_testing(ctx);
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);

      coin23::add_rebill(&mut coin23, @0x1, 10000, 5000, &clock, &registry, &auth);
      test_scenario::return_shared(coin23);
      clock::destroy_for_testing(clock);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }


  #[test]
  #[expected_failure(abort_code=coin23::EACCOUNT_FROZEN)]
  fun test_add_rebill_frozen_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin(ctx);
    let coin23 = coin23::create<SUI>(ctx);
    let clock = clock::create_for_testing(ctx);

    coin23::freeze_for_testing(&mut coin23);
    coin23::add_rebill(&mut coin23, @0x1, 10000, 5000, &clock, &registry, &auth);
  
    clock::destroy_for_testing(clock);
    coin23::destroy_currency_registry_for_testing(registry);
    balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EINVALID_REBILL)]
  fun test_add_rebill_invalid_rebill_amount() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin(ctx);
    let coin23 = coin23::create<SUI>(ctx);
    let clock = clock::create_for_testing(ctx);

    coin23::add_rebill(&mut coin23, @0x1, 0, 5000, &clock, &registry, &auth);
  
    clock::destroy_for_testing(clock);
    coin23::destroy_currency_registry_for_testing(registry);
    balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    test_scenario::end(scenario);
  }

  #[test]
  fun test_withdraw_with_rebill() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(1000));
      coin23::add_rebill(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      clock::increment_for_testing(&mut clock, 5000);
      test_scenario::next_tx(&mut scenario, @0x1);

      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::withdraw_with_rebill(&mut c_coin23, &mut m_coin23, 0, 300, &clock, &registry, &auth, ctx);

        assert!(coin23::balance_available(&c_coin23) == 700, 0);
        assert!(coin23::balance_available(&m_coin23) == 300, 0);

        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    clock::destroy_for_testing(clock);
    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_MERCHANT_AUTHORITY)]
  fun test_withdraw_with_rebill_invalid_merchant_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(1000));
      coin23::add_rebill(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      clock::increment_for_testing(&mut clock, 5000);
      test_scenario::next_tx(&mut scenario, @0x2);

      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::withdraw_with_rebill(&mut c_coin23, &mut m_coin23, 0, 300, &clock, &registry, &auth, ctx);
        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    clock::destroy_for_testing(clock);
    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EACCOUNT_FROZEN)]
  fun test_withdraw_with_rebill_frozen_merchant_and_customer() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(1000));
      coin23::add_rebill(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      clock::increment_for_testing(&mut clock, 5000);
      test_scenario::next_tx(&mut scenario, @0x1);

      coin23::freeze_for_testing(&mut c_coin23);

      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::freeze_for_testing(&mut m_coin23);
        coin23::withdraw_with_rebill(&mut c_coin23, &mut m_coin23, 0, 300, &clock, &registry, &auth, ctx);

        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    clock::destroy_for_testing(clock);
    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_cancel_rebill_by_customer() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      coin23::cancel_rebill(&mut coin23, @0x1, 0, &auth);

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_cancel_rebill_by_merchant() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::cancel_rebill(&mut coin23, @0x1, 0, &auth);
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_cancel_rebill_from_multiple() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      coin23::add_rebill(&mut coin23, @0x1, 500, 5000, &clock, &registry, &auth);

      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::cancel_rebill(&mut coin23, @0x1, 0, &auth);

        let merchant_rebills = coin23::rebills_for_merchant(&coin23, @0x1);
        assert!(!vector::is_empty(merchant_rebills), 0);
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }


  #[test]
  #[expected_failure(abort_code=coin23::ENO_OWNER_AUTHORITY)]
  fun test_cancel_rebill_inalid_owner_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      test_scenario::next_tx(&mut scenario, @0x2);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::cancel_rebill(&mut coin23, @0x1, 0, &auth);
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

 #[test]
  fun test_cancel_all_merchant_rebills_by_customer() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      coin23::add_rebill(&mut coin23, @0x1, 500, 5000, &clock, &registry, &auth);

      test_scenario::next_tx(&mut scenario, @0x0);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::cancel_all_rebills_for_merchant(&mut coin23, @0x1, &auth);
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_cancel_all_merchant_rebills_by_merchant() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      coin23::add_rebill(&mut coin23, @0x1, 500, 5000, &clock, &registry, &auth);

      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::cancel_all_rebills_for_merchant(&mut coin23, @0x1, &auth);
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

 #[test]
  #[expected_failure(abort_code=coin23::ENO_OWNER_AUTHORITY)]
  fun test_cancel_all_merchant_rebills_by_invalid_owner() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      coin23::add_rebill(&mut coin23, @0x1, 500, 5000, &clock, &registry, &auth);

      test_scenario::next_tx(&mut scenario, @0x2);
      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::cancel_all_rebills_for_merchant(&mut coin23, @0x1, &auth);
      };

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_add_hold_single() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      
      let merchants = coin23::merchants_with_held_funds(&coin23);
      let (hold_value, expiry_ms) = coin23::inspect_hold(&coin23, @0x1);

      assert!(coin23::balance_available(&coin23) == 9000, 0);
      assert!(vector::contains(&merchants, &@0x1), 0);
      assert!(hold_value == 1000, 0);
      assert!(expiry_ms == 5000, 0);

      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_add_hold_multple() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      coin23::add_hold(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EINVALID_HOLD)]
  fun test_add_hold_invalid_amount() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::add_hold(&mut coin23, @0x1, 0, 5000, &clock, &registry, &auth);
      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_OWNER_AUTHORITY)]
  fun test_add_hold_invalid_owner_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x1);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EACCOUNT_FROZEN)]
  fun test_add_hold_to_frozen_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x0, ctx);
    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::freeze_for_testing(&mut coin23);
      coin23::add_hold(&mut coin23, @0x1, 1000, 5000, &clock, &registry, &auth);
      test_scenario::return_shared(coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_withdraw_from_held_funds() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);

      clock::increment_for_testing(&mut clock, 2000);
      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        
        coin23::withdraw_from_held_funds(&mut c_coin23, &mut m_coin23, 500, &clock, &registry, &auth, ctx);
        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_MERCHANT_AUTHORITY)]
  fun test_withdraw_from_held_funds_invalid_merchant_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);

      clock::increment_for_testing(&mut clock, 2000);
      test_scenario::next_tx(&mut scenario, @0x0);
      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        
        coin23::withdraw_from_held_funds(&mut c_coin23, &mut m_coin23, 500, &clock, &registry, &auth, ctx);
        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EACCOUNT_FROZEN)]
  fun test_withdraw_from_held_funds_for_frozen_merchant() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);

      clock::increment_for_testing(&mut clock, 2000);
      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);

        coin23::freeze_for_testing(&mut m_coin23);        
        coin23::withdraw_from_held_funds(&mut c_coin23, &mut m_coin23, 500, &clock, &registry, &auth, ctx);
        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EHOLD_EXPIRED)]
  fun test_withdraw_from_expired_held_funds() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);

      clock::increment_for_testing(&mut clock, 6000);
      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        
        coin23::withdraw_from_held_funds(&mut c_coin23, &mut m_coin23, 500, &clock, &registry, &auth, ctx);
        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_release_held_funds() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);

      clock::increment_for_testing(&mut clock, 2000);
      test_scenario::next_tx(&mut scenario, @0x1);
      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        
        coin23::release_held_funds(&mut c_coin23, @0x1, &auth);
        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_MERCHANT_AUTHORITY)]
  fun test_release_held_funds_invalid_merchant_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    coin23::create_<SUI>(@0x1, ctx);
    coin23::create_<SUI>(@0x0, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let c_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut c_coin23, balance::create_for_testing(10000));
      coin23::add_hold(&mut c_coin23, @0x1, 1000, 5000, &clock, &registry, &auth);

      clock::increment_for_testing(&mut clock, 2000);
      test_scenario::next_tx(&mut scenario, @0x0);
      {
        let m_coin23 = test_scenario::take_shared<Coin23<SUI>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin(ctx);
        
        coin23::release_held_funds(&mut c_coin23, @0x1, &auth);
        test_scenario::return_shared(m_coin23);
      };

      test_scenario::return_shared(c_coin23);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    clock::destroy_for_testing(clock);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_register_currency() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ECURRENCY_ALREADY_REGISTERED)]
  fun test_register_currency_duplicate() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_PACKAGE_AUTHORITY)]
  fun test_register_currency_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness<Witness, FAKE_ACTION>(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_freeze_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      let coin23 = coin23::create<TESTC>(ctx);
      coin23::freeze_(&mut coin23, &registry, &auth);

      assert!(coin23::is_frozen(&coin23), 0);
      balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_PACKAGE_AUTHORITY)]
  fun test_freeze_coin23_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness<Witness, FAKE_ACTION>(Witness {});
      let coin23 = coin23::create<TESTC>(ctx);
      coin23::freeze_(&mut coin23, &registry, &auth);
      balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EFREEZE_DISABLED)]
  fun test_freeze_coin23_freeze_disabled() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, false, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      let coin23 = coin23::create<TESTC>(ctx);
      coin23::freeze_(&mut coin23, &registry, &auth);
      balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_unfreeze_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      {
        let auth = tx_authority::begin_with_package_witness_(Witness {});
        let coin23 = coin23::create<TESTC>(ctx);
        coin23::freeze_(&mut coin23, &registry, &auth);

        assert!(coin23::is_frozen(&coin23), 0);
        balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
      };
      
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      let coin23 = coin23::create<TESTC>(ctx);
      coin23::unfreeze(&mut coin23, &auth);

      assert!(!coin23::is_frozen(&coin23), 0);
      balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_PACKAGE_AUTHORITY)]
  fun test_unfreeze_coin23_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      {
        let auth = tx_authority::begin_with_package_witness_(Witness {});
        let coin23 = coin23::create<TESTC>(ctx);
        coin23::freeze_(&mut coin23, &registry, &auth);
        balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
      };

      let auth = tx_authority::begin_with_package_witness<Witness, FAKE_ACTION>(Witness {});
      let coin23 = coin23::create<TESTC>(ctx);
      coin23::unfreeze(&mut coin23, &auth);
      balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EFREEZE_DISABLED)]
  fun test_disable_creator_freeze_ability() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      {
        let auth = tx_authority::begin_with_package_witness_(Witness {});
        coin23::disable_freeze_ability<TESTC>(&mut registry, &auth);
      };

      let auth = tx_authority::begin_with_package_witness_(Witness {});
      let coin23 = coin23::create<TESTC>(ctx);
      coin23::freeze_(&mut coin23, &registry, &auth);
      balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_PACKAGE_AUTHORITY)]
  fun test_disable_creator_freeze_ability_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness<Witness, FAKE_ACTION>(Witness {});
      coin23::disable_freeze_ability<TESTC>(&mut registry, &auth);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }


  #[test]
  fun test_disable_creator_withdraw() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::disable_creator_withdraw<TESTC>(&mut registry, &auth);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_PACKAGE_AUTHORITY)]
  fun test_disable_creator_withdraw_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness<Witness, FAKE_ACTION>(Witness {});
      coin23::disable_creator_withdraw<TESTC>(&mut registry, &auth);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_set_transfer_policy() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::set_transfer_policy<TESTC>(&mut registry, 1, vector[@0x3], &auth);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_PACKAGE_AUTHORITY)]
  fun test_set_transfer_policy_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness<Witness, FAKE_ACTION>(Witness {});
      coin23::set_transfer_policy<TESTC>(&mut registry, 1, vector[@0x3], &auth);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_set_transfer_fee() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::set_transfer_fee<TESTC>(&mut registry, option::none(), option::none(), &auth);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::ENO_PACKAGE_AUTHORITY)]
  fun test_set_transfer_fee_invalid_auth() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    {
      let auth = tx_authority::begin_with_package_witness_(Witness {});
      coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    };

    {
      let auth = tx_authority::begin_with_package_witness<Witness, FAKE_ACTION>(Witness {});
      coin23::set_transfer_fee<TESTC>(&mut registry, option::none(), option::none(), &auth);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code = coin23::EINVALID_TRANSFER)]
  fun test_coin23_tranfer_with_no_transfer() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);
    
    coin23::create_<TESTC>(@0x0, ctx);
    coin23::create_<TESTC>(@0x1, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let to = test_scenario::take_shared<Coin23<TESTC>>(&scenario);
      let from = test_scenario::take_shared<Coin23<TESTC>>(&scenario);

      coin23::import_from_balance(&mut from, balance::create_for_testing(1000));

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
  #[expected_failure(abort_code = coin23::EINVALID_TRANSFER)]
  fun test_coin23_tranfer_with_creator_withdraw() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, false, true, 0, option::none(), option::none(), vector::empty(), &auth);
    
    coin23::create_<TESTC>(@0x0, ctx);
    coin23::create_<TESTC>(@0x1, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let to = test_scenario::take_shared<Coin23<TESTC>>(&scenario);
      let from = test_scenario::take_shared<Coin23<TESTC>>(&scenario);

      coin23::import_from_balance(&mut from, balance::create_for_testing(1000));

      {
        let ctx = test_scenario::ctx(&mut scenario);
        let auth = tx_authority::begin_with_package_witness_(Witness {});

        coin23::transfer(&mut from, &mut to, 500, &registry, &auth, ctx);
      };

      test_scenario::return_shared(from);
      test_scenario::return_shared(to);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_coin23_tranfer_with_user_transfer_allowed() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 1, option::none(), option::none(), vector::empty(), &auth);
    
    coin23::create_<TESTC>(@0x0, ctx);
    coin23::create_<TESTC>(@0x1, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let to = test_scenario::take_shared<Coin23<TESTC>>(&scenario);
      let from = test_scenario::take_shared<Coin23<TESTC>>(&scenario);

      coin23::import_from_balance(&mut from, balance::create_for_testing(1000));

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
  fun test_coin23_tranfer_with_transfer_fee() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 1, option::some(100), option::some(@0x5), vector::empty(), &auth);
    
    coin23::create_<TESTC>(@0x0, ctx);
    coin23::create_<TESTC>(@0x1, ctx);

    test_scenario::next_tx(&mut scenario, @0x0);
    {
      let to = test_scenario::take_shared<Coin23<TESTC>>(&scenario);
      let from = test_scenario::take_shared<Coin23<TESTC>>(&scenario);

      coin23::import_from_balance(&mut from, balance::create_for_testing(1000));

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
  #[expected_failure(abort_code = coin23::ECURRENCY_CANNOT_BE_TRANSFERRED)]
  fun test_add_rebill_non_transferable_currency() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 0, option::none(), option::none(), vector::empty(), &auth);

    {
      let auth = tx_authority::begin(ctx);
      let coin23 = coin23::create<TESTC>(ctx);
      let clock = clock::create_for_testing(ctx);

      coin23::add_rebill(&mut coin23, @0x1, 10000, 5000, &clock, &registry, &auth);
  
      clock::destroy_for_testing(clock);
      balance::destroy_for_testing(coin23::destroy_for_testing(coin23));
    };
    
    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=coin23::EINVALID_EXPORT)]
  fun test_balance_export_not_exportable_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 1, option::none(), option::none(), vector::empty(), &auth);

    {
      let coin23 = coin23::create<TESTC>(ctx);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
      
      let exported = coin23::export_to_balance(&mut coin23, &registry, 500, &auth);
      balance::destroy_for_testing(exported);
      coin23::return_and_share(coin23, @0x0);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_balance_export_user_exportable_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 2, option::none(), option::none(), vector::empty(), &auth);

    {
      let coin23 = coin23::create<TESTC>(ctx);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
      
      let exported = coin23::export_to_balance(&mut coin23, &registry, 500, &auth);
      balance::destroy_for_testing(exported);
      coin23::return_and_share(coin23, @0x0);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_balance_export_creator_withdraw_exportable_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 1, option::none(), option::none(), vector::empty(), &auth);

    {
      let coin23 = coin23::create<TESTC>(ctx);
      let auth = tx_authority::begin_with_package_witness_(Witness {});

      coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
      
      let exported = coin23::export_to_balance(&mut coin23, &registry, 500, &auth);
      balance::destroy_for_testing(exported);
      coin23::return_and_share(coin23, @0x0);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }

  #[test]
  fun test_balance_export_agent_export_coin23() {
    let scenario = test_scenario::begin(@0x0);
    let ctx = test_scenario::ctx(&mut scenario);
    let registry = coin23::create_currency_registry_for_testing(ctx);

    let auth = tx_authority::begin_with_package_witness_(Witness {});
    coin23::register_currency<TESTC>(&mut registry, true, true, 1, option::none(), option::none(), vector::singleton(@0x7), &auth);

    test_scenario::next_tx(&mut scenario, @0x7);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let coin23 = coin23::create<TESTC>(ctx);
      let auth = tx_authority::begin(ctx);

      coin23::import_from_balance(&mut coin23, balance::create_for_testing(1000));
      
      let exported = coin23::export_to_balance(&mut coin23, &registry, 500, &auth);
      balance::destroy_for_testing(exported);
      coin23::return_and_share(coin23, @0x0);
    };

    coin23::destroy_currency_registry_for_testing(registry);
    test_scenario::end(scenario);
  }
}
