package ecs 

// A `Query` represents `Component`'s with an `Entity` in common.
Query :: struct {
    components: ^map[typeid]rawptr,
    entities: [dynamic]Entity,
    component_types: [dynamic]typeid,
    current_index: int,
}

@private
create_query :: proc(world: ^World) -> Query {
    return {
        components = &world.components,
        entities = make([dynamic]Entity),
        component_types = make([dynamic]typeid),
        current_index = -1,
    }
}

// Destroy a `Query`.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn(&world)
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// ecs.destroy_query(&query)
// ```
destroy_query :: proc(query: Query) {
    delete(query.component_types)
    delete(query.entities)
}

// Go to the next `Component` group.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn(&world)
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// defer ecs.destroy_query(&query)
//
// ecs.query_next(&query)
// position := ecs.get_entity_component(&query, Position)
// ```
query_next :: proc(query: ^Query) -> bool {
    query.current_index += 1
    return query.current_index < len(query.entities)
}

// Returns the `Entity` of the current `Component` group.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn(&world)
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// defer ecs.destroy_query(&query)
//
// ecs.query_next(&query)
// queried_entity := ecs.get_query_entity(&query)
// ```
get_query_entity :: proc(query: Query) -> Entity {
    return query.entities[query.current_index]
}

// Returns the `Component` from a `Query`.
//
// # Examples
//
// ```odin
// Position :: struct { x, y: int }
//
// world := ecs.create_world()
// defer ecs.destroy_world(&world)
//
// entity := ecs.spawn(&world)
// ecs.add_entity_component(&world, entity, Position { 10, 10 })
//
// query := ecs.query_components(&world, Position)
// defer ecs.destroy_query(&query)
//
// ecs.query_next(&query)
// position := ecs.get_query_component(&query, Position)
// ```
get_query_component :: proc(query: Query, $Comp_T: typeid) -> ^Comp_T {
    comp_grp := (^Component_Group(Comp_T))(query.components[Comp_T])	
    entity := query.entities[query.current_index]

    assert(entity in comp_grp.entity_indices, "Invalid component type")

    return &comp_grp.components[comp_grp.entity_indices[entity]]
}