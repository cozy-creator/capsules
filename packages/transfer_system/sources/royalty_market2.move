module transfer_system::royalty_market2 {
    use sui::object::{UID, ID};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::object;
    use noot::coin2;
    use noot::noot::{Self, TransferCap, Noot};
    use std::option;

    const ENOT_OWNER: u64 = 0;
    const ENO_TRANSFER_PERMISSION: u64 = 1;
    const EINSUFFICIENT_FUNDS: u64 = 2;

    struct Market has drop {}

    // Treasury's are stored within the world treasury as a dynamic field
    struct WorldTreasury has key {
        id: UID
    }

    struct Treasury<phantom C> has store {
        owed: vector<OwnerAmount>,
        fund: Coin<C>
    }

    struct OwnerAmount has store {
        pay_to: address,
        amount: u64
    }

    public fun payout(treasury: &mut Treasury) {
        
    }

    // transfer_Cap is only optional until shared objects can be deleted in Sui.
    // This is because after an offer is sold, we cannot delete it becasue it's a
    // shared object, but it also no longer has its transfer cap, so it can no longer
    // be used
    struct SellOffer<phantom C, phantom T> has key, store {
        id: UID,
        pay_to: address,
        price: u64,
        royalty_addr: address,
        seller_royalty: u64,
        market_fee: u64,
        transfer_cap: option::Option<TransferCap<T, Market>>
    }

    struct BuyOffer<phantom C, phantom T> has key, store {
        id: UID,
        send_to: address,
        for: option::Option<ID>,
        offer: Coin<C>
    }

    // May be a shared or owned object. Used in the buy_noot function call to pay
    // royalties. Multiple Royalty objects may exist per `T`. Noots cannot be bought or
    // sold without access to a Royalty object.
    struct Royalty<phantom T> has key, store {
        id: UID,
        pay_to: address,
        fee_bps: u64
    }

    // Owned object, kept by the creator. Used to create Royalty objects of type `T`
    // or change them. We allow multiple of these to exist, but only the module defining
    // the type `T` can create them
    struct RoyaltyCap<phantom T> has key, store {
        id: UID
    }

    public fun create_royalty_cap<T: drop>(_witness: T, ctx: &mut TxContext): RoyaltyCap<T> {
        RoyaltyCap<T> {
            id: object::new(ctx)
        }
    }

    public entry fun create_royalty_<T>(pay_to: address, fee_bps: u64, royalty_cap: &RoyaltyCap<T>, ctx: &mut TxContext) {
        let royalty = create_royalty<T>(pay_to, fee_bps, royalty_cap, ctx);
        transfer::share_object(royalty);
    }

    public fun create_royalty<T>(pay_to: address, fee_bps: u64, _royalty_cap: &RoyaltyCap<T>, ctx: &mut TxContext): Royalty<T> {
        Royalty<T> {
            id: object::new(ctx),
            pay_to,
            fee_bps
        }
    }

    // This is of limited utility until shared objects can be destroyed in Sui; right now this can only
    // destroy royalties if they are owned objects
    public entry fun destroy_royalty<T>(royalty: Royalty<T>, _royalty_cap: &RoyaltyCap<T>) {
        let Royalty { id, pay_to: _, fee_bps: _ } = royalty;
        object::delete(id);
    }

    // Do we really need this function? Isn't creating and destroying enough?
    public entry fun change_royalty<T>(royalty: &mut Royalty<T>, new_pay_to: address, new_fee_bps: u64, _royalty_cap: &RoyaltyCap<T>) {
        royalty.pay_to = new_pay_to;
        royalty.fee_bps = new_fee_bps;
    }

    // In order to do this, the noot must be single-writer, and owned by the transaction-sender
    // as such, the is_owner is kind of redundant. This fully consumes the noot, and shares it. Once
    // shared resources can be consumed (and not just referenced) by transactions in Sui, the
    // is_owner check will make more sense.
    public entry fun create_sell_offer_<C, T: drop>(price: u64, noot: &mut Noot<T, Market>, market_bps: u16, ctx: &mut TxContext) {
        // Assert that the transfer cap still exists within the Noot
        assert!(noot::is_fully_owned<T, Market>(noot), ENO_TRANSFER_PERMISSION);
        // Assert that the owner of this Noot is sending this tx
        assert!(noot::is_owner<T, Market>(tx_context::sender(ctx), noot), ENOT_OWNER);

        let transfer_cap = noot::extract_transfer_cap(Market {}, noot);
        let pay_to = tx_context::sender(ctx);
        create_sell_offer<C,T>(pay_to, price, transfer_cap, market_bps, ctx);
    }

    public fun create_sell_offer<C, T>(pay_to: address, price: u64, transfer_cap: TransferCap<T, Market>, market_bps: u16, ctx: &mut TxContext) {
        let for_sale = SellOffer<C, T> {
            id: object::new(ctx),
            pay_to,
            price,
            royalty_addr: royalty.pay_to,
            seller_royalty: (((price as u128) * (royalty.fee_bps as u128) / 10000) as u64),
            market_fee: (((price as u128) * (market_bps as u128) / 10000) as u64),
            transfer_cap: option::some(transfer_cap)
        };

        transfer::share_object(for_sale);
    }

    // Once Sui supports passing shared objects by value, rather than just reference, this function
    // will change to consume the shared SellOffer wrapper, and delete it.
    // Note that the new_owner does not necessarily have to be the sender of the transaction
    public entry fun fill_sell_offer_<C, T: drop>(for_sale: &mut SellOffer<C, T>, coin: Coin<C>, new_owner: address, royalty: &Royalty<T>, market_addr: address, noot: &mut Noot<T, Market>, ctx: &mut TxContext) {
        let transfer_cap = fill_sell_offer(for_sale, coin, royalty, market_addr, ctx);
        noot::transfer_and_fully_own(new_owner, noot, transfer_cap);
    }

    public fun fill_sell_offer<C, T>(for_sale: &mut SellOffer<C, T>, coin: Coin<C>, royalty: &Royalty<T>, market_addr: address, ctx: &mut TxContext): TransferCap<T, Market> {
        assert!(option::is_some(&for_sale.transfer_cap), ENO_TRANSFER_PERMISSION);

        let buyer_royalty = ((for_sale.price as u128) * (royalty.fee_bps as u128) / 10000 / 2 as u64);
        assert!(coin::value(&coin) >= (for_sale.price + buyer_royalty), EINSUFFICIENT_FUNDS);

        // Buyer's part of the royalty. This is not included in for_sale.price.
        coin2::take_coin_and_transfer(royalty.pay_to, &mut coin, buyer_royalty, ctx);

        // Seller's part of the royalty. Note that the seller and buy royalty addresses and
        // amounts need not be the same.
        coin2::take_coin_and_transfer(for_sale.royalty_addr, &mut coin, for_sale.seller_royalty, ctx);

        // Marketplace fee
        coin2::take_coin_and_transfer(market_addr, &mut coin, for_sale.market_fee, ctx);

        // Remainder goes to the seller
        coin2::take_coin_and_transfer(for_sale.pay_to, &mut coin, for_sale.price - for_sale.seller_royalty - for_sale.market_fee, ctx);

        coin2::refund(coin, ctx);

        let transfer_cap = option::extract(&mut for_sale.transfer_cap);
        transfer_cap
    }

    // SellOffer is a shared object and cannot be deleted. In the future, we will be able to delete it
    public entry fun cancel_sell_offer<C, T: drop>(
        for_sale: &mut SellOffer<C,T>, 
        noot: &mut Noot<T, Market>, 
        ctx: &mut TxContext) 
    {
        assert!(noot::is_owner<T, Market>(tx_context::sender(ctx), noot), ENOT_OWNER);

        let transfer_cap = option::extract(&mut for_sale.transfer_cap);
        assert!(noot::is_correct_transfer_cap(noot, &transfer_cap), ENO_TRANSFER_PERMISSION);
        noot::fill_transfer_cap(noot, transfer_cap);
    }

    public entry fun create_buy_offer() {}

    public entry fun fill_buy_offer() {}

    public entry fun cancel_buy_offer() {}

    // === Get functions, to read struct data ===

    public fun get_royalty_info<T>(royalty: &Royalty<T>): (address, u64) {
        (royalty.pay_to, royalty.fee_bps)
    }
}