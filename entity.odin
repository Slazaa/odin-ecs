package ecs

Entity :: distinct uint

spawn :: proc(world: ^World) -> (entity: Entity) {
	entity = world.next_entity
	world.next_entity += 1

	return
}

despawn :: proc(world: ^World, entity: Entity) {
	for _, component_group in world.components {

	}
}