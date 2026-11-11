extends TestCase
const ROOM := ["                                        ", " @                                      ", "########################################", "########################################"]

func test_bubbles_reach_ground_enemies_in_both_directions() -> void:
	for facing in [1.0, -1.0]:
		var level := await open_text_level(room(ROOM))
		var player := level.player
		var enemy := EntityFactory.create(level, {"type": "slime_blob", "cell": Vector2i(8, ROOM_SKY + 1), "args": [], "params": {}}) as Enemy
		level.entities.add_child(enemy)
		enemy.set_physics_process(false)
		player.teleport_to(enemy.global_position - Vector2(facing * 380, 0), false)
		player.facing = facing
		player.power.pick_up(&"BUBBLEBERRY")
		check(player.runner.try_activate(player.power.definition()), "Bubble Trap launches")
		await frames(65)
		check(enemy.bubble_left > 0 or enemy.dead or enemy.hp < 1, "forward bubbles reach an ordinary enemy 380px away, facing %s" % facing)

func test_run_and_damage_recovery_never_fade_the_character() -> void:
	var level := await open_text_level(room(ROOM))
	Input.action_press("move_right")
	await frames(55)
	level.player.visual.start_blink(1.0)
	for i in 18:
		await frames(1)
		check_near(level.player.visual.body.modulate.a, 1.0, 0.001, "Tato stays opaque throughout motion/recovery")
	Input.action_release("move_right")

func test_wide_bounce_pad_accepts_an_edge_landing() -> void:
	var level := await open_text_level(room(ROOM))
	var pad := EntityFactory.create(level, {"type": "spring", "cell": Vector2i(7, ROOM_SKY + 1), "args": [], "params": {}}) as Node2D
	level.entities.add_child(pad)
	var player := level.player
	player.teleport_to(pad.global_position + Vector2(65, -130), false)
	player.velocity.y = 300
	await frames(16)
	check_lt(player.velocity.y, -600, "landing near the broad pad edge still launches Tato")

func test_high_jumps_can_finish_a_stage() -> void:
	var level := await open_level("W1-L1")
	var goal_cell := Vector2i.ZERO
	for entity: Dictionary in level.data.entities:
		if entity["type"] == "goal":
			goal_cell = entity["cell"]
	level.player.teleport_to(LevelData.cell_floor(goal_cell) - Vector2(0, 400), false)
	await frames(5)
	check(level.finished, "crossing the goal above the flag finishes a high jump")
