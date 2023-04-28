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

Entity :: distinct uint

World :: struct {
	components: map[typeid]rawptr,
	startup_schedule: Maybe(Schedule),
	schedule: Schedule,
	ending_schedule: Schedule,
	resources: map[typeid]rawptr,
	next_entity: Entity
}

// World

/// Initialize a new `World`.
/// 
/// # Examples
///
/// ```odin
/// world := init()
/// defer deinit()
/// ```
init_world :: proc() -> World {
	return {
		components = make(map[typeid]rawptr),
		startup_schedule = init_schedule(),
		schedule = init_schedule(),
		ending_schedule = init_schedule(),
		resources = make(map[typeid]rawptr)
	}
}

/// Deinitialize the ECS
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

run_world :: proc(world: ^World) {
	run_schedule(&world.schedule, world)
}

run_world_startup :: proc(world: ^World) {
	run_schedule(&world.startup_schedule.?, world)
	deinit_schedule(&world.startup_schedule.?)
	world.startup_schedule = nil
}

// Entity
spawn_entity :: proc(world: ^World) -> (entity: Entity) {
	entity = world.next_entity
	world.next_entity += 1

	return
}

despawn_entity :: proc(world: ^World, entity: Entity) {
	for _, component_group in world.components {
		remove_from_component_group(cast(^Component_Group(struct{}))component_group, entity)
	}
}

// Component
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

has_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> bool {
	return component_group_has(cast(^Component_Group(Comp_T))world.components[Comp_T], entity)
}

add_component :: proc(world: ^World, entity: Entity, component: $Comp_T) -> Maybe(Error) {
	register_component(world, Comp_T)
	return add_to_component_group(cast(^Component_Group(Comp_T))world.components[Comp_T], entity, component)
}

remove_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> Maybe(Error) {
	return remove_from_component_group((^Component_Group(Comp_T))(world.components[Comp_T]), entity)
}

get_components :: proc(world: ^World, $Comp_T: typeid) -> []Comp_T {
	return (^Component_Group(Comp_T))(world.components[Comp_T]).components[:]
}

get_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> Maybe(^Comp_T) {
	component_group := (^Component_Group(Comp_T))(world.components[Comp_T]);	
	return get_component_from_component_group(component_group, entity)
}

query_components_by_slice :: proc(world: ^World, component_types: []typeid) -> (query: Query) {
	min_len_component_group_typeid: typeid
	min_len_component_group_len := -1

	query = Query {
		components = &world.components,
		entities = make([dynamic]Entity),
		component_types = make([dynamic]typeid),
		current_index = -1
	}

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

query_components :: proc(world: ^World, component_types: ..typeid) -> Query {
	return query_components_by_slice(world, component_types)
}

// System
add_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return add_to_schedule(&world.schedule, system)
}

add_startup_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return add_to_schedule(&world.startup_schedule.?, system)
}

add_ending_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return add_to_schedule(&world.ending_schedule, system)
}

remove_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return remove_from_schedule(&world.schedule, system)
}

remove_startup_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return remove_from_schedule(&world.startup_schedule.?, system)
}

remove_ending_system :: proc(world: ^World, system: System) -> Maybe(Error) {
	return remove_from_schedule(&world.ending_schedule, system)
}

// Resource
has_resource :: proc(world: ^World, $Comp_T: typeid) -> bool {
	return Comp_T in world.resources
}

insert_resource :: proc(world: ^World, resource: $Res_T) -> Maybe(Error) {
	if Res_T in world.resources {
		return .Resource_Already_Exists
	}

	new_resource := new(Res_T)
	new_resource^ = resource


	world.resources[Res_T] = new_resource

	return nil
}

remove_resource :: proc(world: ^World, $Res_T: typeid) -> Maybe(Error) {
	if !(Res_T in world.resources) {
		return .Resource_Does_Not_Exit
	}

	delete_key(&world.resources, Res_T)

	return nil
}

get_resource :: proc(world: ^World, $Res_T: typeid) -> Maybe(^Res_T) {
	if !(Res_T in world.resources) {
		return nil
	}

	return cast(^Res_T)world.resources[Res_T]
}