extends TestCase
## Plays every non-boss stage from start to goal with a simple robot player:
## hold right, jump at walls and gaps, flap across, attack on a rhythm.
## Cozy Mode is on, so falls and bumps only cost time. A stage "passes" when
## the robot reaches the goal flag inside the time allowed.

const FRAME_LIMIT := 60 * 150


func before_each() -> void:
	Settings.set_value("cozy_mode", true)


func after_each() -> void:
	Settings.set_value("cozy_mode", false)


func _ahead(p: Tato, dx: float, dy0: float, dy1: float, mask: int) -> bool:
	var space := p.get_world_2d().direct_space_state
	var from := p.global_position + Vector2(dx, dy0)
	var q := PhysicsRayQueryParameters2D.create(from, p.global_position + Vector2(dx, dy1), mask)
	q.exclude = [p.get_rid()]
	return not space.intersect_ray(q).is_empty()


func _wall(p: Tato, reach: float) -> bool:
	var space := p.get_world_2d().direct_space_state
	var from := p.global_position + Vector2(0, -24)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(reach, 0), Layers.WORLD)
	q.exclude = [p.get_rid()]
	return not space.intersect_ray(q).is_empty()


func _play(id: String) -> Dictionary:
	var level := await open_level(id)
	if level == null:
		return {"done": false, "x": 0.0, "frames": 0}
	var p := level.player
	Input.action_press("move_right")
	var jump_hold := 0
	var best_x := p.global_position.x
	var stuck := 0
	var frame := 0
	var back := 0
	while frame < FRAME_LIMIT and not level.finished:
		frame += 1
		await frames(1)
		if p.state == Tato.State.DISABLED:
			continue
		if frame % 22 == 0:
			Input.action_press("attack")
		elif frame % 22 == 2:
			Input.action_release("attack")
		if back > 0:
			back -= 1
			if back == 0:
				Input.action_release("move_left")
				Input.action_press("move_right")
		var floor_now := p.is_on_floor()
		var ground_ahead := _ahead(p, 56.0, -8.0, 150.0, Layers.WORLD | Layers.ONEWAY)
		var water := level.water_at(p.global_position + Vector2(40, 30))
		if jump_hold > 0:
			jump_hold -= 1
			if jump_hold == 0:
				Input.action_release("jump")
		elif floor_now or p.in_water:
			if _wall(p, 46.0) or (not ground_ahead and not water) or p.in_water:
				Input.action_press("jump")
				jump_hold = 26
		else:
			# in the air: flap when sinking with nothing underneath
			var below := _ahead(p, 24.0, 0.0, 130.0, Layers.WORLD | Layers.ONEWAY)
			if p.velocity.y > 120.0 and not below and (p.flaps_left > 0 or p.wings_time > 0.0):
				Input.action_press("jump")
				jump_hold = 14
			elif p.velocity.y > 60.0 and not below:
				Input.action_press("jump")     # glide
				jump_hold = 6
		if p.global_position.x > best_x + 24.0:
			best_x = p.global_position.x
			stuck = 0
		else:
			stuck += 1
			if stuck == 150 or stuck == 420:
				# wiggle: step back and take a run-up
				Input.action_release("move_right")
				Input.action_press("move_left")
				back = 40
			elif stuck > 150 and stuck % 60 == 0:
				Input.action_press("jump")
				jump_hold = 30
	release_all()
	return {"done": level.finished, "x": best_x, "width": level.data.pixel_size().x, "frames": frame, "notes": level.notes_found}


func test_robot_reaches_every_goal() -> void:
	var report: Array[String] = []
	var cleared := 0
	var total := 0
	var want := ""          # --stage=W3 plays only the stages whose id starts with W3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			want = arg.substr(8)
	for id in LevelDB.all_stage_ids():
		if LevelDB.stage_kind(id) == "boss" or (want != "" and not id.begins_with(want)):
			continue
		total += 1
		var r := await _play(id)
		if r["done"]:
			cleared += 1
		report.append("%s %s  %3d%%  %4.0fs" % [id, "GOAL " if r["done"] else "stuck", int(100.0 * float(r["x"]) / maxf(float(r.get("width", 1.0)), 1.0)), float(r["frames"]) / 60.0])
		print("  robot: " + report[-1] + "   (column %d)" % int(float(r["x"]) / 64.0))
		check(r["done"], "%s: robot reached the goal (got %d%% of the way in %.0fs)" % [id, int(100.0 * float(r["x"]) / maxf(float(r.get("width", 1.0)), 1.0)), float(r["frames"]) / 60.0])
	print("ROBOT PLAYTHROUGH")
	for line in report:
		print("  " + line)
	print("  cleared %d of %d" % [cleared, total])
