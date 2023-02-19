module sui_examples::coin {
use std::string;
    use std::ascii;
    use std::option::{Self, Option};
    use sui::balance::{Self, Balance, Supply};
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::url::{Self, Url};
    use std::vector;
    use sui::event;

    /// For when invalid arguments are passed to a function.
    const EInvalidArg: u64 = 1;

    /// For when trying to split a coin more times than its balance allows.
    const ENotEnough: u64 = 2;

    /// Owned object. A coin of type `T` worth `balance`.
    struct Coin<phantom T> has key, store {
        id: UID,
        balance: Balance<T>
    }

    // Owned capability object. Allows the bearer to mint and burn Coin<T>
    struct TreasuryCap<phantom T> has key, store {
        id: UID,
        total_supply: Supply<T>
    }

    struct Witness has drop { }
    struct COIN has drop { }

    /// Create a new currency type `T` as and return `TreasuryCap<T>` and `Type<T>` metadata
    /// object to the caller.
    public fun create_currency<T: drop>(
        witness: T,
        abstract_type: &mut AbstractType,
        data: vector<vector<u8>>,
        schema: &Schema,
        ctx: &mut TxContext
    ): (TreasuryCap<T>, Type<T>) {
        let treasury_cap = TreasuryCap {
            id: object::new(ctx),
            total_supply: balance::create_supply(witness)
        };
        let auth = tx_authority::begin_with_type<T>(&Witness { });
        let type = abstract_type::define_from_abstract_<Coin<T>>(abstract_type, data, schema, &auth, ctx);

        (treasury_cap, type)
    }

    fun init(genesis: COIN, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&genesis, ctx);

        let owner = tx_authority::type_into_address<Witness>();
        let data = vector::empty<vector<u8>>();
        let schema = schema::create_(vector[
            vector[asii::String(b"decimals", ascii::String(b"u8"))],
            vector[asii::String(b"name", ascii::String(b"String"))],
            vector[asii::String(b"symbol", ascii::String(b"String"))],
            vector[asii::String(b"description", ascii::String(b"String"))],
             vector[asii::String(b"icon_url", ascii::String(b"Option<String>"))],
        ], ctx);
        let auth = tx_authority::begin_with_type(&Witness { });

        abstract_type::define(&mut receipt, owner, data, &schema, ctx);
        transfer::transfer(receipt, tx_context::sender(ctx));
        schema::freeze(schema);
    }
}