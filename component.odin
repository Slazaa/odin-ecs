package ecs

import "core:fmt"

@private
Component_Group :: struct($Comp_T: typeid) {
    components: [dynamic]Comp_T,
    entity_indices: map[Entity]int
}

@private 
component_group_has_entity :: proc(
    component_group: Component_Group($Comp_T),
    entity: Entity
) -> bool {
    return entity in component_group.entity_indices
}

@private 
add_to_component_group :: proc(
    component_grp: ^Component_Group($Comp_T),
    entity: Entity,
    component: Comp_T
) -> Maybe(Error) {
    if component_group_has(component_group^, entity) {
        return .Entity_Already_Has_Component
    }

    append(&component_group.components, component)
    component_group.entity_indices[entity] = len(component_group.components) - 1

    return nil	
}

@private
remove_from_component_group :: proc(
    component_group: ^Component_Group($Comp_T),
    entity: Entity
) -> Maybe(Error) {
    if !component_group_has_entity(component_group^, entity) {
        return .Entity_Does_Not_Have_Component
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

@private
get_from_component_group :: proc(
    component_group: Component_Group($Comp_T),
    entity: Entity
) -> Maybe(^Comp_T) {
    if !component_group_has_entity(component_group, entity) {
        return nil
    }

    return &component_group.components[entity]
}