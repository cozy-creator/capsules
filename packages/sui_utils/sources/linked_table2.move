module sui_utils::linked_table2 {
    use sui::balance::{Self, Balance};
    use sui::linked_table::{Self, LinkedTable};

    public fun borrow_mut_fill<K: store + copy + drop, V: store + drop>(
        self: &mut LinkedTable<K, V>,
        key: K,
        default_value: V
    ): &mut V {
        if (!linked_table::contains(self, key)) {
            linked_table::push_back(self, key, default_value);
        };

        linked_table::borrow_mut(self, key)
    }

    public fun merge_balance<K: copy + drop + store, T>(
        table: &mut LinkedTable<K, Balance<T>>,
        key: K,
        balance: Balance<T>
    ) {
        if (linked_table::contains(table, key)) {
            let existing_balance = linked_table::borrow_mut(table, key);
            balance::join(existing_balance, balance);
        } else {
            linked_table::push_back(table, key, balance);
        };
    }

    public fun collapse_balance<K: copy + drop + store, T>(table: LinkedTable<K, Balance<T>>): Balance<T> {
        let returned_balance = balance::zero();

        while (!linked_table::is_empty(&table)) {
            let (_, balance) = linked_table::pop_front(&mut table);
            balance::join(&mut returned_balance, balance);
        };
        linked_table::destroy_empty(table);

        returned_balance
    }
}