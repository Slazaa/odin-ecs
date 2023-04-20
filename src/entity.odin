package ecs

Entity :: distinct uint

spawn :: proc(next_entity: ^Entity) -> (entity: Entity) {
	entity = next_entity^
	next_entity^ += 1

	return
}

despawn :: proc(components: ^Component_Map, entity: Entity) {
	for component_type_and_entity, _ in components {
		if component_type_and_entity.entity == entity {
			delete_key(components, component_type_and_entity)
		}
	}		
}