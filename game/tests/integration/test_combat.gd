extends TestCase
## Attacks, hearts, pickups and blocks, played for real in small rooms.

const ROOM := [
	"                              ",
	" @                            ",
	"##############################",
	"##############################",
]


func before_each() -> void:
	Settings.set_value("cozy_mode", false)
	Settings.set_value("infinite_feathers", false)
	Settings.set_value("challenge_mode", false)


func _spawn(level: Level, type: String, col: float, row: float, args: Array = [], params: Dictionary = {}) -> Node:
	var p := params.duplicate()
	for a: String in args:
		p[a] = true
	var node := EntityFactory.create(level, {"type": type, "cell": Vector2i(int(col), int(row) + ROOM_SKY), "args": args, "params": p})
	level.entities.add_child(node)
	await frames(3)
	return node


func test_honk_bops_a_creature_and_it_drops_a_coin() -> void:
	var level := await open_text_level(room(ROOM))
	var slime: Enemy = await _spawn(level, "slime_blob", 3, 1)
	slime.global_position.x = level.player.global_position.x + 70.0
	await frames(2)
	await tap("attack")
	await frames(10)
	check(slime.dead, "one honk defeats a Slime Blob")
	check_eq(level.defeated_count, 1, "the stage counts it")
	await frames(90)
	check(level.get_tree().get_nodes_in_group("grabbable").size() >= 1 or GameState.stage_coins >= 1, "a coin hopped out")


func test_stomp_bounces_and_spiky_things_cannot_be_stomped() -> void:
	var level := await open_text_level(room(ROOM))
	var p := level.player
	var slime: Enemy = await _spawn(level, "slime_blob", 6, 1)
	slime.set_physics_process(true)
	p.teleport_to(slime.global_position + Vector2(0, -150), false)
	p.invuln = 0.0
	await frames(40)
	check(slime.dead, "landing on a Slime Blob bops it")
	check_eq(GameState.hearts, 5, "and Tato is not hurt")
	var hog: Enemy = await _spawn(level, "hedgehog_roller", 14, 1)
	p.teleport_to(hog.global_position + Vector2(0, -150), false)
	p.invuln = 0.0
	await frames(40)
	check(not hog.dead, "a Hedgehog Roller is too prickly to stomp")
	check_eq(GameState.hearts, 4, "landing on it costs a heart")


func test_running_out_of_hearts_goes_back_to_the_checkpoint() -> void:
	var rows := [
		"                              ",
		" @     C                      ",
		"##############################",
		"##############################",
	]
	var level := await open_text_level(room(rows))
	var p := level.player
	await place(level, 7, 1)
	await frames(10)
	check(level.active_checkpoint != null, "touching the bell sets the checkpoint")
	GameState.add_coins(7)
	await place(level, 20, 1)
	for i in 5:
		p.invuln = 0.0
		p.hurt(p.global_position + Vector2(40, 0))
		await frames(4)
	await frames(30)
	check_eq(GameState.hearts, 5, "hearts are full again after the respawn")
	check_near(p.global_position.x, level.checkpoint_position.x, 40.0, "Tato is back at the checkpoint")
	check_eq(GameState.stage_coins, 7, "coins are kept")
	check(not p.state == Tato.State.DISABLED, "and he can move again")


func test_power_bowl_replaces_the_power_with_a_flavor_burst() -> void:
	var level := await open_text_level(room(ROOM))
	var p := level.player
	await _spawn(level, "power", 6, 1, ["FIRE_PEPPER"])
	await _spawn(level, "power", 12, 1, ["FROSTBERRY"])
	await place(level, 6, 1)
	await frames(6)
	check_eq(p.power.power, &"FIRE_PEPPER", "touching a bowl gives its power")
	check(GameState.knows_food(&"FIRE_PEPPER"), "the notebook learns the power")
	check_eq(GameState.bursts_found(), 0, "no burst for the first power")
	await place(level, 12, 1)
	await frames(6)
	check_eq(p.power.power, &"FROSTBERRY", "the newest bowl replaces the old power")
	check_eq(GameState.bursts_found(), 1, "swapping two different powers records a Flavor Burst")
	check(GameState.knows_recipe(FoodDB.resolve(&"FROSTBERRY", &"FIRE_PEPPER")), "it is the Pepper + Frostberry burst")


func test_every_power_attacks() -> void:
	var level := await open_text_level(room(ROOM))
	var p := level.player
	for id in FoodDB.FOOD_IDS:
		p.runner.cancel()
		p.runner.cooldowns.clear()
		p.power.pick_up(id)
		await place(level, 4, 1)
		p.facing = 1.0
		var target: Enemy = await _spawn(level, "apple_chomper", 6, 1)
		target.set_physics_process(true)
		target.global_position = p.global_position + Vector2(120.0, 0)
		target.stats = target.stats.duplicate()
		target.stats["speed"] = 0.0
		target.stats.erase("lunge")
		var hp0 := target.hp
		await tap("attack")
		var hit := false
		for i in 70:
			await frames(1)
			if target.dead or target.hp < hp0 or target.frozen_left > 0.0 or target.stuck_left > 0.0 or target.bubble_left > 0.0:
				hit = true
				break
		if id == &"COCOA_SHIELD":
			check(p.is_shielded() or hit, "Cocoa Shield guards Tato")
		else:
			check(hit, "%s (%s) hits a creature in front of Tato" % [FoodDB.food(id).display_name, FoodDB.food(id).ability_name])
		if not target.dead:
			target.defeat()
		await frames(20)
	check(true, "all twelve attacks ran")


func test_freeze_makes_a_step_and_shield_blocks_hurt() -> void:
	var level := await open_text_level(room(ROOM))
	var p := level.player
	var slime: Enemy = await _spawn(level, "apple_chomper", 8, 1)
	slime.take_hit(1, {"element": &"ice", "dir": Vector2.RIGHT})
	check_gt(slime.frozen_left, 0.0, "an ice hit freezes the creature")
	p.teleport_to(slime.global_position + Vector2(0, -150), false)
	await frames(50)
	check(p.is_on_floor() and p.global_position.y < slime.global_position.y - 30.0, "Tato can stand on the frozen creature")
	check_eq(GameState.hearts, 5, "a frozen creature does not hurt")
	slime.defeat()
	p.power.pick_up(&"COCOA_SHIELD")
	await place(level, 4, 1)
	await tap("attack")
	await frames(4)
	p.hurt(p.global_position + Vector2(30, 0))
	check_eq(GameState.hearts, 5, "nothing hurts Tato inside the Cocoa Shield")


func test_blocks_crates_keys_and_pickups() -> void:
	var level := await open_text_level(room(ROOM))
	var p := level.player
	var crate := await _spawn(level, "crate", 6, 1, [], {"holds": "coins:2"})
	crate.call("take_hit", 1, {"element": &"honk"})
	check(bool(crate.get("broken")), "a crate breaks when hit")
	var block := await _spawn(level, "qblock", 10, 1, [], {"holds": "heart"})
	block.call("take_hit", 1, {"element": &"honk"})
	check(bool(block.get("used")), "a Question Block opens when hit")
	await _spawn(level, "key", 14, 1)
	var lock := await _spawn(level, "lock", 16, 1)
	await place(level, 14, 1)
	await frames(6)
	check_eq(GameState.keys, 1, "the key is picked up")
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(bool(lock.get("open")), "walking into the lock with a key opens it")
	check_eq(GameState.keys, 0, "the key is used up")
	GameState.lose_heart()
	await _spawn(level, "pickup", 20, 1, ["cherry"])
	await _spawn(level, "pickup", 21, 1, ["wings"])
	await _spawn(level, "pickup", 22, 1, ["rainbow_star"])
	await place(level, 20, 1)
	await frames(6)
	check_eq(GameState.hearts, 5, "fruit heals a heart")
	await place(level, 21, 1)
	await frames(6)
	check_gt(p.wings_time, 0.0, "wings give endless flaps for a while")
	await place(level, 22, 1)
	await frames(6)
	check(p.is_shielded(), "a Rainbow Star makes Tato unhurtable")


func test_goal_finishes_the_stage_and_awards_stars() -> void:
	var rows := [
		"                              ",
		" @   n  n  n    E             ",
		"##############################",
		"##############################",
	]
	var level := await open_text_level(room(rows), "W1-L1")
	LevelDB._cache.erase("W1-L1")
	Input.action_press("move_right")
	for i in 400:
		await frames(1)
		if level.finished:
			break
	Input.action_release("move_right")
	check(level.finished, "reaching the flag finishes the stage")
	check_eq(level.notes_found, 3, "all three Treasure Notes were picked up on the way")
	check(GameState.is_cleared("W1-L1"), "the stage is marked cleared")
	check_eq(GameState.stars_in_level("W1-L1"), 2, "a star for finishing and a star for all the notes")
