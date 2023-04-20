package ecs

Component :: any

Component_Type_And_Entity :: struct {
	component_type: typeid,
	entity: Entity
}

Component_Group :: map[Component_Type_And_Entity]Component

add_component :: proc(components: ^Component_Group, entity: Entity, component: any) {
	components[Component_Type_And_Entity { component.id, entity }] = component
}

remove_component :: proc(components: ^Component_Group, entity: Entity, $Comp_T: typeid) {
	for component_type_and_entity, _ in components {
		if
			component_type_and_entity.component_type == Comp_T &&
			component_type_and_entity.entity == entity
		{
			delete_key(components, component_type_and_entity)
			break
		}
	}
}

query_component :: proc(components: Component_Group, $Comp_T: typeid) -> (query: [dynamic]Comp_T) {
	query = make([dynamic]Comp_T)

	for component_type_and_entity, component in components {
		if component_type_and_entity.component_type == Comp_T {
			append(&query, component.(Comp_T))
		}
	}

	return
}