module script_tx::display_creator {
    use std::option::Option;
    use std::string::String;

    use attach::data;

    use display::creator::{Self, Creator};
    
    use ownership::tx_authority::TxAuthority;

    // ========= attach::data API =========
    public fun deserialize_and_set_(
        creator: &mut Creator,
        namespace: Option<address>,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        auth: &TxAuthority
    ) {
        let uid = creator::uid_mut(creator, auth);
        data::deserialize_and_set_(uid, namespace, data, fields, auth);
    }

    public fun remove(
        creator: &mut Creator,
        namespace: Option<address>,
        keys: vector<String>,
        auth: &TxAuthority
    ) {
        let uid = creator::uid_mut(creator, auth);
        data::remove(uid, namespace, keys, auth);
    }
}