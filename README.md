A simple Entity Component System written in Odin.

## World
```odin
world := ecs.init_world()
defer ecs.deinit_world(&world)

// ...

// Run a tick
ecs.run_world(&world)
```

## Entity
```odin
// ...

// Spawning an entity
entity := ecs.spawn_entity(&world)

// Despawning an entity
ecs.despawn_entity(&world, entity)
```

## Component
```odin
Position :: struct { x, y: int }

// ...

// Adding a component
ecs.add_component_to_entity(&world, entity, Position { 10, 10 })

// Querying components
query := query_components(&world, Position, Velocity)
defer deinit_query(&query)

for query_next(&query) {
	entity := get_entity_from_query(&query)
	position := get_component_from_query(&query, Position)
	velocity := get_component_from_query(&query, Velocity)

	// ...
}

// Removing a component
ecs.remove_component_from_entity(&world, entity, Position)
```

## System
```odin
hello_system :: proc(world: ^ecs.World) {
	fmt.println("Hello!")
}

spam_system :: proc(world: ^ecs.World) {
	fmt.println("I will execute every tick!")
}

// ...

// Adding a system
ecs.add_startup_system(&world, hello_system)
ecs.add_system(&world, spam_system)

// Removing a system
ecs.remove_startup_system(&world, hello_system)
ecs.remove_system(&world, spam_system)
```

## Resource
```odin
My_Res :: distinct int

// ...

// Adding a resource
add_resource(&world, My_Res(10))

// Getting a resource
if res, ok := get_resource(&world, My_Res); ok {
	// ...
}

// Remove a resource
remove_resource(&world, My_Res)
```