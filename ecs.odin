package ecs

Error :: enum {
    Component_Already_Registered,
    Entity_Already_In_Storage,
    Entity_Not_In_Storage,
}

Entity :: distinct uint