module sui_utils::linked_table2 {
    use sui::balance::{Self, Balance};
    use sui::linked_table;

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
        
        while (!linked_table::is_empty(table)) {
            let (_, balance) = linked_table::pop_front(table);
            balance::join(&mut returned_balance, balance);
        };
        linked_table::destroy_empty(table);

        returned_balance
    }
}