module economy::coin24 {
    public fun create_bid(account: &mut Account, price: u64, for: ID) {
        dynamic_field::add(&mut account.id, for, price);
    }

    public fun order_book_local(orderbook: &mut OrderBook) {
        // Items are stored inside of the orderbook if for sale
        // Coins are stored inside of the orderbook for offers
        // After a trade occurs, items are removed and placed in a shared-object capsule
        // Coins will remain in the orderbook until withdrawn into an Account
        // (We could potentially provide a withdraw-crank, for convenience?)
        // (Coins could potentially be transferred, rather than merge balance, if sendable)
        // Trading bots should own all coins inside of the orderbook; they act as a proxy
        // owner of their depositor's funds, allowing it to buy and sell.
        //
        // Bids are funds that sit inside of the orderbook
        // The funds are owned by an address (person or bot) not an account object-id
        //
        // Bids for specific-items are stored in the orderbook as well, indexed by id rather than price
    }

    public fun order_book_proxy(orderbook: &mut Orderbook) {
        // Proxy-items are stored in the orderbook when for sale
        // Proxy-coin claims are stored inside of the orderbook for offers
        // When a trade matches, the proxy-items can be claimed by their new owners
        // Same for proxy-coin claims
        // (We could add a withdraw-crank, for convenience)
        // Care has to be taken that these proxy-items and proxy-coins are available,
        // otherwise you could rip people off.
        // Trading bots can be used as well
        // 
        // We should probably just store the actual funds, rather than claims on funds
        // That just makes everything easier.
        // Bids are now funds that sit inside of the orderbook
        // 
        // Bids for specific-items are stored in the orderbook as well, indexed by id rather than price
    }

    public fun offchain_orderbook(orderbook: &mut Orderbook) {
        // Offers for an item are stored inside of the item
        // Bids for general items are stored inside of an Account, and are not necessarily fully funded
        // When a trade matches, the item and coin are swapped immediately. This matching is done
        // off-chain, and good indexing is required.
        // 
        // Bids for specific-items are also stored inside of an Account
    }
}