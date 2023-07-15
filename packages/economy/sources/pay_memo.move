// Event broadcast module for simple payments, making it easy for merchants to find out when
// their payment-requests have been filled.
//
// Instructions for merchants:
// Use suix_subscribe event, then query this module (package, module-name, struct-name) and
// filter by 'MoveEventField' for '/reference', filtering for the reference-id you used to
// identify the transaction.

module economy::pay_memo {
    use std::string::String;

    use sui::event;
    use sui::object::ID;

    // Event
    struct PayMemo has copy, drop {
        reference_id: ID,
        merchant: String,
        description: String
    }

    public entry fun emit(reference_id: ID, merchant: String, description: String) {
        event::emit(PayMemo { reference_id, merchant, description });
    }

}