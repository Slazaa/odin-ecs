package ecs

import "core:fmt"

main :: proc() {
	world := init()
	defer deinit(&world)
}