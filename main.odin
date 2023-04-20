package ecs

My_Res :: struct { }

main :: proc() {
	world := init()
	defer deinit(&world)

	add_resource(&world.resources, My_Res { })	
	remove_resource(&world.resources, My_Res)

	run(&world)
}