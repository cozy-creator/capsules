module transfer_system::trade_history {



    // Root-level or stored owned object. Stores PairVolume data
    struct TradeHistory has key, store {
        id: UID
    }

    // Trade pair corresponds to (Coin<C>, Type)
    struct PairVolume<C> has store, copy, drop {
        type: StructTag,
        volume: u64,
        last_trade_ms: u64 // millisecond timestamp
    }

    struct Key<C> has store, copy, dropy { 
        type: StructTag
    }

    // Convenience function
    public entry fun create_history(ctx: &mut TxContext){
        transfer::transfer(create_history_(ctx), tx_context::sender(ctx));
    }

    public fun create_history_(ctx: &mut TxContext): TradeHistory {
        TradeHistory {
            id: object::new(ctx)
        }
    }
    
    // ========= Royalty Info Functions =========
    // PairVolume can only be modified by royalty_info::pay_royalty

    friend::royalty_info;

    // We use linear-decay; an exponential-decay is impossible to compute using integer arithmetic
    // pair.volume = pair.volume / math.pow(2, time_diff / DECAY_FACTOR) + price;
    // After 30 days the volume will go to 0
    // This can only be updated through the friend royalty_info::pay_royalty
    public(friend) fun decay<C>(pair: &mut PairVolume<C>, clock: &Clock) {
        let time_diff: u128 = clock::timestamp_ms(clock) - pair.last_trade_ms;
        let vol = pair.volume;
        pair.volume = vol - math::min(vol, (((vol as u128) * time_diff / MONTH_MS) as u64));
    }

    public(friend) fun record_trade<C>(price: u64, pair: &mut PairVolume<C>, clock: &Clock) {
        pair.last_trade_ms = clock::timestamp_ms(clock);
        pair.volume += price;
    }

    public(friend) fun borrow_mut<C, T>(history: &mut TradeHistory): &mut PairVolume<C> {
        borrow_mut_(history, struct_tag::get<T>())
    }

    public(friend) fun borrow_mut_<C>(history: &mut TradeHistory, type: StructTag): &mut PairVolume<C> {
        dynamic_field2::borrow_mut_fill(&mut history.id, Key<C> { type }, PairVolume<C> { type, volume: 0, last_trade_ms: 0 })
    }

    // ====== Getter Functions ======

    public fun get<C, Type>(history: &TradeHistory): PairVolume<C> {
        get_<C>(history, struct_tag::get<Type>())
    }

    public fun get_<C>(history: &TradeHistory, type: StructTag): PairVolume<C> {
        let key = Key<C> { type };
        dynamic_field2::get_with_default(&history.id, key, PairVolume<C> { type, volume: 0, last_trade_ms: 0 })
    }

    public fun volume<C>(pair: &PairVolume<C>): u64 {
        pair.volume
    }

    public fun breakdown<C>(pair: &PairVolume<C>): (StructTag, u64, u64) {
        (pair.type, pair.volume, pair.last_trade_ms)
    }
}