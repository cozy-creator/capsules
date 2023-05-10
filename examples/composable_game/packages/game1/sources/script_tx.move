// This exists only because Sui does not yet support script transactions

module composable_game::script_tx {
    use composable_game::aircraft_carrier::{Self, Carrier};
    use data::data;

    public fun view_all(carrier: &Carrier, namespace: address): vector<u8> {
        let uid = aircraft_carrier::carrier_uid(carrier);
        data::view_all(uid, namespace)
    }
}