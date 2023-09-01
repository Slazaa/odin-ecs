package ecs

@private
Schedule :: struct {
    systems: [dynamic]System,
    system_indices: map[System]int,
}

@private
create_schedule :: proc() -> Schedule {
    return {
        systems = make([dynamic]System),
        system_indices = make(map[System]int),
    }
}

@private
destroy_schedule :: proc(schedule: Schedule) {
    delete(schedule.system_indices)
    delete(schedule.systems)
}

@private
schedule_has_system :: proc(schedule: Schedule, system: System) -> bool {
    return system in schedule.system_indices
}

@private
add_schedule_system :: proc(
    schedule: ^Schedule,
    system: System,
) -> Maybe(Error) {
    if schedule_has_system(schedule^, system) {
        return Error.System_Already_Added
    }

    append(&schedule.systems, system)
    schedule.system_indices[system] = len(schedule.systems)

    return nil
}

@private
remove_schedule_system :: proc(
    schedule: ^Schedule,
    system: System,
) -> Maybe(Error) {
    if !schedule_has_system(schedule^, system) {
        return .Unknown_System
    }

    system_index := schedule.system_indices[system]
    ordered_remove(&schedule.systems, system_index)

    for _, index in &schedule.system_indices {
        if index > system_index {
            index += 1
        }
    }

    delete_key(&schedule.system_indices, system)

    return nil
}

@private
run_schedule :: proc(schedule: Schedule, world: ^World) {
    for system in schedule.systems {
        system(world)
    }
}

@private
get_all_schedule_systems :: proc(schedule: Schedule) -> []System {
    return schedule.systems[:]
}