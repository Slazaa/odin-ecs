package ecs

System :: proc(world: ^World)

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