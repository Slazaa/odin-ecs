package ecs

Component :: any

Component_Type_And_Entity :: struct {
	component_type: typeid,
	entity: Entity
}

Component_Group :: map[Component_Type_And_Entity]Component

Component_And_Entity :: struct($Comp_T: typeid) {
	component: Comp_T,
	entity: Entity
}

add_component :: proc(components: ^Component_Group, entity: Entity, component: any) {
	components[Component_Type_And_Entity { component.id, entity }] = component
}

remove_component :: proc(components: ^Component_Group, $Comp_T: typeid, entity: Entity) {
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

query_components :: proc(components: Component_Group, $Comp_T: typeid) -> (query: [dynamic]Component_And_Entity(Comp_T)) {
	query = make([dynamic]Component_And_Entity(Comp_T))

	for component_type_and_entity, component in components {
		if component_type_and_entity.component_type == Comp_T {
			append(&query, Component_And_Entity(Comp_T) { component.(Comp_T), component_type_and_entity.entity })
		}
	}

	return
}

query_component :: proc(components: Component_Group, $Comp_T: typeid, entity: Entity) -> Maybe(Comp_T) {
	for component_type_and_entity, component in components {
		if
			component_type_and_entity.component_type == Comp_T &&
			component_type_and_entity.entity == entity
		{
			return component.(Comp_T)
		}
	}

	return nil
}