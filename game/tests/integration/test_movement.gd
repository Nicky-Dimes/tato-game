extends TestCase
## Tato's basic movement, played for real in small rooms with simulated input.

const FLAT := [
	"                                        ",
	" @                                      ",
	"########################################",
	"########################################",
]


func test_spawns_standing_on_the_ground() -> void:
	var level := await open_text_level(room(FLAT))
	var p := level.player
	check(p.is_on_floor(), "Tato is on the floor after spawning")
	check_near(p.global_position.y, floor_y(level, 2), 2.0, "feet rest on top of the ground row")
	check_eq(p.state, Tato.State.IDLE, "state is IDLE")
	check_eq(GameState.hearts, GameState.MAX_HEARTS, "starts with five hearts")


func test_walks_then_runs() -> void:
	var level := await open_text_level(room(FLAT))
	var p := level.player
	var x0 := p.global_position.x
	Input.action_press("move_right")
	await frames(20)
	check_near(absf(p.velocity.x), Tato.WALK_SPEED, 6.0, "reaches walk speed")
	check_eq(p.state, Tato.State.WALK, "state is WALK")
	check_gt(p.global_position.x - x0, 45.0, "moved right")
	await frames(50)
	check_near(absf(p.velocity.x), Tato.RUN_SPEED, 8.0, "breaks into a run after holding the direction")
	check_eq(p.state, Tato.State.RUN, "state is RUN")
	Input.action_release("move_right")
	await frames(20)
	check_near(p.velocity.x, 0.0, 1.0, "stops when the direction is released")
	check_eq(p.facing, 1.0, "still facing right")
	Input.action_press("move_left")
	await frames(10)
	check_eq(p.facing, -1.0, "turns to face left")
	Input.action_release("move_left")


func test_jump_height_and_short_hop() -> void:
	var level := await open_text_level(room(FLAT))
	var p := level.player
	var ground := p.global_position.y
	Input.action_press("jump")
	var top := ground
	for i in 60:
		await frames(1)
		top = minf(top, p.global_position.y)
	Input.action_release("jump")
	var full := ground - top
	check_gt(full, 4.0 * Layers.TILE, "the higher held jump clears four tiles (%.0f px)" % full)
	check_lt(full, 5.1 * Layers.TILE, "jump remains controllable below five tiles (%.0f px)" % full)
	await frames(30)
	check(p.is_on_floor(), "lands again")
	# short tap
	ground = p.global_position.y
	await tap("jump")
	top = ground
	for i in 50:
		await frames(1)
		top = minf(top, p.global_position.y)
	var hop := ground - top
	check_lt(hop, full * 0.75, "letting go early gives a clearly lower hop (%.0f vs %.0f)" % [hop, full])
	check_gt(hop, 20.0, "but still a hop")


func test_coyote_time_and_jump_buffer() -> void:
	var rows := [
		"                                        ",
		" @                                      ",
		"########                                ",
		"########                                ",
		"                                        ",
		"                                        ",
		"                                        ",
		"########################################",
	]
	var level := await open_text_level(room(rows))
	var p := level.player
	await place(level, 6.4, 1)
	Input.action_press("move_right")
	# walk until the ground is gone
	for i in 120:
		await frames(1)
		if not p.is_on_floor():
			break
	check(not p.is_on_floor(), "walked off the ledge")
	await frames(3)          # 3 frames = 0.05 s, inside the 0.10 s coyote window
	Input.action_press("jump")
	await frames(2)
	check_lt(p.velocity.y, -500.0, "coyote time: jump still works just after leaving the ledge")
	check_eq(p.flaps_left, Tato.MAX_FLAPS, "that jump was a real jump, not a flap")
	Input.action_release("jump")
	Input.action_release("move_right")
	# buffer: use up the flaps on the way down, then press jump just before landing
	for i in Tato.MAX_FLAPS:
		await frames(8)
		await tap("jump")
	check_eq(p.flaps_left, 0, "all flaps used in the air")
	var pressed := false
	for i in 240:
		await frames(1)
		if not pressed and not p.is_on_floor() and p.velocity.y > 0.0:
			var space := p.get_world_2d().direct_space_state
			var q := PhysicsRayQueryParameters2D.create(p.global_position, p.global_position + Vector2(0, 26), Layers.WORLD)
			if not space.intersect_ray(q).is_empty():
				pressed = true
				check(not p.is_on_floor(), "pressed while still in the air")
				Input.action_press("jump")
		elif pressed and p.velocity.y < -500.0:
			break
	Input.action_release("jump")
	check(pressed, "found the moment just before landing")
	check_lt(p.velocity.y, -500.0, "jump buffer: a press just before landing still jumps")


func test_flap_and_glide() -> void:
	var rows := [
		" @                  ",
		"####                ",
		"                    ",
		"                    ",
		"                    ",
		"                    ",
		"                    ",
		"                    ",
		"                    ",
		"                    ",
		"                    ",
		"                    ",
		"####################",
	]
	var level := await open_text_level(room(rows))
	var p := level.player
	await place(level, 6, 0)
	await frames(12)
	check_gt(p.velocity.y, 100.0, "falling")
	var before := p.velocity.y
	await tap("jump")
	check_lt(p.velocity.y, before - 200.0, "a flap pushes back up")
	check_eq(p.flaps_left, Tato.MAX_FLAPS - 1, "one flap used")
	await frames(6)
	await tap("jump")
	await frames(6)
	await tap("jump")
	check_eq(p.flaps_left, 0, "three flaps, then none")
	var v := p.velocity.y
	await frames(4)
	await tap("jump")
	check_gt(p.velocity.y, v - 50.0, "a fourth press does not flap")
	# glide: hold jump while falling
	Input.action_press("jump")
	await frames(40)
	check_lt(p.velocity.y, Tato.GLIDE_FALL + 5.0, "holding jump after flapping glides down slowly")
	Input.action_release("jump")
	await frames(120)
	check(p.is_on_floor(), "lands")
	check_eq(p.flaps_left, Tato.MAX_FLAPS, "flaps come back on landing")


func test_one_way_platform_and_drop_through() -> void:
	var rows := [
		"                    ",
		"                    ",
		"     ====           ",
		" @                  ",
		"####################",
	]
	var level := await open_text_level(room(rows))
	var p := level.player
	await place(level, 6.5, 3)
	Input.action_press("jump")
	await frames(30)
	Input.action_release("jump")
	await frames(50)
	check(p.is_on_floor(), "standing after the jump")
	check_near(p.global_position.y, floor_y(level, 2), 3.0, "jumped up through the thin platform (two tiles up) and landed on it")
	Input.action_press("move_down")
	await frames(3)
	await tap("jump")
	Input.action_release("move_down")
	await frames(45)
	check_near(p.global_position.y, floor_y(level, 4), 3.0, "down + jump drops through to the ground below")


func test_slopes_water_and_slide() -> void:
	var rows := [
		"                                ",
		"        /###\\                   ",
		" @     /#####\\                  ",
		"###################~~~~~~#######",
		"###################~~~~~~#######",
		"###################~~~~~~#######",
		"################################",
	]
	var level := await open_text_level(room(rows))
	var p := level.player
	await place(level, 3, 2)
	Input.action_press("move_right")
	await frames(90)
	check_near(p.global_position.y, floor_y(level, 1), 4.0, "walked up the two-tile ramp to the top (y=%.0f)" % p.global_position.y)
	check(p.is_on_floor(), "standing on the ramp top")
	# keep going down the other side; hold down to belly-slide
	await frames(25)
	Input.action_press("move_down")
	await frames(14)
	check(p.sliding or p.state == Tato.State.SLIDE or p.in_water, "belly slide starts going downhill at speed")
	Input.action_release("move_down")
	await frames(70)
	Input.action_release("move_right")
	await place(level, 21, 2)
	await frames(90)
	check(p.in_water, "floating in the pond")
	check_eq(p.state, Tato.State.SWIM, "state is SWIM")
	var surface := level.water_surface_at(p.global_position + Vector2(0, -22))
	check_near(p.global_position.y, surface + 20.0, 14.0, "bobs at the surface instead of sinking")
	await tap("jump")
	await frames(6)
	check_lt(p.velocity.y, -150.0, "hops out of the water")
