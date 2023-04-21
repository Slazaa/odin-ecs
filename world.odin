package ecs

Error :: enum {
	COMPONENT_ALREADY_REGISTERED,
	ENTITY_ALREADY_HAS_COMPONENT,
	ENTITY_DOES_NOT_HAVE_COMPONENT	
}

World :: struct {
	components: map[typeid]Component_Group,
	startup_systems: map[System]struct{},
	systems: map[System]struct{},
	resources: map[typeid]Resource,
	next_entity: Entity
}

init :: proc() -> World {
	return World {
		components = make(map[typeid]Component_Group),
		startup_systems = make(map[System]struct{}),
		systems = make(map[System]struct{}),
		resources = make(map[typeid]Resource)
	}
}

deinit :: proc(world: ^World) {
	delete(world.resources)
	delete(world.systems)
	
	if world.startup_systems != nil {
		delete(world.startup_systems)
	}

	for _, component_group in world.components {
		free(component_group.components.data)
		delete(component_group.components)
		delete(component_group.entity_indices)
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