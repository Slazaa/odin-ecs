package ecs

Query :: struct {
    includes: []typeid,
    excludes: []typeid,
}

query_next :: proc(query: ^Query) -> Maybe(Entity) {
    panic("TODO")
}