package ecs

import "core:slice"

Resource :: any
Resource_Group :: map[typeid]Resource

add_resource :: proc(resources: ^Resource_Group, resource: any) {
	resources[resource.id] = resource
}

remove_resource :: proc(resources: ^Resource_Group, $Res_T: typeid) {
	if Res_T in resources {
		delete_key(resources, Res_T)
	}
}

query_resource :: proc(resources: ^Resource_Group, $Res_T: typeid) -> Maybe(Res_T) {
	resource, ok := resources[Res_T]
	return resource.(Res_T) if ok else nil
}