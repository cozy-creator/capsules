module auction::auction {
    use std::vector;
    use std::option::{Self, Option};

    use sui::object::{Self, ID, UID};
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use sui_utils::typed_id;
    use sui_utils::struct_tag;

    use ownership::ownership;
    use ownership::tx_authority;

    use transfer_system::simple_transfer::{Self, Witness as SimpleTransfer};
    use transfer_system::royalty_market::{Witness as RoyaltyMarket, Royalty};

    struct Auction<phantom T, phantom C> has key {
        id: UID,
        /// The minimum bid amount for the auction
        starting_bid: u64,
        /// The time when the auction begins
        start_time: u64,
        /// The time when the auction ends
        end_time: u64,
        /// Table to store bids made by addresses with their respective amounts
        bids: Table<address, u64>,
        /// The highest bid amount for the auction
        highest_bid: Balance<C>,
        // The address of the highest bidder
        highest_bidder: Option<address>,
        /// Status of the auction (0 for active, 2 for cancelled, 3 for ended)
        status: u8
    }

    struct Witness has drop {}

    const ENO_OWNER_AUTH: u64 = 0;
    const EITEM_TYPE_MISMATCH: u64 = 1;
    const EINVALID_TIME_DIFFERENCE: u64 = 2;
    const EINSUFFICIENT_BID: u64 = 3;
    const EAUCTION_NOT_STARTED: u64 = 4;
    const EAUCTION_ALREADY_ENDED: u64 = 5;
    const EALREADY_HIGHEST_BIDDER: u64 = 6;
    const EAUCTION_ALREADY_CANCELED: u64 = 7;
    const EAUCTION_NOT_ENDED: u64 = 8;
    const EUNRECOGNIZED_MARKET: u64 = 9;
    const EMARKET_MISMATCH: u64 = 10;
    const EITEM_MISMATCH: u64 = 11;

    public fun create_auction<T: key, C>(
        item: &mut UID,
        clock: &Clock,
        minimum_bid: u64,
        starts_at: u64,
        ends_at: u64,
        ctx: &mut TxContext
    ) {
        // Ensures that the auction creator is the rightful owner of the item being auctioned
        assert!(ownership::is_authorized_by_owner(item, &tx_authority::begin(ctx)), ENO_OWNER_AUTH);

        let current_time = clock::timestamp_ms(clock);

        assert!(current_time <= starts_at, EINVALID_TIME_DIFFERENCE);
        assert!(starts_at < ends_at, EINVALID_TIME_DIFFERENCE);

        let item_type = ownership::get_type(item);
        assert!(struct_tag::get<T>() == option::destroy_some(item_type), EITEM_TYPE_MISMATCH);


        let auction = Auction<T, C> {
            id: object::new(ctx),
            market_address: get_market_address(item),
            item_id: object::uid_to_inner(item),
            highest_bidder: option::none(),
            highest_bid: balance::zero(),
            is_canceled: false,
            minimum_bid,
            starts_at,
            ends_at,
        };

        let tid = typed_id::new(&auction);
        let auth = tx_authority::begin_with_type(&Witness {});
        let owner = vector::singleton(tx_context::sender(ctx));

        ownership::as_shared_object_(item, tid, owner, vector::empty(), &auth);

        transfer::share_object(auction)
    }

    public fun place_bid<T, C>(self: &mut Auction<T, C>, clock: &Clock, bid: Coin<C>, ctx: &mut TxContext) {
        let current_time = clock::timestamp_ms(clock);
        let current_bidder = tx_context::sender(ctx);

        //Ensures that the auction has not been canceled
        assert!(!self.is_canceled, EAUCTION_ALREADY_CANCELED);

        // Ensures that the auction has started
        assert!(current_time >= self.starts_at, EAUCTION_NOT_STARTED);

        // Ensures that the aution has not ended
        assert!(current_time <= self.ends_at, EAUCTION_ALREADY_ENDED);

        // Ensures that the bid is greater than or equal to the minimum bid allowed
        assert!(coin::value(&bid) >= self.minimum_bid, EINSUFFICIENT_BID);

        // Ensures that the bid is greater than the current highest bid
        assert!(coin::value(&bid) > balance::value(&self.highest_bid), EINSUFFICIENT_BID);

        if(option::is_some(&self.highest_bidder)) {
            // If there is already a highest bidder in place, 
            // we ensure that any new bid is placed by an address different from the current highest bidder.
            assert!(&current_bidder != option::borrow(&self.highest_bidder), EALREADY_HIGHEST_BIDDER);

            // Additionally, we transfer the previous highest bid back to its original bidder.
            let coin = coin::from_balance(balance::withdraw_all(&mut self.highest_bid), ctx);
            transfer::public_transfer(coin, option::extract(&mut self.highest_bidder));
        };

        // Update the auction highest bid with the new bid
        balance::join(&mut self.highest_bid, coin::into_balance(bid));

        // Update the highest bidder with the current bidder
        option::fill(&mut self.highest_bidder, current_bidder)
    }

    public fun cancel_auction<T, C>(self: &mut Auction<T, C>, clock: &Clock, ctx: &mut TxContext) {
        // Ensures that the auction creator is the rightful owner of the item being auctioned
        assert!(ownership::is_authorized_by_owner(&self.id, &tx_authority::begin(ctx)), ENO_OWNER_AUTH);

        // Ensures that the aution has not ended
        assert!(clock::timestamp_ms(clock) <= self.ends_at, EAUCTION_ALREADY_ENDED);

        //Ensures that the auction has not been canceled
        assert!(!self.is_canceled, EAUCTION_ALREADY_CANCELED);

        if(option::is_some(&self.highest_bidder)) {
            let coin = coin::from_balance(balance::withdraw_all(&mut self.highest_bid), ctx);
            transfer::public_transfer(coin, option::extract(&mut self.highest_bidder));
        };

        self.is_canceled = true
    }

    public fun simple_finish_auction<T, C>(self: &mut Auction<T, C>, item: &mut UID, clock: &Clock, ctx: &mut TxContext) {
        // Ensures that the item uses the correct market
        assert!(self.market_address == tx_authority::type_into_address<SimpleTransfer>(), EMARKET_MISMATCH);

        // Ensures that the item to transfer is the same as the auctioned item
        assert!(object::uid_to_inner(item) == self.item_id, EITEM_MISMATCH);

        //Ensures that the auction has not been canceled
        assert!(!self.is_canceled, EAUCTION_ALREADY_CANCELED);

        // Ensures that the aution has ended
        assert!(clock::timestamp_ms(clock) > self.ends_at, EAUCTION_NOT_ENDED);

        if(option::is_some(&self.highest_bidder)) {
            // TODO: Transfer the item to the highest bidder.
            let highest_bidder = option::extract(&mut self.highest_bidder);
            let new_owner = vector::singleton(highest_bidder);
            simple_transfer::transfer(item, new_owner, ctx);


            // Transfer the highest bid to the auction creator
            let coin = coin::from_balance(balance::withdraw_all(&mut self.highest_bid), ctx);
            let owner = option::destroy_some(ownership::get_owner(&self.id));

            transfer::public_transfer(coin, vector::pop_back(&mut owner))
        };
    }

    public fun royalty_finish_auction<T, C>(self: &mut Auction<T, C>, _royalty: &Royalty<T>, clock: &Clock, ctx: &mut TxContext) {
        // Ensure that the item uses the correct market
        assert!(self.market_address == tx_authority::type_into_address<RoyaltyMarket>(), EMARKET_MISMATCH);

        //Ensures that the auction has not been canceled
        assert!(!self.is_canceled, EAUCTION_ALREADY_CANCELED);

        // Ensures that the aution has ended
        assert!(clock::timestamp_ms(clock) > self.ends_at, EAUCTION_NOT_ENDED);

        if(option::is_some(&self.highest_bidder)) {
            // TODO: Transfer the item to the highest bidder.
            let _highest_bidder = option::extract(&mut self.highest_bidder);

            // Transfer the highest bid to the auction creator
            let coin = coin::from_balance(balance::withdraw_all(&mut self.highest_bid), ctx);
            let owner = option::destroy_some(ownership::get_owner(&self.id));

            transfer::public_transfer(coin, vector::pop_back(&mut owner))
        };
    }

    fun get_market_address(uid: &UID): address {
        let transfer_auth = option::borrow(&ownership::get_transfer_authority(uid));
        let simple_transfer = tx_authority::type_into_address<SimpleTransfer>();
        let royalty_market = tx_authority::type_into_address<RoyaltyMarket>();

        if(vector::contains(transfer_auth, &simple_transfer)) {
            simple_transfer
        } else if(vector::contains(transfer_auth, &royalty_market)) {
            royalty_market
        } else {
            abort EUNRECOGNIZED_MARKET
        }
    }
}

#[test_only]
module auction::auction {

}