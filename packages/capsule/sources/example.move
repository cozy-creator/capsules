module capsule::example {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct GameItem {
        id: UID,
        power_level: u8
    }

    public fun issue_item(ctx: &mut TxContext): GameItem {
        GameItem {
            id: object::new(ctx),
            power_level: 1
        }
    }
}