module transfer_system::trade_history {
    use sui::clock::{Self, Clock};
    use sui::math;

    use sui_utils::struct_tag::{Self, StructTag};
    use sui_utils::dynamic_field2;

    use transfer_system::market_account::{Self, MarketAccount};

    // Constants
    const MONTH_MS: u128 = 2_592_000_000; // 30 days in milliseconds


    // Trade pair corresponds to (Coin<C>, Type)
    struct PairVolume<phantom C> has store, copy, drop {
        type: StructTag,
        volume: u64,
        last_trade_ms: u64 // millisecond timestamp
    }

    struct Key<phantom C> has store, copy, drop { 
        type: StructTag
    }

    // ========= Royalty Info Functions =========
    // PairVolume can only be modified by royalty_info::pay_royalty

    friend transfer_system::royalty_info;

    // We use linear-decay; an exponential-decay is impossible to compute using integer arithmetic
    // pair.volume = pair.volume / math.pow(2, time_diff / DECAY_FACTOR) + price;
    // After 30 days the volume will go to 0
    // This can only be updated through the friend royalty_info::pay_royalty
    public(friend) fun decay<C>(pair: &mut PairVolume<C>, clock: &Clock) {
        let time_diff = (clock::timestamp_ms(clock) - pair.last_trade_ms as u128);
        let vol = pair.volume;
        pair.volume = vol - math::min(vol, (((vol as u128) * time_diff / MONTH_MS) as u64));
    }

    public(friend) fun record_trade<C>(price: u64, pair: &mut PairVolume<C>, clock: &Clock) {
        pair.last_trade_ms = clock::timestamp_ms(clock);
        pair.volume = pair.volume + price;
    }

    public(friend) fun borrow_mut<C, T>(account: &mut MarketAccount): &mut PairVolume<C> {
        borrow_mut_(account, struct_tag::get<T>())
    }

    public(friend) fun borrow_mut_<C>(account: &mut MarketAccount, type: StructTag): &mut PairVolume<C> {
        let account_uid = market_account::extend(account);
        dynamic_field2::borrow_mut_fill(account_uid, Key<C> { type }, PairVolume<C> { type, volume: 0, last_trade_ms: 0 })
    }

    // ====== Getter Functions ======

    public fun get<C, Type>(account: &MarketAccount): PairVolume<C> {
        get_<C>(account, struct_tag::get<Type>())
    }

    public fun get_<C>(account: &MarketAccount, type: StructTag): PairVolume<C> {
        let key = Key<C> { type };
        let account_uid = market_account::uid(account);
        dynamic_field2::get_with_default(account_uid, key, PairVolume<C> { type, volume: 0, last_trade_ms: 0 })
    }

    public fun volume<C>(pair: &PairVolume<C>): u64 {
        pair.volume
    }

    public fun breakdown<C>(pair: &PairVolume<C>): (StructTag, u64, u64) {
        (pair.type, pair.volume, pair.last_trade_ms)
    }
}