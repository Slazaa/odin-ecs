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

if position, ok := ecs.get_component_by_entity(&world, entity, Position).?; ok {
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