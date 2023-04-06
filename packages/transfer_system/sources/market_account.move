module transfer_system::market_account {
    use std::vector;
    use std::type_name::{Self, TypeName};

    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::bag::{Self, Bag};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::transfer;

    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};

    use sui_utils::typed_id;

    friend transfer_system::royalty_market;

    struct MarketAccount has key {
        id: UID,
        balances: Bag
    }

    struct Witness has drop {}

    const ENO_OWNER_AUTHORITY: u64 = 0;
    const ENO_COIN_BALANCE: u64 = 1;

    public fun create(ctx: &mut TxContext) {
        let account = MarketAccount {
            id: object::new(ctx),
            balances: bag::new(ctx)
        };

        let typed_id = typed_id::new(&account);
        let auth = tx_authority::begin_with_type(&Witness {});

        ownership::as_shared_object_<MarketAccount>(&mut account.id, typed_id, vector[tx_context::sender(ctx)], vector::empty(), &auth);
        transfer::share_object(account)
    }

    public fun deposit<C>(account: &mut MarketAccount, payment: Coin<C>) {
        let balance_type = type_name::get<C>();
        let deposit = coin::into_balance(payment);

        if(bag::contains<TypeName>(&account.balances, balance_type)) {
            let balance = bag::borrow_mut<TypeName, Balance<C>>(&mut account.balances, balance_type);
            balance::join(balance, deposit);
        } else {
            bag::add<TypeName, Balance<C>>(&mut account.balances, balance_type, deposit)
        }
    }

    public(friend) fun take<C>(account: &mut MarketAccount, amount: u64, ctx: &mut TxContext): Coin<C> {
        assert_account_ownership(account, &tx_authority::begin(ctx));

        let balance_type = type_name::get<C>();
        assert!(bag::contains<TypeName>(&account.balances, balance_type), ENO_COIN_BALANCE);
        
        let balance = bag::borrow_mut<TypeName, Balance<C>>(&mut account.balances, balance_type);

        let take_balance = balance::split(balance, amount);
        coin::from_balance(take_balance, ctx)
    }

    public fun balance<C>(account: &MarketAccount): u64 {
        let balance_type = type_name::get<C>();
        assert!(bag::contains<TypeName>(&account.balances, balance_type), ENO_COIN_BALANCE);

        let balance = bag::borrow<TypeName, Balance<C>>(&account.balances, balance_type);
        balance::value(balance)
    }

    public fun assert_account_ownership(account: &MarketAccount, auth: &TxAuthority) {
        assert!(ownership::is_authorized_by_owner(&account.id, auth), ENO_OWNER_AUTHORITY)
    }

    #[test_only]
    public fun take_for_testing<C>(account: &mut MarketAccount, amount: u64, ctx: &mut TxContext): Coin<C> {
        take(account, amount, ctx)
    }
}