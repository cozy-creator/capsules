module sui_utils::linked_table2 {
    use std::option;
    use std::vector;

    use sui::balance::{Self, Balance};
    use sui::linked_table::{Self, LinkedTable};

    // Will retrieve keys while preserving their order
    public fun keys<K: store + copy + drop, V: store>(self: &LinkedTable<K, V>): vector<K> {
        let key_list = vector[];
        let key_maybe = linked_table::front(self);
        while (option::is_some(key_maybe)) {
            let key = *option::borrow(key_maybe);
            vector::push_back(&mut key_list, key);
            key_maybe = linked_table::next(self, key);
        };
        
        key_list
    }

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