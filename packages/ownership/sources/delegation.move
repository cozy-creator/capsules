module ownership::delegation {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use sui_utils::struct_tag::StructTag;

    use ownership::permission::ADMIN;
    use ownership::tx_authority::{Self, TxAuthority};

    // Root-level, shared object. The owner is the principle, and is immutable (non-transferable).
    struct DelegationStore has key {
        id: UID,
        principal: address,
        agent_delegations: VecMap<address, Delegation>,
    }

    // `types` or `objects` being empty means that all types / all object-ids are allowed, in other
    // words, no constraint is imposed.
    // This struct is analgous to RBAC in ownership::organization
    struct Delegation has store, copy, drop {
        permissions: vector<Permission>,
        types: vector<StructTag>,
        objects: vector<ID>
    }

    // ======= For Owners =======

    public fun create(ctx: &mut TxContext): DelegationStore {
        DelegationStore {
            id: object::new(ctx),
            principal: tx_context::sender(ctx),
            agent_delegations: vec_map::empty()
        }
    }

    public fun return_and_share(store: DelegationStore) {
        transfer::share_object(store);
    }

    // This won't work yet, but it will once Sui supports deleting shared objects (late 2023)
    public fun destroy(store: DelegationStore, auth: &TxAuthority) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_OWNER_AUTHORITY);

        let DelegationStore = { id, principal: _, agent_delegations: _ } = store;
        object::delete(id);
    }

    // ======= Modify Agent Permissions =======

    public fun add_permitted_types() {

    }

    public fun add_to_delegation<Permission>(
        store: &mut DelegationStore,
        agent: address,
        permitted_types: vector<StructTag>,
        permitted_objects: vector<ID>,
        auth: &TxAuthority
    ) {
        assert!(tx_authority::has_permission<ADMIN>(store.principal, auth), ENO_OWNER_AUTHORITY);

        let delegation = Delegation {
            permissions: vec![Permission],
            types: vec![],
            objects: vec![]
        };

        vec_map::insert(store.agent_delegations, agent, delegation);
    }

    public fun remove_from_delegation<Permission>() {

    }

    public fun remove_agent() {

    }

    public fun remove_all() {

    }

    // ======= For Agents =======

    public fun claim_delegation(ctx: &mut TxContext): TxAuthority {

    }

    // ======= Convenience Entry Functions =======

}