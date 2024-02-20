A simple ECS written in Odin.

## World
```odin
world := ecs.world_init()
defer ecs.world_deinit(&world)

// Updates the world
ecs.world_update(&world)
```

## Entity
```odin
// Spawning entities
entity := ecs.world_spawn(&world)

// Despawning entities
ecs.world_despawn(&world, entity)
```

## Component
```odin
Position :: struct { x, y: int }

// Adding components
ecs.world_add_component(&world, entity, Position{10, 10})

// Getting components
if position, ok := world_get_component(world, entity, Position).?; ok {
    // ...
}

// Querying components
query := world_query(&world, []typeid{Position, Velocity}, []typeid{})

for entity, ok := query_next(&query).?; ok {
    position := world_get_component(world, Position)
    velocity := world_get_component(world, Velocity)
}

// Removing a component
ecs.world_remove_component(&world, entity, Position)
```