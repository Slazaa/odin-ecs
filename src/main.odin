package ecs

import "core:fmt"

Position :: struct { x, y: uint }

main :: proc() {
	world := init()
	defer deinit(&world)

	run(&world)
}