A simple ECS written in Odin.

## World
```odin
world := ecs.world_init()
defer ecs.world_deinit(&world)
```

## Entity
```odin
// Spawning entities
entity := ecs.world_spawn(&world)

// Despawning entities
ecs.world_despawn(world, entity)
```

## Component
```odin
Position :: struct { x, y: int }

// Adding components
ecs.world_add_component(&world, entity, Position { 10, 10 })

// Getting components
if position, ok := ecs.world_get_component(world, entity, Position).?; ok {
    // ...
}

// Removing a component
ecs.world_remove_component(&world, entity, Position)
```

## Queries
```odin
// Querying components
query := ecs.world_query(&world, []typeid{Position, Velocity}, []typeid{})

for entity, ok := ecs.query_next(&query).?; ok {
    position := ecs.world_get_component(world, Position, entity)
    velocity := ecs.world_get_component(world, Velocity, entity)
}
```