package ecs

Resource :: any

query_resource :: proc(
	world_resources: ^map[typeid]Resource,
	$Res_T: typeid
) -> Maybe(Res_T) {
	resource, ok := world_resources[Res_T]
	return resource.(Res_T) if ok else nil
}

add_resource :: proc(
	world_resources: ^map[typeid]Resource,
	resource: any
) {
	world_resources[resource.id] = resource
}