package ecs

Error :: enum {
	ENTITY_ALREADY_HAS_COMPONENT,
	ENTITY_DOES_NOT_HAVE_COMPONENT	
}

System :: proc(world: ^World)
Entity :: distinct uint

World :: struct {
	components: map[typeid]rawptr,
	startup_systems: map[System]struct{},
	systems: map[System]struct{},
	next_entity: Entity
}

// World
init :: proc() -> World {
	return World {
		components = make(map[typeid]rawptr),
		startup_systems = make(map[System]struct{}),
		systems = make(map[System]struct{}),
	}
}

deinit :: proc(world: ^World) {
	delete(world.systems)
	
	if world.startup_systems != nil {
		delete(world.startup_systems)
	}

	for _, component_group in world.components {
		delete((^Component_Group(struct{}))(component_group).components)
		delete((^Component_Group(struct{}))(component_group).entity_indices)
		free(component_group)
	}

	delete(world.components)
}

run :: proc(world: ^World) {
	if world.startup_systems != nil {
		for system in world.startup_systems {
			system(world)
		}

		delete(world.startup_systems)
		world.startup_systems = nil
	}

	for system in world.systems {
		system(world)
	}
}

// Entity
spawn :: proc(world: ^World) -> (entity: Entity) {
	entity = world.next_entity
	world.next_entity += 1

	return
}

despawn :: proc(world: ^World, entity: Entity) {
	for _, component_group in world.components {
		remove_from_component_group(cast(^Component_Group(struct{}))component_group, entity)
	}
}

// Component
has_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> bool {
	component_group_has(cast(^Component_Group(Comp_T))world.components[Comp_T], entity)
}

add_component :: proc(world: ^World, entity: Entity, component: $Comp_T) -> Error {
	register_component(world, Comp_T)
	return add_to_component_group(cast(^Component_Group(Comp_T))world.components[Comp_T], entity, component)
}

remove_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> Error {
	return remove_from_component_group((^Component_Group(Comp_T))(world.components[Comp_T]), entity)
}

query_components :: proc(world: ^World, $Comp_T: typeid) -> []Comp_T {
	return (^Component_Group(Comp_T))(world.components[Comp_T]).components[:]
}

query_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> Maybe(Comp_T) {
	component_group := (^Component_Group(Comp_T))(world.components[Comp_T]);	

	if !(entity in component_group.entity_indices) {
		return nil
	}

	return component_group.components[component_group.entity_indices[entity]]
}

// System
add_system :: proc(world: ^World, system: System) {
	world.systems[system] = { }
}

add_startup_system :: proc(world: ^World, system: System) {
	world.startup_systems[system] = { }
}

remove_system :: proc(world: ^World, system: System) {
	delete_key(&world.systems, system)
}

remove_startup_system :: proc(world: ^World, system: System) {
	delete_key(&world.startup_systems, system)
}