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

    struct Auction<phantom T, phantom C> has key {
        id: UID,
        // The auctioned item
        item_id: ID,
        // The top bid submitted in the auction
        highest_bid: Balance<C>,
        // The bidder with the highest bid in the auction
        highest_bidder: Option<address>,
        // The minimum bid allowed in the auction
        minimum_bid: u64,
        // The starting date of the auction
        starts_at: u64,
        // The ending date of the auction.
        ends_at: u64
    }

    struct Witness has drop {}

    const ENO_OWNER_AUTH: u64 = 1;
    const EITEM_TYPE_MISMATCH: u64 = 2;
    const EINVALID_TIME_DIFFERENCE: u64 = 3;
    const EINSUFFICIENT_BID: u64 = 4;
    const EAUCTION_NOT_STARTED: u64 = 5;
    const EAUCTION_ALREADY_ENDED: u64 = 6;
    const EALREADY_HIGHEST_BIDDER: u64 = 7;

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
            item_id: object::uid_to_inner(item),
            highest_bidder: option::none(),
            highest_bid: balance::zero(),
            minimum_bid,
            starts_at,
            ends_at
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

        // Ensures that the auction has started
        assert!(current_time > self.starts_at, EAUCTION_NOT_STARTED);

        // Ensures that the aution has not ended
        assert!(current_time < self.ends_at, EAUCTION_ALREADY_ENDED);

        // Ensures that the bid is greater than or equal to the minimum bid allowed
        assert!(coin::value(&bid) >= self.minimum_bid, EINSUFFICIENT_BID);

        // Ensures that the bid is greater than the current highest bid
        assert!(coin::value(&bid) > balance::value(&self.highest_bid), EINSUFFICIENT_BID);

        if(option::is_some(&self.highest_bidder)) {
            // If there is already a highest bidder in place, 
            // we ensure that any new bid is placed by an address different from the current highest bidder.
            assert!(&current_bidder != option::borrow(&self.highest_bidder), EALREADY_HIGHEST_BIDDER);

            // Additionally, we transfer the previous highest bid back to its original bidder.
            let balance = balance::withdraw_all(&mut self.highest_bid);
            let coin = coin::from_balance(balance, ctx);

            transfer::public_transfer(coin, option::extract(&mut self.highest_bidder));
        };

        // Update the auction highest bid with the new bid
        balance::join(&mut self.highest_bid, coin::into_balance(bid));

        // Update the highest bidder with the current bidder
        option::fill(&mut self.highest_bidder, current_bidder);
    }
}