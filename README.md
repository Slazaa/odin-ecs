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
entity := ecs.spawn(&world.next_entity)

// Despawning an entity
ecs.despawn(&world.components, entity)
```

## Component
```odin
Position :: struct { x, y: int }

// ...

// Adding a component
ecs.add_component(&world.components, entity, Position { 10, 10 })

// Querying components
positions := ecs.query_components(world.components, Position)

for position in positions {
	// ...
}

delete(positions)

if position, ok := ecs.query_component(world.components, entity, Position).?; ok {
	// ...
}

// Removing a component
ecs.remove_component(&world.components, entity, Position)
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
ecs.add_system(&world.startup_systems, hello_system)
ecs.add_system(&world.systems, spam_system)

// Removing a system
ecs.remove_system(&world.startup_systems, hello_system)
ecs.remove_system(&world.systems, spam_system)
```

## Resource
```odin
My_Res :: struct { }

// ...

// Adding a resource
ecs.add_resource(&world.resources, My_Res { })

// Querying resources
if resource, ok := ecs.query_resource(world.resources, My_Res); ok {
	// ...
}

// Removing a resource
ecs.remove_resource(&world.resources, My_Res)
```