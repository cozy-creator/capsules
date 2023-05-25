module games::capsule_verse {
    const ENO_PERMISSION: u64 = 0;

    struct Capsuleverse has key, store {
        id: UID,
        value: String
    }

    struct EDIT {}

    public fun edit_value(verse: &mut Capsuleverse, new_value: String, auth: &TxAuthority) {
        assert!(ownership::has_owner_permission<EDIT>(&verse.id, auth), ENO_PERMISSION);
        assert!(client::has_owner_permission<EDIT>(&verse.id, auth), ENO_PERMISSION);

        verse.value = new_value;
    }

}