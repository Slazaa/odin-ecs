package ecs

import "core:fmt"
import "core:slice"

World :: struct {
    storages: map[typeid]rawptr,
    next_entity: Entity,
}

// Initializes a new `World`.
// Deinitialize it with `world_deinit`.
world_init :: proc() -> World {
    return {
        storages = make(map[typeid]rawptr),
    }
}

// Deinitiliazes the `World`.
world_deinit :: proc(world: World) {
    for _, storage_rawptr in world.storages {
        storage := cast(^Storage(struct{}))storage_rawptr
        free(storage)
    }

    delete(world.storages)
}

// Spawns a new `Entity` into the `World`.
world_spawn :: proc(world: ^World) -> Entity {
    entity := world.next_entity
    world.next_entity += 1

    return entity
}

// Despawns an `Entity` from the `World`.
world_despawn :: proc(world: World, entity: Entity) {
    for _, storage_rawptr in world.storages {
        storage := cast(^Storage(struct{}))storage_rawptr        
        storage_remove_entity(storage, entity)
    }
}

@private
world_get_storage_ptr :: proc(world: World, $Component: typeid) -> Maybe(^Storage(Component)) {
    if storage_rawptr, ok := world.storages[Component]; ok {
        return cast(^Storage(Component))storage_rawptr
    }

    return nil
}

@private
world_get_storage :: proc(world: World, $Component: typeid) -> Maybe(Storage(Component)) {
    if storage_rawptr, ok := world.storages[Component]; ok {
        return (cast(^Storage(Component))storage_rawptr)^
    }

    return nil
}

// Returns `true` if the `Component` type is registered.
// Else returns `false`.
world_is_component_registered :: proc(world: World, $Component: typeid) -> bool {
    return Component in world.storages
}

@private
world_register_component :: proc(world: ^World, $Component: typeid) -> Maybe(Error) {
    if world_is_component_registered(world^, Component) {
        return .Component_Already_Registered
    }

    storage := new(Storage(Component))
    storage^ = storage_init(Component)

    world.storages[Component] = storage

    return nil
}

// Returns `true` if the `Entity` of the `World` has the `Component`.
// Else returns `false`.
world_entity_has_component :: proc(world: World, entity: Entity, $Component: typeid) -> bool {
    if storage, ok := world_get_storage(world, Component); ok {
        return storage_has(storage, entity)
    }

    return false
}

world_get_entity_component :: proc(world: World, entity: Entity, $Component: typeid) -> Maybe(Component) {
    storage, storage_ok := world_get_storage(world, Component).?

    if !storage_ok {
        return nil
    }

    component, component_ok := storage_get_component(storage, entity).?

    if !component_ok {
        return nil
    }

    return component
}

// Adds a `Component` to an `Entity` of a `World`.
world_add_entity_component :: proc(world: ^World, entity: Entity, component: $Component) -> Maybe(Error) {
    if world_is_component_registered(world^, Component) {
        world_register_component(world, Component)
    }

    storage := world_get_storage_ptr(world^, Component).?

    storage_add_component(storage, entity, component)

    return nil
}

// Removes a `Compoent` of an `Entity`.
world_remove_entity_component :: proc(world: World, entity: Entity, $Component: typeid) -> Maybe(Error) {
    storage, storage_ok := world_get_storage_ptr(world, Component).?

    if !storage_ok {
        return Error.Component_Not_Registered
    }

    return storage_remove_entity(storage, entity)
}

world_query :: proc(world: World, includes: []typeid, excludes: []typeid) -> Query {
    panic("TODO")
}