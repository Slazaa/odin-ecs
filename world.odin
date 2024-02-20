package ecs

import "core:fmt"

World :: struct {
    storages: map[typeid]rawptr,
    should_run_init_systems: bool,
    next_entity: Entity,
}

// Initializes a new `World`.
// Deinitialize it with `world_deinit`.
world_init :: proc() -> World {
    return {
        storages = make(map[typeid]rawptr),
        should_run_startup = true,
    }
}

// Deinitiliazes the `World`.
world_deinit :: proc(world: ^World) {
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
        storage_remove(storage, entity)
    }
}

// Returns `true` if the `Component` type is registered.
// Else returns `false`.
world_is_component_registered :: proc(world: World, $Component: typeid) -> bool {
    return contains(world.components, Component)
}

// Returns the `Storage` of `Component`.
world_get_storage :: proc(world: World, $Component: typeid) -> (res: ^Storage(Component), err: Error) {
    if storage_rawptr, ok := world.storages; ok {
        return cast(^Storage(Component))world.components[Component], nil
    }

    return nil, .Component_Not_Registered
}

@private
world_register_component :: proc(world: World, $Component: typeid) -> Maybe(Error) {
    if world_is_component_registered(world, Component) {
        return .Component_Already_Registered
    }

    storage := new(Storage(Component))
    storage^ = storage_init()

    world.storages[Component] = storage
}

// Returns `true` if the `Entity` of the `World` has the `Component`.
// Else returns `false`.
world_entity_has_component :: proc(world: World, entity: Entity, $Component: typeid) -> bool {
    storage := (^Storage(Component))(world.storages[Component])
    return storage_has(storage, entity)
}

// Adds a `Component` to an `Entity` of a `World`.
world_add_entity_component :: proc(world: World, entity: Entity, component: $Component) -> Maybe(Error) {
    if world_is_component_registered(world, Component) {
        world_register_component(world)
    }

    storage := world_get_storage(world, Component) or_return

    storage_add(storage, entity, component)
}

// Removes a `Compoent` of an `Entity`.
remove_entity_component :: proc(
    world: ^World,
    entity: Entity,
    $Comp_T: typeid,
) -> Maybe(Error) {
    return remove_from_component_group(
        (^Component_Group(Comp_T))(world.components[Comp_T]),
        entity,
    )
}

world_remove_entity_component :: proc(world: World, entity: $Component: typeid) -> Maybe(Error) {
    storage := world_get_storage(world, Component) or_return
    return storage_remove(storage, entity)
}