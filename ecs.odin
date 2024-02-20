package ecs

Error :: enum {
    Entity_Already_In_Storage,
    Entity_Not_In_Storage,
    System_Already_Added,
    Unknown_System,
}

Entity :: distinct uint
System :: proc(world: ^World)
