package ecs 

// A `Query` represents `Component`'s with a common `Entity`.
Query :: struct {
	components: ^map[typeid]rawptr,
	entities: [dynamic]Entity,
	component_types: [dynamic]typeid,
	current_index: int
}

@private
init_query :: proc(world: ^World) -> Query {
	return {
		components = &world.components,
		entities = make([dynamic]Entity),
		component_types = make([dynamic]typeid),
		current_index = -1
	}
}

// Deinitializes a `Query`.
//
// # Examples
//
// ```
// Position :: struct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.add_component_to_entity(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// ecs.deinit_query(&query)
deinit_query :: proc(query: ^Query) {
	delete(query.component_types)
	delete(query.entities)
}

// Go to the next `Component` group.
//
// # Examples
// ```
// Position :: struct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.add_component_to_entity(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// defer ecs.deinit_query(&query)
//
// ecs.query_next(&query)
// position := ecs.get_component_from_query(&query, Position)
query_next :: proc(query: ^Query) -> bool {
	query.current_index += 1
	return query.current_index < len(query.entities)
}

// Returns the `Entity` of the current `Component` group.
//
// # Examples
// ```
// Position :: struct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.add_component_to_entity(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// defer ecs.deinit_query(&query)
//
// ecs.query_next(&query)
// queried_entity := ecs.get_entity_from_query(&query)
get_entity_from_query :: proc(query: ^Query) -> Entity {
	return query.entities[query.current_index]
}

// Returns the `Component` from a `Query`.
//
// # Examples
// ```
// Position :: struct { x, y: int }
//
// world := ecs.init_world()
// defer ecs.deinit_world(&world)
//
// entity := ecs.spawn_entity(&world)
// ecs.add_component_to_entity(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// defer ecs.deinit_query(&query)
//
// ecs.query_next(&query)
// position := ecs.get_component_from_query(&query, Position)
get_component_from_query :: proc(query: ^Query, $Comp_T: typeid) -> Comp_T {
	component_group := (^Component_Group(Comp_T))(query.components[Comp_T]);	
	entity := query.entities[query.current_index]

	assert(entity in component_group.entity_indices, "Invalid component type")

	return component_group.components[component_group.entity_indices[entity]]
}