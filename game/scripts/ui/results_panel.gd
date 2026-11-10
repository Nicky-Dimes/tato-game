class_name ResultsPanel
extends CanvasLayer
## The card at the end of a stage: stars earned, Treasure Notes, coins.
## No ranks to fail; everything found is kept.

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_results(level: Level, stats: Dictionary, result: Dictionary) -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.19, 0.08, 0.27, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(520, 0)
	panel.add_child(box)
	var boss := LevelDB.stage_kind(level.level_id) == "boss"
	box.add_child(UITheme.title_label("Flavor Page found!" if boss else "Stage clear!", 46))
	var name_label := UITheme.label(LevelDB.stage_name(level.level_id), 26, UITheme.PLUM_SOFT, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 6)
	box.add_child(stars)
	var have := GameState.stars_in_level(level.level_id)
	for i in 3:
		var tr := TextureRect.new()
		tr.texture = Art.tex("items/star")
		tr.custom_minimum_size = Vector2(64, 64)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if i >= have:
			tr.modulate = Color(0.2, 0.12, 0.3, 0.35)
		stars.add_child(tr)
	var how := UITheme.label("Stars: finish the stage, find all 3 Treasure Notes, find the hidden Star", 18, UITheme.PLUM_SOFT)
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(how)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	_row(grid, "Treasure Notes", "%d / %d" % [int(stats.get("notes_found", 0)), int(stats.get("notes_total", 0))])
	_row(grid, "Coins", "%d" % int(stats.get("coins", 0)))
	_row(grid, "Creatures bopped", "%d" % int(stats.get("defeated", 0)))
	_row(grid, "Time", HUD.format_time(float(stats.get("time", 0.0))) + ("  (best!)" if result.get("best_time", false) and not result.get("first_clear", false) else ""))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)
	var go := UITheme.button("Continue", Vector2(230, 64))
	go.pressed.connect(func() -> void: Game.leave_level(true))
	buttons.add_child(go)
	var again := UITheme.button("Play again", Vector2(210, 64))
	again.pressed.connect(func() -> void: Game.restart_level())
	buttons.add_child(again)
	go.grab_focus()
	panel.pivot_offset = Vector2(280, 160)
	panel.scale = Vector2(0.7, 0.7)
	var t := panel.create_tween()
	t.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _row(grid: GridContainer, left: String, right: String) -> void:
	grid.add_child(UITheme.label(left, 24))
	grid.add_child(UITheme.label(right, 24, UITheme.PLUM, true))
