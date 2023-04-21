package ecs

import "core:runtime"

Component_Group :: struct {
	components_type: typeid,
	components: ^runtime.Raw_Dynamic_Array,
	entity_indices: map[Entity]uint
}

@private register_component :: proc(world: ^World, $Comp_T: typeid) -> Error {
	if Comp_T in world.components {
		return .COMPONENT_ALREADY_REGISTERED
	}

	world.components[Comp_T] = {
		components_type = Comp_T,
		components = cast(^runtime.Raw_Dynamic_Array)new([dynamic]Comp_T)
	}

	world.components[Comp_T].components = make([dynamic]Comp_T)

	return nil
}

has_component :: proc(world: ^World, entity: Entity, component_type: typeid) -> bool {
	return entity in world.components[component_type].entity_indices
}

add_component :: proc(world: ^World, entity: Entity, component: $Comp_T) -> Error {
	if !(Comp_T in world.components) {
		register_component(world, Comp_T)
	}

	if has_component(world, entity, Comp_T) {
		return .ENTITY_ALREADY_HAS_COMPONENT
	}

	component_group := world.components[Comp_T]
	components := cast(^[dynamic]Comp_T)component_group.components

	append(components, component)
	component_group.entity_indices[entity] = len(components) - 1

	return nil	
}

remove_component :: proc(world: ^World, entity: Entity, component_type: typeid) -> Error {
	if !has_component(world, entity, component_type) {
		return .ENTITY_DOES_NOT_HAVE_COMPONENT
	}

	component_group := world.components[component_type]
	index := component_group.entity_indices[entity]

	component_type_size := type_info_of(component_type).size		

	components := component_group.components.data
	entity_indices := component_group.entity_indices

	delete_key(&entity_indices, entity)

	return nil
}