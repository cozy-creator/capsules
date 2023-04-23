module composable_game::whitelist {

    // Error enums
    const ENO_CREATE_PERMISSION: u64 = 0;

    struct Character has key {
        id: UID
    }

    struct CREATE {} // permission struct

    // For this to work, the agent calling into this must have CREATE permission from this module's namespace
    public fun create(auth: &TxAuthority, ctx: &mut TxContext): Character {
        assert!(namespace::has_permission<CREATE>(auth), ENO_CREATE_PERMISSION);

        Character { id: object::new(ctx) }
    }

    // For this to work, the agent calling into this must have:
    // (1) namespace::SINGLE_USE permission from this module's namespace
    // (2) CREATE permission from this module's namespace
    public fun issue_single_use_token(to: address, auth: &TxAuthority, ctx: &mut TxContext) {
        let token = namespace::create_single_use_permission<CREATE>(auth, ctx);
        transfer::transfer(token, to);
    }
}