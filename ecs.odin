package ecs

Error :: enum {
    Entity_Already_Has_Component,
    Entity_Does_Not_Have_Component,
    Resource_Already_Exists,
    Resource_Does_Not_Exist,
    System_Already_Added,
    Unknown_System,
}

// An `Entity` represents an object in a `World`.
Entity :: distinct uint

// A `System` is a procedure that represents a logic of a `World`.
System :: proc(world: ^World)

// A `Resource` is a piece of data that can be accessed at any time.
Resource :: rawptr