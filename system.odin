package ecs

import "core:slice"
import "core:container/small_array"

System :: proc(world: ^World)
System_Group :: map[System]struct{ }

remove_system :: proc(systems: ^System_Group, system: System) {
	if system in systems {
		delete_key(systems, system)
	}
}