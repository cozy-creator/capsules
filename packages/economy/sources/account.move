module economy::account {
    use sui::object::UID;

    struct Account has key {
        id: UID
    }

    struct WITHDRAW {}
}