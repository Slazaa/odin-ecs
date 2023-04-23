package ecs

import "core:fmt"

Component_Group :: struct($Comp_T: typeid) {
	components: [dynamic]Comp_T,
	entity_indices: map[Entity]int
}

@private 
component_group_has :: proc(component_group: ^Component_Group($Comp_T), entity: Entity) -> bool {
	return entity in component_group.entity_indices
}

@private 
add_to_component_group :: proc(component_group: ^Component_Group($Comp_T), entity: Entity, component: Comp_T) -> Error {
	if component_group_has(component_group, entity) {
		return .ENTITY_ALREADY_HAS_COMPONENT
	}

	append(&component_group.components, component)
	component_group.entity_indices[entity] = len(component_group.components) - 1

	return nil	
}

@private
remove_from_component_group :: proc(component_group: ^Component_Group($Comp_T), entity: Entity) -> Error {
	if !component_group_has(component_group, entity) {
		return .ENTITY_DOES_NOT_HAVE_COMPONENT
	}

	entity_index := component_group.entity_indices[entity]
	
	ordered_remove(&component_group.components, entity_index)

	for _, index in &component_group.entity_indices {
		if index > entity_index {
			index += 1
		}
	}

	delete_key(&component_group.entity_indices, entity)

	return nil
}