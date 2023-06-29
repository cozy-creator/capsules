// Note that queue itself does not enforce any rules on who can deposit and withdraw; a person with a mutable
// reference to `Queue<T>` can deposit or withdraw to any address. That is, queue relies entirely upon
// referential authority for its security.
//
// Should we add these restrictions in? Or should we leave it up to the Fund program to enforce?
//
// Ideally Queue would be a pure data-type; I wish we didn't need to use ctx or generate object-ids
// to create it.

module economy::queue {
    use sui::balance::{Self, Balance, Supply};
    use sui::tx_context::TxContext;
    use sui::linked_table::{Self as map, LinkedTable as Map};

    use sui_utils::linked_table2 as map2;

    // Incoming is a map of depositors to deposits to be processed
    // Balance is a pool of active funds
    // Outoing is a map of people owed money to the funds they can claim
    struct Queue<phantom T> has store {
        incoming: Map<address, Balance<T>>,
        reserve: Balance<T>,
        outgoing: Map<address, Balance<T>>
    }

    // ======== Creation / Deletion API =========

    public fun new<T>(ctx: &mut TxContext): Queue<T> {
        Queue {
            incoming: map::new<address, Balance<T>>(ctx),
            reserve: balance::zero<T>(),
            outgoing: map::new<address, Balance<T>>(ctx)
        }
    }

    // Merges all Balance<T> into one and returns it, even if it's empty
    public fun destroy<T>(queue: Queue<T>): Balance<T> {
        let return_balance = balance::zero();

        let Queue { incoming, reserve, outgoing } = queue;

        balance::join(&mut return_balance, map2::collapse_balance(incoming));
        balance::join(&mut return_balance, reserve);
        balance::join(&mut return_balance, map2::collapse_balance(outgoing));

        return_balance
    }

    // Aborts if any Balance<T> is greater than 0
    public fun destroy_empty<T>(queue: Queue<T>) {
        let Queue { incoming, reserve, outgoing } = queue;

        map::destroy_empty(incoming);
        balance::destroy_zero(reserve);
        map::destroy_empty(outgoing);
    }

    // ======== Queue API =========

    public fun deposit<T>(queue: &mut Queue<T>, addr: address, balance: Balance<T>) {
        map2::merge_balance(&mut queue.incoming, addr, balance);
    }

    // Cancels a pending deposit and returns the funds
    // Returns nothing if there is no pending deposit
    public fun cancel_deposit<T>(queue: &mut Queue<T>, addr: address): Balance<T> {
        if (map::contains(&queue.incoming, addr)) {
            map::remove(&mut queue.incoming, addr)
        } else {
            balance::zero()
        }
    }

    // We withdraw everything; there's no point in leaving fractional values in queue
    public fun withdraw<T>(queue: &mut Queue<T>, addr: address): Balance<T> {
        if (map::contains(&queue.outgoing, addr)) {
            map::remove(&mut queue.outgoing, addr)
        } else {
            balance::zero()
        }
    }

    // ======== Direct API =========

    public fun direct_deposit<T>(queue: &mut Queue<T>, balance: Balance<T>) {
        balance::join(&mut queue.reserve, balance);
    }

    public fun direct_withdraw<T>(queue: &mut Queue<T>, amount: u64): Balance<T> {
        balance::split(&mut queue.reserve, amount)
    }

    // ======== Process Queue =========

    // Moves q_a.incoming -> balance, mint `S` with `supply` -> q_s.outgoing
    public fun deposit_input_mint_output<S, A>(
        q_a: &mut Queue<A>,
        q_s: &mut Queue<S>,
        asset_size: u64,
        share_size: u64,
        supply: &mut Supply<S>
    ): u64 {
        let deposits = 0;

        while (!map::is_empty(&q_a.incoming)) {
            // deposit incoming funds
            let (user, balance) = map::pop_front(&mut q_a.incoming);
            let balance_value = balance::value(&balance);
            balance::join(&mut q_a.reserve, balance);
            deposits = deposits + balance_value;

            // mint outgoing shares
            let share_amount = ratio_conversion(balance_value, share_size, asset_size);
            let shares = balance::increase_supply(supply, share_amount);
            map2::merge_balance(&mut q_s.outgoing, user, shares);
        };

        deposits
    }

    // q_s incoming -> burn with `supply`, q_a balance -> q_a outgoing
    // If q_a.reserve is not sufficient to cover redeeming shares, this process will stop
    // Returns a 'success' boolean, since this will never abort
    public fun burn_input_withdraw_output<S, A>(
        q_a: &mut Queue<A>,
        q_s: &mut Queue<S>,
        asset_size: u64,
        share_size: u64,
        supply: &mut Supply<S>
    ): (bool, u64) {
        let withdrawals = 0;

        while (!map::is_empty(&q_s.incoming)) {
            // withdraw outgoing funds
            let (user, shares) = map::pop_front(&mut q_s.incoming);
            let shares_value = balance::value(&shares);
            let asset_amount = ratio_conversion(shares_value, asset_size, share_size);

            // Check if we've run out of funds for now; stop rather than abort
            if (balance::value(&q_a.reserve) < asset_amount) {
                map::push_front(&mut q_s.incoming, user, shares);
                return (false, withdrawals)
            };
            let balance = balance::split(&mut q_a.reserve, asset_amount);
            map2::merge_balance(&mut q_a.outgoing, user, balance);
            withdrawals = withdrawals + asset_amount;

            // burn incoming shares
            balance::decrease_supply(supply, shares);
        };

        (true, withdrawals)
    }

    // ======== Getters =========

    public fun reserves_available<A>(queue: &Queue<A>): u64 {
        balance::value(&queue.reserve)
    }

    public fun ratio_conversion(amount: u64, numerator: u64, denominator: u64): u64 {
        ((amount as u128) * (numerator as u128) / (denominator as u128) as u64)
    }
}