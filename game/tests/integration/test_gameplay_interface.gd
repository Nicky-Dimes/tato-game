extends TestCase
## Exercise player-facing controls and real power signals, not just scene loading.

func after_each() -> void:
	get_tree().paused = false
	Controls.reset_bindings()


func test_hud_navigation_pauses_and_returns_to_play() -> void:
	var level := await open_level("W1-L1")
	if level == null:
		return
	for pair: Array in [["PauseButton", ""], ["NotebookButton", "journal"], ["MapButton", "map"]]:
		var button := level.hud.root.find_child(pair[0], true, false) as Button
		check(button != null, "%s can be reached from gameplay" % pair[0])
		if button == null:
			continue
		button.pressed.emit()
		await get_tree().process_frame
		check(get_tree().paused, "%s pauses the world" % pair[0])
		check(level._pause_menu._root.visible, "pause overlay is visible")
		if pair[1] == "map":
			check(level._pause_menu._sub_holder.visible, "map asks before leaving an unfinished stage")
		level._pause_menu.close()
		await get_tree().process_frame
		check(not get_tree().paused, "closing overlay restores gameplay")
	var header := level.hud.root.find_child("GameplayHeader", true, false) as HBoxContainer
	check(header.get_combined_minimum_size().x < 1248, "HUD fits the 1280-pixel logical viewport")
	check_eq(level.hud._hearts.size(), 5, "all five hearts are represented")


func test_single_power_labels_and_real_attack_readiness() -> void:
	var level := await open_level("W1-L1")
	if level == null:
		return
	var player := level.player
	for food: FoodDefinition in FoodDB.all_foods():
		player.power.pick_up(food.id)
		check_eq(level.hud._power_name.text, food.ability_name, "new food updates attack label")
		check_eq(player.power.power, food.id, "new food replaces the active slot")
	player.runner.cancel()
	player.power.pick_up(&"FIRE_PEPPER")
	var definition := player.power.definition()
	check(player.runner.try_activate(definition), "a real attack starts")
	level.hud._process(0)
	check_lt(level.hud._readiness.value, 1.0, "HUD shows actual attack cooldown")
	await frames(90)
	level.hud._process(0)
	check_near(level.hud._readiness.value, 1.0, 0.01, "HUD becomes ready when the attack recovers")
	check(level.hud._power_hint.text.contains(Controls.prompt("attack")), "attack prompt matches current binding")
