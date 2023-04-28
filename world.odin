package ecs

import "core:fmt"

Error :: enum {
	Entity_Already_Has_Component,
	Entity_Does_Not_Have_Component,
	Resource_Already_Exists,
	Resource_Does_Not_Exit,
	System_Already_Added,
	Unknown_System
}

// An `Entity` represents an object in a `World`.
Entity :: distinct uint

// A `System` is a procedure that represents a logic of a `World`.
System :: proc(world: ^World)

// A `Resource` is a piece of data that can be accessed at any time.
Resource :: rawptr

// A `World` holds `Component`'s, `Entity`'s and `System`'s.
World :: struct {
	components: map[typeid]rawptr,
	startup_schedule: Maybe(Schedule),
	schedule: Schedule,
	ending_schedule: Schedule,
	resources: map[typeid]Resource,
	next_entity: Entity
}

// Initializes a new `World`.
// 
// # Examples
//
// ```
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
// ```
init_world :: proc() -> World {
	return {
		components = make(map[typeid]rawptr),
		startup_schedule = init_schedule(),
		schedule = init_schedule(),
		ending_schedule = init_schedule(),
		resources = make(map[typeid]rawptr)
	}
}

// Runs every ending system of a `World` and then deinitiliaze it.
//
// # Examples
//
// ```
// world := ecs.init_world()
// ecs.deinit_world(&world)
// ```
deinit_world :: proc(world: ^World) {
	for system in get_all_from_schedule(&world.ending_schedule) {
		system(world)
	}

	deinit_schedule(&world.ending_schedule)
	deinit_schedule(&world.schedule)
	
	if world.startup_schedule != nil {
		deinit_schedule(&world.startup_schedule.?)
	}

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
// If `run_world_startup` were not called beofore this procedure, it will be called.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_system(&world, hello_system)
//
// for {
// 	ecs.run_world(&world)
// }
// ```
run_world :: proc(world: ^World) {
	if world.startup_schedule != nil {
		run_world_startup(world)
	}

	run_schedule(&world.schedule, world)
}

// Runs every startup `System` of a `World` and then remove the startup systems.
// This procedure should only be called once for a given `World`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_startup_system(&world, hello_system)
//
// ecs.run_world_startup(&world)
// ```
run_world_startup :: proc(world: ^World) {
	run_schedule(&world.startup_schedule.?, world)
	deinit_schedule(&world.startup_schedule.?)
	world.startup_schedule = nil
}

// Spawns an entity into a `World`.
//
// # Examples
//
// ```
// world := ecs.init_world()
// ecs.defer deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ```
spawn_entity :: proc(world: ^World) -> (entity: Entity) {
	entity = world.next_entity
	world.next_entity += 1

	return
}

// Despawns an entity of a `World`
//
// # Examples
//
// ```
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.despawn_entity(&world, entity)
// ```
despawn_entity :: proc(world: ^World, entity: Entity) {
	for _, component_group in world.components {
		remove_from_component_group(cast(^Component_Group(struct{}))component_group, entity)
	}
}

@private
register_component :: proc(world: ^World, $Comp_T: typeid) {
	if Comp_T in world.components {
		return
	}

	world.components[Comp_T] = new(Component_Group(Comp_T))
	
	component_group := cast(^Component_Group(Comp_T))world.components[Comp_T]

	component_group^ = {
		components = make([dynamic]Comp_T),
		entity_indices = make(map[Entity]int)
	}
}

@private
has_component_by_typeid :: proc(world: ^World, entity: Entity, component_type: typeid) -> bool {
	return component_group_has(cast(^Component_Group(struct{}))world.components[component_type], entity)
}

// Returns `true` if the `Entity` of the `World` has the `Component`.
//
// # Examples
//
// ```
// Position :: sturct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// ecs.add_component_to_entity(&world, entity, Position { 10, 10 })
//
// assert(ecs.entity_has_component(&world, entity, Position)) 
// ```
entity_has_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> bool {
	return component_group_has(cast(^Component_Group(Comp_T))world.components[Comp_T], entity)
}

// Adds a `Component` to an `Entity` of a `World`.
//
// # Examples
//
// ```
// Position :: struct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// ecs.add_component_to_entity(&world, entity, Position { 10, 10 })
// ```
add_component_to_entity :: proc(world: ^World, entity: Entity, component: $Comp_T) -> Maybe(Error) {
	register_component(world, Comp_T)
	return add_to_component_group(cast(^Component_Group(Comp_T))world.components[Comp_T], entity, component)
}

// Removes a `Compoent` of an `Entity`.
//
// # Examples
//
// ```
// Position :: struct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// ecs.add_component_to_entity(&world, entity, Position { 10, 10 })
// ecs.remove_component_from_entity(&world, entity, Position)
// ```
remove_component_from_entity :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> Maybe(Error) {
	return remove_from_component_group((^Component_Group(Comp_T))(world.components[Comp_T]), entity)
}

@private
query_components_by_slice :: proc(world: ^World, component_types: []typeid) -> (query: Query) {
	min_len_component_group_typeid: typeid
	min_len_component_group_len := -1

	query = init_query(world)

	for type in component_types {
		component_group := (^Component_Group(struct{}))(world.components[type])

		if min_len_component_group_typeid == nil || len(component_group.components) < min_len_component_group_len {
			min_len_component_group_typeid = type 
			min_len_component_group_len = len(component_group.components)
		}

		append(&query.component_types, type)
	}

	min_len_component_group := (^Component_Group(struct{}))(world.components[min_len_component_group_typeid])

	entity_loop: for entity, _ in min_len_component_group.entity_indices {
		for	type in component_types {
			if type == min_len_component_group_typeid {
				continue
			}

			if !(entity in (^Component_Group(struct{}))(world.components[type]).entity_indices) {
				continue entity_loop
			}
		}

		append(&query.entities, entity)
	}

	return
}

// Queries the `Component`'s of a `World`.
//
// # Examples
//
// ```
// Position :: struct { x, y: int }
// Velocity :: struct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
//
// add_component_to_entity(&world, entity, Position { 10, 10 })
// add_component_to_entity(&world, entity, Velocity { 10, 10 })
//
// query := query_components(&world, Position, Velocity)
// ```
query_components :: proc(world: ^World, component_types: ..typeid) -> Query {
	return query_components_by_slice(world, component_types)
}

// Returns `true` if the `World` has the `System`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_system(&world, hello_system)
//
// assert(ecs.has_system(&world, hello_system))
// ```
has_system :: proc(world: ^World, system: System) -> bool {
	return schedule_has(&world.schedule, system)
}

// Returns `true` if the `World` has the startup `System`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_startup_system(&world, hello_system)
//
// assert(ecs.has_startup_system(&world, hello_system))
// ```
has_startup_system :: proc(world: ^World, system: System) -> bool {
	return schedule_has(&world.startup_schedule.?, system)
}

// Returns `true` if the `World` has the ending `System`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_ending_system(&world, hello_system)
//
// assert(ecs.has_ending_system(&world, hello_system))
// ```
has_ending_system :: proc(world: ^World, system: System) -> bool {
	return schedule_has(&world.schedule, system)
}

// Adds a `System` to a `World`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_system(&world, hello_system)
// ```
add_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return add_to_schedule(&world.schedule, system)
}

// Adds a startup `System` to a `World`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_startup_system(&world, hello_world)
// ```
add_startup_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return add_to_schedule(&world.startup_schedule.?, system)
}

// Adds an ending `System` to a `World`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_ending_system(&world, hello_system)
// ```
add_ending_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return add_to_schedule(&world.ending_schedule, system)
}

// Removes a `System` from a `World`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_system(&world, hello_system)
// ecs.remove_system(&world, hello_system)
//
// assert(!ecs.has_system(&world, hello_system))
// ```
remove_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return remove_from_schedule(&world.schedule, system)
}

// Removes a startup `System` from a `World`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_startup_system(&world, hello_system)
// ecs.remove_startup_system(&world, hello_system)
//
// assert(!ecs.has_startup_system(&world, hello_system))
// ```
remove_startup_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return remove_from_schedule(&world.startup_schedule.?, system)
}

// Removes a ending `System` from a `World`.
//
// # Examples
//
// ```
// hello_system :: proc(world: ^ecs.World) {
// 	fmt.println("Hello!")
// }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.add_ending_system(&world, hello_system)
// ecs.remove_ending_system(&world, hello_system)
//
// assert(!ecs.has_ending_system(&world, hello_system))
// ```
remove_ending_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return remove_from_schedule(&world.ending_schedule, system)
}

// Returns `true` if the `World` has the `Resource`.
//
// # Examples
//
// ```
// Res :: distinct int
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.insert_resource(&world, Res(10))
//
// assert(ecs.has_resource(&world, Res))
// ```
has_resource :: proc(world: ^World, $Comp_T: typeid) -> bool {
	return Comp_T in world.resources
}

// Returns `true` if the `World` has the `Resource`.
//
// # Examples
//
// ```
// Res :: distinct int
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.insert_resource(&world, Res(10))
//
// assert(ecs.has_resource(&world, Res))
// ```
insert_resource :: proc(world: ^World, resource: $Res_T) -> Maybe(Error) {
	if Res_T in world.resources {
		return .Resource_Already_Exists
	}

	new_resource := new(Res_T)
	new_resource^ = resource


	world.resources[Res_T] = new_resource

	return nil
}

// Removes a `Resource` from a `World`.
//
// # Examples
//
// ```
// Res :: distinct int
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.insert_resource(&world, Res(10))
// ecs.remove_resource(&world, Res)
//
// assert(!ecs.has_resource(&world, Res))
// ```
remove_resource :: proc(world: ^World, $Res_T: typeid) -> Maybe(Error) {
	if !(Res_T in world.resources) {
		return .Resource_Does_Not_Exit
	}

	delete_key(&world.resources, Res_T)

	return nil
}

// Returns the `Resource` from a `World`.
//
// # Examples
//
// ```
// Res :: distinct int
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// ecs.insert_resource(&world, Res(10))
// res := ecs.get_resource(&world, Res)
// ```
get_resource :: proc(world: ^World, $Res_T: typeid) -> Maybe(^Res_T) {
	if !(Res_T in world.resources) {
		return nil
	}

	return cast(^Res_T)world.resources[Res_T]
}