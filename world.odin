package ecs

import "core:fmt"

// A `World` holds `Component`'s, `Entity`'s and `System`'s.
World :: struct {
    components: map[typeid]rawptr,
    startup_schedule: Schedule,
    schedule: Schedule,
    ending_schedule: Schedule,
    resources: map[typeid]Resource,
    should_run_startup: bool,
    next_entity: Entity,
}

// Creates a new `World`.
// 
// # Examples
//
// ```odin
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
// ```
create_world :: proc() -> World {
    return {
        components = make(map[typeid]rawptr),
        startup_schedule = create_schedule(),
        schedule = create_schedule(),
        ending_schedule = create_schedule(),
        resources = make(map[typeid]rawptr),
        should_run_startup = true,
    }
}

// Runs every ending system of a `World` and then destroy it.
//
// # Examples
//
// ```odin
// world := ecs.create_world()
// ecs.destroy_world(&world)
// ```
destroy_world :: proc(world: ^World) {
    for system in get_all_schedule_systems(world.ending_schedule) {
        system(world)
    }

    destroy_schedule(world.ending_schedule)
    destroy_schedule(world.schedule)
    destroy_schedule(world.startup_schedule)

    for _, resource in world.resources {
        free(resource)
    }

    delete(world.resources)	

    for _, component_group in world.components {
        delete((^Component_Group(struct{}))(component_group).components)
        delete((^Component_Group(struct{}))(component_group).entity_indices)
        free(component_group)
    }

    delete(world.components)
}

// Runs every `System` of a `World` once.
// If `run_world_startup` were not called beofore this procedure,
// it will be called.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_system(&world, hello_system)
//
// for {
//     ecs.run_world(&world)
// }
// ```
run_world :: proc(world: ^World) {
    if world.should_run_startup {
        run_world_startup(world);
    }

    run_schedule(world.schedule, world)
}

// Runs every startup `System` of a `World` and then remove the startup systems.
// This procedure should only be called once for a given `World`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_startup_system(&world, hello_system)
//
// ecs.run_world_startup(&world)
// ```
run_world_startup :: proc(world: ^World) {
    run_schedule(world.startup_schedule, world)
    world.should_run_startup = false
}

// spawn_entitys an entity into a `World`.
//
// # Examples
//
// ```odin
// world := ecs.create_world()
// ecs.defer destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ```
spawn_entity :: proc(world: ^World) -> (entity: Entity) {
    entity = world.next_entity
    world.next_entity += 1

    return
}

// Despawn_entitys an entity of a `World`
//
// # Examples
//
// ```odin
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.despawn_entity(&world, entity)
// ```
despawn_entity :: proc(world: ^World, entity: Entity) {
    for _, component_group in world.components {
        remove_from_component_group(
            cast(^Component_Group(struct{}))component_group,
            entity,
        )
    }
}

// Returns `true` if the `Component` type is registered.
//
// # Examples
//
// ```odin
// Position :: sturct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.add_entity_component(&world, entity, Position)
//
// assert(is_component_registered(world, Position))
// ```
is_component_registered :: proc(world: World, $Comp_T: typeid) -> bool {
    return Comp_T in world.components	
}

@private
register_component :: proc(world: ^World, $Comp_T: typeid) {
    if is_component_registered(world^, Comp_T) {
        return
    }

    world.components[Comp_T] = new(Component_Group(Comp_T))
    
    component_group := cast(^Component_Group(Comp_T))world.components[Comp_T]

    component_group^ = Component_Group(Comp_T) {
        components = make([dynamic]Comp_T),
        entity_indices = make(map[Entity]int),
    }
}

// Returns `true` if the `Entity` of the `World` has the `Component`.
//
// # Examples
//
// ```odin
// Position :: sturct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
//
// assert(ecs.entity_has_component(world, entity, Position)) 
// ```
entity_has_component :: proc(
    world: World, entity: Entity,
    $Comp_T: typeid,
) -> bool {
    return component_group_has(
        (^Component_Group(Comp_T))(world.components[Comp_T]),
        entity,
    )
}

// Adds a `Component` to an `Entity` of a `World`.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
// ```
add_entity_component :: proc(
    world: ^World,
    entity: Entity,
    component: $Comp_T
) -> Maybe(Error) {
    register_component(world, Comp_T)

    return add_to_component_group(
        (^Component_Group(Comp_T))(world.components[Comp_T]),
        entity,
        component,
    )
}

// Removes a `Compoent` of an `Entity`.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
// ecs.remove_entity_component(&world, entity, Position)
// ```
remove_entity_component :: proc(
    world: ^World,
    entity: Entity,
    $Comp_T: typeid
) -> Maybe(Error) {
    return remove_from_component_group(
        (^Component_Group(Comp_T))(world.components[Comp_T]),
        entity,
    )
}

// Returns the `Component`'s of the `Component` type.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
//
// positions := ecs.get_world_components(world, Position)
// ```
get_world_components :: proc(world: World, $Comp_T: typeid) -> Maybe([]Comp_T) {
    if !is_component_registered(world, Comp_T) {
        return nil
    }

    return (^Component_Group(Comp_T))(world.components[Comp_T]).components[:]
}

// Queries the `Component`'s of a `World`.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
// Velocity :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// add_entity_component(&world, entity, Position { 10, 10 })
// add_entity_component(&world, entity, Velocity { 10, 10 })
//
// query := query_components(&world, Position, Velocity)
// ```
query_components :: proc(
    world: ^World,
    component_types: ..typeid
) -> (query: Query) {
    min_len_comp_grp_type: typeid
    min_len_comp_grp_len := -1

    query = create_query(world)

    for type in component_types {
        comp_grp := (^Component_Group(struct{}))(world.components[type])

        if 
            min_len_comp_grp_type == nil ||
            len(comp_grp.components) < min_len_comp_grp_len
        {
            min_len_comp_grp_type = type 
            min_len_comp_grp_len = len(comp_grp.components)
        }

        append(&query.component_types, type)
    }

    min_len_comp_grp := (^Component_Group(struct{}))(
        world.components[min_len_comp_grp_type],
    )

    entity_loop: for entity, _ in min_len_comp_grp.entity_indices {
        for	type in component_types {
            if type == min_len_comp_grp_type {
                continue
            }

            if !(entity in (^Component_Group(struct{}))(
                world.components[type],
            ).entity_indices) {
                continue entity_loop
            }
        }

        append(&query.entities, entity)
    }

    return
}

// Returns `true` if the `World` has the `System`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_system(&world, hello_system)
//
// assert(ecs.world_has_system(&world, hello_system))
// ```
world_has_system :: proc(world: World, system: System) -> bool {
    return schedule_has_system(world.schedule, system)
}

// Returns `true` if the `World` has the startup `System`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_startup_system(&world, hello_system)
//
// assert(ecs.world_has_startup_system(&world, hello_system))
// ```
world_has_startup_system :: proc(world: World, system: System) -> bool {
    return schedule_has_system(world.startup_schedule, system)
}

// Returns `true` if the `World` has the ending `System`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_ending_system(&world, hello_system)
//
// assert(ecs.world_has_ending_system(&world, hello_system))
// ```
world_has_ending_system :: proc(world: World, system: System) -> bool {
    return schedule_has_system(world.schedule, system)
}

// Adds a `System` to a `World`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_system(&world, hello_system)
// ```
add_world_system :: proc(world: ^World, system: System) -> Maybe(Error) {
    return add_schedule_system(&world.schedule, system)
}

// Adds a startup `System` to a `World`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_startup_system(&world, hello_world)
// ```
add_world_startup_system :: proc(world: ^World, system: System) -> Maybe(Error) {
    return add_schedule_system(&world.startup_schedule, system)
}

// Adds an ending `System` to a `World`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_ending_system(&world, hello_system)
// ```
add_world_ending_system :: proc(world: ^World, system: System) -> Maybe(Error) {
    return add_schedule_system(&world.ending_schedule, system)
}

// Removes a `System` from a `World`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_system(&world, hello_system)
// ecs.remove_world_system(&world, hello_system)
//
// assert(!ecs.world_has_system(&world, hello_system))
// ```
remove_world_system :: proc(world: ^World, system: System) -> Maybe(Error) {
    return remove_schedule_system(&world.schedule, system)
}

// Removes a startup `System` from a `World`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_startup_system(&world, hello_system)
// ecs.remove_world_startup_system(&world, hello_system)
//
// assert(!ecs.world_has_startup_system(&world, hello_system))
// ```
remove_world_startup_system :: proc(
    world: ^World,
    system: System,
) -> Maybe(Error) {
    return remove_schedule_system(&world.startup_schedule, system)
}

// Removes a ending `System` from a `World`.
//
// # Examples
//
// ```odin
// hello_system :: proc(world: ^ecs.World) {
//     fmt.println("Hello!")
// }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_ending_system(&world, hello_system)
// ecs.remove_world_ending_system(&world, hello_system)
//
// assert(!ecs.has_world_ending_system(&world, hello_system))
// ```
remove_world_ending_system :: proc(
    world: ^World,
    system: System,
) -> Maybe(Error) {
    return remove_schedule_system(&world.ending_schedule, system)
}

// Returns `true` if the `World` has the `Resource`.
//
// # Examples
//
// ```odin
// Res :: distinct int
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.insert_resource(&world, Res(10))
//
// assert(ecs.world_has_resource(&world, Res))
// ```
world_has_resource :: proc(world: World, $Comp_T: typeid) -> bool {
    return Comp_T in world.resources
}

// Returns `true` if the `World` has the `Resource`.
//
// # Examples
//
// ```odin
// Res :: distinct int
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_resource(&world, Res(10))
//
// assert(ecs.world_has_resource(&world, Res))
// ```
add_world_resource :: proc(world: ^World, res: $Res_T) -> Maybe(Error) {
    if Res_T in world.resources {
        return .Resource_Already_Exists
    }

    new_res := new(Res_T)
    new_res^ = res


    world.resources[Res_T] = new_res

    return nil
}

// Removes a `Resource` from a `World`.
//
// # Examples
//
// ```odin
// Res :: distinct int
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_resource(&world, Res(10))
// ecs.remove_world_resource(&world, Res)
//
// assert(!ecs.world_has_resource(&world, Res))
// ```
remove_world_resource :: proc(world: ^World, $Res_T: typeid) -> Maybe(Error) {
    if !(Res_T in world.resources) {
        return .Resource_Does_Not_Exist
    }

    delete_key(&world.resources, Res_T)

    return nil
}

// Returns the `Resource` from a `World`.
//
// # Examples
//
// ```odin
// Res :: distinct int
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// ecs.add_world_resource(&world, Res(10))
// res := ecs.get_world_resource(&world, Res)
// ```
get_world_resource :: proc(world: World, $Res_T: typeid) -> Maybe(^Res_T) {
    if !(Res_T in world.resources) {
        return nil
    }

    return (^Res_T)(world.resources[Res_T])
}