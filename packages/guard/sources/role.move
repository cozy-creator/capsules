module guard::role {
    use sui::vec_map::VecMap;
    use sui::tx_context::TxContext;

    use guard::guard::Guard;

    struct Role {
        authority: address,
        roles: VecMap<vector<u8>, vector<address>>
    }

    public fun create<T>(_guard: &mut Guard<T>, _authority: address) {}

    public fun grant<T>(_guard: &mut Guard<T>, _role: vector<u8>, _account: address) {}

    public fun has<T>(_guard: &Guard<T>, _role: vector<u8>, _account: address) {}

    public fun revoke<T>(_guard: &Guard<T>, _role: vector<u8>, _account: address) {}

    public fun renounce<T>(_guard: &Guard<T>, _role: vector<u8>, _ctx: &mut TxContext) {}
}