A simple Entity Component System written in Odin.

## World
```odin
world := ecs.init()
defer ecs.deinit(&world)

// ...

// Run a tick
ecs.run(&world)
```

## Entity
```odin
// ...

// Spawning an entity
entity := ecs.spawn(&world)

// Despawning an entity
ecs.despawn(&world, entity)
```

## Component
```odin
Position :: struct { x, y: int }

// ...

// Adding a component
ecs.add_component(&world, entity, Position { 10, 10 })

// Getting components
positions := ecs.get_components(&world, Position)

for position in positions {
	// ...
}

delete(positions)

if position, ok := ecs.get_component(&world, entity, Position).?; ok {
	// ...
}

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
ecs.remove_component(&world, entity, Position)
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