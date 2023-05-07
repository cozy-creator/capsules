module guard::guard_id {
    const ID_PREFIX: u64 = 19999;

    public fun allow_list(): u64 {
        ID_PREFIX + 1
    }

    public fun coin_payment(): u64 {
        ID_PREFIX + 2
    }
}