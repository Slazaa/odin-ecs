package ecs

System :: proc(world: ^World)
System_Group :: map[System]struct{}

add_system :: proc(systems: ^System_Group, system: System) {
	systems[system] = { }
}

remove_system :: proc(systems: ^System_Group, system: System) {
	delete_key(systems, system)
}