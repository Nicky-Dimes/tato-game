class_name TestCase
extends Node
## Base for automated tests. Each method whose name starts with "test_" is
## one test; it may `await`. Use the check_* helpers; a failed check marks the
## test failed and the run carries on with the next one.

var failures: Array[String] = []
var checks := 0
var runner: Node


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
	return condition


func check_eq(actual: Variant, expected: Variant, message: String) -> bool:
	return check(actual == expected, "%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, tolerance: float, message: String) -> bool:
	return check(absf(actual - expected) <= tolerance, "%s (expected %.2f +/- %.2f, got %.2f)" % [message, expected, tolerance, actual])


func check_gt(actual: float, minimum: float, message: String) -> bool:
	return check(actual > minimum, "%s (expected > %.2f, got %.2f)" % [message, minimum, actual])


func check_lt(actual: float, maximum: float, message: String) -> bool:
	return check(actual < maximum, "%s (expected < %.2f, got %.2f)" % [message, maximum, actual])


# ---- helpers for tests that play a stage --------------------------------

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func release_all() -> void:
	for action in Controls.ACTIONS:
		Input.action_release(action)


func hold(action: String, frame_count: int) -> void:
	Input.action_press(action)
	await frames(frame_count)
	Input.action_release(action)


func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(1)


## Opens a stage and waits until it is ready. Returns the Level node.
func open_level(level_id: String) -> Level:
	Game.headless_test = true
	GameState.use_temp_profile()
	release_all()
	Game.level_id = level_id
	Game.start_checkpoint = ""
	var err := get_tree().change_scene_to_file(Game.LEVEL_SCENE)
	check(err == OK, "level scene opens")
	for i in 30:
		await get_tree().process_frame
		var scene := get_tree().current_scene
		if scene is Level and (scene as Level).player != null and (scene as Level).hud != null:
			await frames(20)
			return scene as Level
	check(false, "level %s became ready" % level_id)
	return null


## Builds a stage from text (not from data/levels) so a test can use a tiny
## purpose-made room.
func open_text_level(text: String, level_id: String = "UNIT") -> Level:
	LevelDB._cache[level_id] = LevelData.parse(text, level_id)
	return await open_level(level_id)


func place(level: Level, cell_x: float, cell_y: float) -> void:
	level.player.teleport_to(Vector2((cell_x + 0.5) * Layers.TILE, (cell_y + 1.0) * Layers.TILE), false)
	level.player.invuln = 0.0
	await frames(3)
