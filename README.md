A simple Entity Component System written in Odin.

## World
```odin
world := ecs.create_world()
defer ecs.destroy_world(&world)

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
ecs.add_entity_component(&world, entity, Position { 10, 10 })

// Querying components
query := query_world_components(&world, Position, Velocity)
defer destroy_query(&query)

for query_next(&query) {
	entity := get_query_entity(&query)
	position := get_query_component(&query, Position)
	velocity := get_query_component(&query, Velocity)

	// ...
}

// Removing a component
ecs.remove_entity_component(&world, entity, Position)
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
ecs.add_world_startup_system(&world, hello_system)
ecs.add_world_system(&world, spam_system)

// Removing a system
ecs.remove_world_startup_system(&world, hello_system)
ecs.remove_world_system(&world, spam_system)
```

## Resource
```odin
My_Res :: distinct int

// ...

// Adding a resource
add_world_resource(&world, My_Res(10))

// Getting a resource
if res, ok := get_world_resource(&world, My_Res); ok {
	// ...
}

// Remove a resource
remove_world_resource(&world, My_Res)
```