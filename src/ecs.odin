package ecs

System :: proc(world: ^World)

World :: struct {
	components: Component_Map,
	startup_systems: [dynamic]System,
	systems: [dynamic]System,
	resources: map[typeid]Resource,
	next_entity: Entity
}

init :: proc() -> World {
	return World {
		components = make(Component_Map),
		startup_systems = make([dynamic]System),
		systems = make([dynamic]System),
		resources = make(map[typeid]Resource)
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