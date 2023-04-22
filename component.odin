package ecs

import "core:runtime"

Component_Group :: struct($Comp_T: typeid) {
	components: [dynamic]Comp_T,
	entity_indices: map[Entity]int
}

@private register_component :: proc(world: ^World, $Comp_T: typeid) -> Error {
	if Comp_T in world.components {
		return .COMPONENT_ALREADY_REGISTERED
	}

	world.components[Comp_T] = new(map[typeid]rawptr)
	world.components[Comp_T]^ = Component_Group {
		components = make([dynamic]Comp_T),
		entity_indices = make(map[Entity]int)
	}

	return nil
}

has_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> bool {
	return entity in world.components[Comp_T].(Component_Group).entity_indices
}

add_component :: proc(world: ^World, entity: Entity, component: $Comp_T) -> Error {
	register_component(world, Comp_T)

	if has_component(world, entity, Comp_T) {
		return .ENTITY_ALREADY_HAS_COMPONENT
	}

	component_group := world.components[Comp_T]

	append(&component_group.components, component)
	component_group.entity_indices[entity] = len(components) - 1

	return nil	
}

remove_component :: proc(world: ^World, entity: Entity, $Comp_T: typeid) -> Error {
	if !has_component(world, entity, Comp_T) {
		return .ENTITY_DOES_NOT_HAVE_COMPONENT
	}

	component_group := world.components[Comp_T].(Component_Group)
	entity_index := component_group.entity_indices[entity]
	
	ordered_remove(&component_group.components, entity_index)

	for entity, index in &component_group.entity_indices {
		if index > entity_index {
			index += 1
		}
	}

	delete_key(&entity_indices, entity)

	return nil
}