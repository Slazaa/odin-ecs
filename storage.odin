package ecs

import "core:fmt"
import "core:slice"

@private
Storage :: struct($Component: typeid) {
    components: [dynamic]Component,
    entities: [dynamic]Entity,
}

@private
storage_init :: proc($Component: typeid) -> Storage(Component) {
    return {
        components = make([dynamic]Component),
        entities = make([dynamic]Entity),
    }
}

@private
storage_deinit :: proc(storage: Storage($Component)) {
    delete(storage.entities)
    delete(storage.components)
}

@private
storage_has_entity :: proc(storage: Storage($Component), entity: Entity) -> bool {
    return slice.contains(storage.entities[:], entity)
}

@private 
storage_add_component :: proc(storage: ^Storage($Component), entity: Entity, component: Component) -> Maybe(Error) {
    if storage_has_entity(storage^, entity) {
        return .Entity_Already_In_Storage
    }

    append(&storage.components, component)
    append(&storage.entities, entity)

    return nil
}

@private
storage_get_entity_index :: proc(storage: Storage($Component), entity: Entity) -> (res: int, err: Error) {
    for i in 0..<len(storage.entities) {
        if storage.entities[i] == entity {
            return i, nil
        }
    }

    return 0, Error.Entity_Not_In_Storage
}

@private
storage_remove_entity :: proc(storage: ^Storage($Component), entity: Entity) -> Maybe(Error) {
    if !storage_has_entity(storage^, entity) {
        return Error.Entity_Not_In_Storage
    }

    entity_index := storage_get_entity_index(storage^, entity) or_return

    ordered_remove(&storage.components, entity_index)
    ordered_remove(&storage.entities, entity_index)

    return nil
}

@private
storage_get_component :: proc(storage: Storage($Component), entity: Entity) -> Maybe(Component) {
    entity_index, err := storage_get_entity_index(storage, entity)

    if err != nil {
        return nil
    }

    return storage.components[entity_index]
}

@private
storage_get_component_ptr :: proc(storage: Storage($Component), entity: Entity) -> Maybe(^Component) {
    entity_index, err := storage_get_entity_index(storage, entity)

    if err != nil {
        return nil
    }

    return &storage.components[entity_index]
}