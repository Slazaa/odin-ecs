package ecs

World :: struct {
	components: Component_Group,
	startup_systems: System_Group,
	systems: System_Group,
	resources: Resource_Group,
	next_entity: Entity
}

init :: proc() -> World {
	return World {
		components = make(Component_Group),
		startup_systems = make(System_Group),
		systems = make(System_Group),
		resources = make(Resource_Group)
	}
}

deinit :: proc(world: ^World) {
	delete(world.resources)
	delete(world.systems)
	
	if world.startup_systems != nil {
		delete(world.startup_systems)
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