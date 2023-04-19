package ecs

Entity :: distinct uint
Component :: distinct rawptr
System :: proc(world: ^World)
Resource :: distinct rawptr

World :: struct {
	components: map[typeid]map[Entity]Component,
	startup_systems: [dynamic]System,
	systems: [dynamic]System,
	resources: map[typeid]Resource,
	next_entity: Entity
}

init :: proc() -> World {
	return World {
		components = make(map[typeid]map[Entity]Component),
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

spawn :: proc(world: ^World) -> (entity: Entity) {
	entity = world.next_entity
	world.next_entity += 1

	return
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