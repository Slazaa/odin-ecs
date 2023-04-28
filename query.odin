package ecs 

Query :: struct {
	components: ^map[typeid]rawptr,
	entities: [dynamic]Entity,
	component_types: [dynamic]typeid,
	current_index: int
}

init_query :: proc(world: ^World) -> Query {
	return {
		components = &world.components,
		entities = make([dynamic]Entity),
		component_types = make([dynamic]typeid),
		current_index = -1
	}
}

deinit_query :: proc(query: ^Query) {
	delete(query.component_types)
	delete(query.entities)
}

query_next :: proc(query: ^Query) -> bool {
	query.current_index += 1
	return query.current_index < len(query.entities)
}

get_entity_from_query :: proc(query: ^Query) -> Entity {
	return query.entities[query.current_index]
}

get_component_from_query :: proc(query: ^Query, $Comp_T: typeid) -> Comp_T {
	component_group := (^Component_Group(Comp_T))(query.components[Comp_T]);	
	entity := query.entities[query.current_index]

	assert(entity in component_group.entity_indices, "Invalid component type")

	return component_group.components[component_group.entity_indices[entity]]
}