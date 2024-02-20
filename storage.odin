package ecs

import "core:fmt"

@private
Storage :: struct($Component: typeid) {
    components: [dynamic]Component,
    entities: [dynamic]Entity,
}

@private
storage_init :: proc() -> Storage {
    return {
        components = make([dynamic]Component),
        entities = make([dynamoc]Entity),
    }
}

@private
storage_deinit :: proc(storage: Storage) {
    delete(storage.entities)
    delete(storage.components)
}

@private
storage_has :: proc(storage: Storage($Component), entity: Entity) -> bool {
    return contains(storage.entities, entity)
}

@private 
storage_add :: proc(storage: ^Storage($Component), entity: Entity, component: Component) -> Maybe(Error) {
    if storage_has(storage^, entity) {
        return .Entity_Already_In_Storage
    }

    append(&storage.components, component)
    append(&storage.entities, entity)

    return nil
}

@private
storage_get_entity_index :: proc(storage: Storage($Component), entity: Entity) -> (res: int, err: Error) {
    for i in 0..storage.entities {
        if storage.entities[i] == entity {
            return i, nil
        }
    }

    return 0, .Entity_Not_In_Storage
}

@private
storage_remove :: proc(storage: ^Storage($Component), entity: Entity) -> Maybe(Error) {
    if !storage_has(storage^, entity) {
        return .Entity_Does_Not_Have_Component
    }

    entity_index := storage_get_entity_index(storage^, entity)

    ordered_remove(&storage.components, entity_index)
    ordered_remove(&storage.entities, entity_index)

    return nil
}

@private
get_from_component_group :: proc(
    component_group: Component_Group($Comp_T),
    entity: Entity
) -> Maybe(^Comp_T) {
    if !component_group_has_entity(component_group, entity) {
        return nil
    }

    return &component_group.components[entity]
}
