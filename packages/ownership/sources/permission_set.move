// This is an internal module used by tx_authority and delegations

module ownership::permission_set {
    use sui::object::ID;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::struct_tag::StructTag;

    use ownership::permission::{Self, Permission};

    friend ownership::tx_authority;
    friend ownership::delegation;

    // TO DO: Is `copy` + `store` a security vulnerability? Can someone get ahold of this, store it,
    // and use it maliciously later?
    struct PermissionSet has store, copy, drop {
        general: vector<Permission>,
        on_types: VecMap<StructTag, vector<Permission>>,
        on_objects: VecMap<ID, vector<Permission>>
    }

    public(friend) fun empty(): PermissionSet {
        PermissionSet {
            general: vector[],
            on_types: vec_map::empty(),
            on_objects: vec_map::empty()
        }
    }

    public(friend) fun new(contents: vector<Permission>): PermissionSet {
        PermissionSet {
            general: contents,
            on_types: vec_map::empty(),
            on_objects: vec_map::empty()
        }
    }

    public(friend) fun intersection(self: &PermissionSet, filter: &PermissionSet): PermissionSet {
        let general = permission::intersection(&self.general, &filter.general);
        let on_types = permission::vec_map_intersection(
            &self.on_types, &filter.general, &filter.on_types);
        let on_objects = permission::vec_map_intersection(
            &self.on_objects, &filter.general, &filter.on_objects);
        
        PermissionSet { general, on_types, on_objects }
    }

    // This ensures that permissions are not improperly overwritten
    public(friend) fun merge(self: &mut PermissionSet, new: PermissionSet) {
        let PermissionSet { general, on_types, on_objects } = new;
        permission::add(&mut self.general, general);
        permission::vec_map_add(&mut self.on_types, on_types);
        permission::vec_map_add(&mut self.on_objects, on_objects);
    }

    // ======== Field Accessors ========

    public fun general(set: &PermissionSet): &vector<Permission> {
        &set.general
    }

    public fun types(set: &PermissionSet): &VecMap<StructTag, vector<Permission>> {
        &set.on_types
    }

    public fun objects(set: &PermissionSet): &VecMap<ID, vector<Permission>> {
        &set.on_objects
    }

    public(friend) fun general_mut(set: &mut PermissionSet): &mut vector<Permission> {
        &mut set.general
    }

    public(friend) fun types_mut(set: &mut PermissionSet): &mut VecMap<StructTag, vector<Permission>> {
        &mut set.on_types
    }

    public(friend) fun objects_mut(set: &mut PermissionSet): &mut VecMap<ID, vector<Permission>> {
        &mut set.on_objects
    }
}