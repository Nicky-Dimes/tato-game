extends TestCase
## Opens every screen in the game the way a player would reach it and pokes
## its buttons. The runner fails the test if the game logs any error, so this
## catches a screen that breaks only when it is actually shown.

const SLOT := 2
var _backup_main := ""
var _backup_bak := ""


func before_each() -> void:
	_backup_main = _read(SaveService.slot_path(SLOT))
	_backup_bak = _read(SaveService.backup_path(SLOT))
	SaveService.delete_slot(SLOT)


func after_each() -> void:
	SaveService.delete_slot(SLOT)
	_write(SaveService.slot_path(SLOT), _backup_main)
	_write(SaveService.backup_path(SLOT), _backup_bak)
	get_tree().paused = false
	GameState.use_temp_profile()


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _write(path: String, text: String) -> void:
	if text == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _open(path: String, args: Dictionary = {}) -> Node:
	Game.scene_args = args
	check_eq(get_tree().change_scene_to_file(path), OK, "%s opens" % path.get_file())
	for i in 12:
		await get_tree().process_frame
	return get_tree().current_scene


## Presses every enabled button under `root` whose text is not in `skip`.
func _buttons(root: Node, out: Array = []) -> Array:
	for c in root.get_children():
		if c is BaseButton and (c as BaseButton).is_visible_in_tree():
			out.append(c)
		_buttons(c, out)
	return out


## A save with a bit of everything in it, so screens have things to list.
func _rich_profile() -> void:
	GameState.start_new(SLOT)
	for id: String in ["W1-L1", "W1-L2", "W1-L3", "W1-X", "W1-B", "W2-L1"]:
		GameState.mark_cleared(id, {"time": 80.0, "hurt": 1, "notes_found": 3, "notes_total": 3, "coins": 40, "defeated": 6})
	GameState.collect("page", "W1")
	GameState.collect("note", "W1-L1-N01")
	GameState.collect("star", "W1-L1-star")
	GameState.add_coins(250)
	for food: String in ["FIRE_PEPPER", "BUBBLEBERRY", "WATERMELON"]:
		GameState.unlock_food(food)
	GameState.discover_recipe(FoodDB.resolve("FIRE_PEPPER", "BUBBLEBERRY"))
	for kind: String in ["slime_blob", "bee_buzzer", "mega_mushroot"]:
		GameState.meet_enemy(kind)
	GameState.save()


func test_title_screen_and_save_slots() -> void:
	_rich_profile()
	var menu := await _open(Game.TITLE_SCENE)
	check(menu != null and menu.has_method("_show_slots"), "title screen is showing")
	if menu == null:
		return
	check_gt(float(_buttons(menu).size()), 2.0, "title screen has its buttons")
	for mode: String in ["new", "load"]:
		menu.call("_show_slots", mode)
		await frames(3)
		var found := false
		for b: BaseButton in _buttons(menu):
			if b is Button and (b as Button).text.contains("pages"):
				found = true
		check(found, "the used nest is listed with its progress (%s)" % mode)
		menu.call("_clear_sub")
		await frames(2)
	menu.call("_show_settings")
	await frames(3)
	check_gt(float(_buttons(menu).size()), 4.0, "settings opened from the title screen")
	menu.call("_confirm_erase", SLOT)
	await frames(3)
	check_gt(float(_buttons(menu).size()), 1.0, "erase asks first")


func _ranges(root: Node, out: Array = []) -> Array:
	for c in root.get_children():
		if c is Range and not (c is ScrollBar):
			out.append(c)
		_ranges(c, out)
	return out


func test_settings_every_tab_and_control() -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	var before := Settings.data.duplicate(true)
	var bindings_before: Dictionary = Controls.bindings.duplicate(true)
	var panel := SettingsPanel.new()
	holder.add_child(panel)
	await frames(3)
	for tab: String in SettingsPanel.TABS:
		panel.call("_show_tab", tab)
		await frames(2)
		var body: Node = panel.get("_body")
		var used := 0
		for item: Variant in _ranges(body):
			if is_instance_valid(item):
				var r := item as Range
				r.value = r.min_value
				r.value = r.max_value
				used += 1
		if tab == "Controls":
			# the remap boxes are tried one at a time further down
			used = _buttons(body).size()
			check_gt(float(used), Controls.ACTIONS.size() * 3.0 - 1.0, "every action has two key boxes and a gamepad box")
			continue
		for item: Variant in _buttons(body):
			if not is_instance_valid(item):
				continue
			var b := item as BaseButton
			if b.disabled:
				continue
			if b.toggle_mode:
				b.button_pressed = not b.button_pressed
			b.pressed.emit()
			used += 1
			await frames(1)
		check_gt(float(used), 3.0, "settings tab %s has working controls" % tab)
	# remap: pick the first box on the Controls tab and press P
	panel.call("_show_tab", "Controls")
	await frames(2)
	var first_box: Button = null
	for item: Variant in _buttons(panel.get("_body")):
		if first_box == null and item is Button:
			first_box = item
	check(first_box != null, "controls tab has remap boxes")
	if first_box != null:
		first_box.pressed.emit()
		await frames(1)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_P
		key.keycode = KEY_P
		key.pressed = true
		Input.parse_input_event(key)
		await frames(3)
		var first_action: String = Controls.ACTIONS[0]
		check_eq(int((Controls.bindings[first_action]["keys"] as Array)[0]), int(KEY_P), "pressing P remaps the first action")
	Settings.data = before
	Settings.apply_all()
	Settings.save_settings()
	Controls.bindings = bindings_before
	Controls.apply_bindings()
	Controls.call("_store")
	holder.queue_free()
	await frames(2)


func test_storybook_every_story() -> void:
	for id: String in ["intro", "page_w1", "page_w2", "page_w3", "page_w4", "page_w5", "ending"]:
		var pages: Array = Story.story_pages(id)
		check_gt(float(pages.size()), 0.0, "story %s has pages" % id)
		for page: Dictionary in pages:
			check(Art.tex(str(page.get("art", ""))) != null, "story %s picture %s exists" % [id, str(page.get("art", ""))])
		var book := await _open(Game.STORY_SCENE, {"story": id, "then": {}})
		check(book != null and book.has_method("_next"), "storybook %s is showing" % id)
		if book == null:
			continue
		for i in maxi(pages.size() - 1, 0):
			book.call("_next")
			await frames(2)


func test_world_map_every_world() -> void:
	_rich_profile()
	for w: Dictionary in LevelDB.WORLDS:
		var map := await _open(Game.WORLD_MAP_SCENE, {"world": w["id"]})
		check(map != null, "map for %s is showing" % str(w["id"]))
		if map != null:
			check_gt(float(_buttons(map).size()), 4.0, "map for %s lists its stages" % str(w["id"]))


func test_credits() -> void:
	var c := await _open(Game.CREDITS_SCENE)
	check(c != null, "credits are showing")
	await frames(30)


func test_stage_screens_pause_notebook_wardrobe_results() -> void:
	_rich_profile()
	Game.headless_test = false       # show the real intro banner, results card and prompts
	var level := await open_level("W1-L1")
	Game.headless_test = false
	if level == null:
		return
	check(level.hud != null and level.touch != null, "stage has its HUD and touch controls")
	level.hud.show_banner("Honk Hill", "Grassland")
	level.hud.show_message("Checkpoint!")
	level.hud.show_toast("Treasure Note!")
	level.hud.show_hint(["One", "Two", "Three"])
	level.hud.show_recipe(FoodDB.resolve("FIRE_PEPPER", "BUBBLEBERRY"))
	level.hud.show_boss("Mega Mushroot")
	level.hud.show_defeat()
	level.show_hint_nest()
	await frames(20)
	var pause: PauseMenu = level._pause_menu
	check(pause != null, "stage has a pause menu")
	if pause != null:
		for sub: String in ["", "settings", "journal"]:
			pause.open(sub)
			await get_tree().process_frame
			await get_tree().process_frame
			check(get_tree().paused, "pause menu (%s) pauses the game" % sub)
			pause.close()
			await get_tree().process_frame
		check(not get_tree().paused, "closing the pause menu resumes")
	# Snack Notebook, every tab
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	var book := JournalPanel.new()
	holder.add_child(book)
	await frames(3)
	var tabs := 0
	for item: Variant in _buttons(book):
		if not is_instance_valid(item):
			continue
		var b := item as BaseButton
		if b is Button and not (b as Button).text in ["Back", "Close"]:
			b.pressed.emit()
			tabs += 1
			await frames(2)
	check_gt(float(tabs), 3.0, "notebook tabs open")
	holder.queue_free()
	# wardrobe: buy and wear something
	level.open_wardrobe()
	await frames(4)
	var wardrobes := level.find_children("*", "WardrobePanel", true, false)
	check_eq(wardrobes.size(), 1, "wardrobe opens")
	for panel in level.find_children("*", "WardrobePanel", true, false):
		for item: Variant in _buttons(panel):
			if not is_instance_valid(item):
				continue
			var b := item as BaseButton
			if not b.disabled and not (b is Button and (b as Button).text in ["Back", "Close", "Done"]):
				b.pressed.emit()
				await frames(1)
	await frames(3)
	# finish the stage: the results card appears
	level.player.set_disabled(false)
	level.complete_level()
	for i in 150:
		await get_tree().physics_frame
	var cards := level.find_children("*", "ResultsPanel", true, false)
	check_eq(cards.size(), 1, "results card appears after the goal")
	if cards.size() == 1:
		check_gt(float(_buttons(cards[0]).size()), 0.0, "results card has a button")
	Game.headless_test = true


func test_home_nest_and_trial_room() -> void:
	_rich_profile()
	for id: String in ["HUB", "TRIAL"]:
		var level := await open_level(id)
		check(level != null, "%s opens" % id)
		if level == null:
			continue
		await frames(40)
		check(level.player.is_on_floor(), "Tato stands on the ground in %s" % id)
