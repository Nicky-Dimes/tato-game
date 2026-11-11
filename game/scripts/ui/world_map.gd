extends Control
## Stage select for one world: its painting from the world board, the five
## stages (three stages, a bonus stage, the boss) with the stars and
## Treasure Notes found, and arrows to the other worlds already opened.

var _world_index := 0
var _holder: Control


func _ready() -> void:
	theme = UITheme.theme()
	AudioService.music("map")
	var want := str(Game.scene_args.get("world", "W1"))
	for i in LevelDB.WORLDS.size():
		if LevelDB.WORLDS[i]["id"] == want:
			_world_index = i
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_holder)
	_build()


func _build() -> void:
	for c in _holder.get_children():
		c.queue_free()
	var w: Dictionary = LevelDB.WORLDS[_world_index]
	var wid: String = w["id"]
	var bg := TextureRect.new()
	bg.texture = ProductionArt.landscape(str(w["theme"]), "far")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(1, 1, 1, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(1.0, 0.97, 0.9, 0.35)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(veil)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 60.0
	box.offset_right = -60.0
	box.offset_top = 20.0
	box.offset_bottom = -20.0
	box.add_theme_constant_override("separation", 10)
	_holder.add_child(box)
	box.add_child(UITheme.title_label("World %d: %s" % [int(w["index"]), str(w["name"])], 48))
	var tag := UITheme.outlined_label(str(w["tagline"]), 22)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var first: Button = null
	for stage_id: String in w["stages"]:
		var open := GameState.is_unlocked(stage_id) and LevelDB.has_level(stage_id)
		var kind := LevelDB.stage_kind(stage_id)
		var card := UITheme.panel(UITheme.CREAM if open else Color("d9cfe0"))
		card.custom_minimum_size = Vector2(204, 300)
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 6)
		card.add_child(col)
		var head := "Boss" if kind == "boss" else ("Bonus" if kind == "optional" else "Stage %s" % stage_id.substr(4))
		var hl := UITheme.label(head, 20, UITheme.ORANGE_DARK, true)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(hl)
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(150, 96)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture = Art.tex("bosses/%s" % str(w["boss_art"])) if kind == "boss" else Art.tex("cards/world_%s" % str(w["theme"]))
		if not open:
			pic.modulate = Color(0.19, 0.08, 0.27, 0.5)
		col.add_child(pic)
		var nl := UITheme.label(LevelDB.stage_name(stage_id) if open else "? ? ?", 22, UITheme.PLUM, true)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size = Vector2(170, 0)
		col.add_child(nl)
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(stars)
		var have := GameState.stars_in_level(stage_id)
		for i in 3:
			var st := TextureRect.new()
			st.texture = Art.tex("items/star")
			st.custom_minimum_size = Vector2(30, 30)
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if i >= have:
				st.modulate = Color(0.2, 0.12, 0.3, 0.3)
			stars.add_child(st)
		var notes := UITheme.label("Notes %d/3" % GameState.count_in_level("note", stage_id), 18, UITheme.PLUM_SOFT)
		notes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(notes)
		var play := UITheme.button("Play" if open else "Locked", Vector2(170, 54))
		play.disabled = not open
		play.pressed.connect(func() -> void: Game.start_level(stage_id))
		col.add_child(play)
		if open and (first == null or not GameState.is_cleared(stage_id)):
			if first == null or GameState.is_cleared(str(first.get_meta("stage", ""))):
				first = play
				play.set_meta("stage", stage_id)
		row.add_child(card)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 14)
	box.add_child(nav)
	var prev := UITheme.small_button("< World")
	prev.custom_minimum_size = Vector2(150, 54)
	prev.disabled = _world_index <= 0
	prev.pressed.connect(func() -> void:
		_world_index -= 1
		_build())
	nav.add_child(prev)
	var home := UITheme.button("Home Nest", Vector2(230, 58))
	home.pressed.connect(func() -> void: Game.goto_hub())
	nav.add_child(home)
	var nxt := UITheme.small_button("World >")
	nxt.custom_minimum_size = Vector2(150, 54)
	var next_open := _world_index + 1 < LevelDB.WORLDS.size() and GameState.world_unlocked(str(LevelDB.WORLDS[_world_index + 1]["id"]))
	nxt.disabled = not next_open
	nxt.pressed.connect(func() -> void:
		_world_index += 1
		_build())
	nav.add_child(nxt)
	if first != null:
		first.grab_focus()
	else:
		home.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Game.goto_hub()
		get_viewport().set_input_as_handled()
