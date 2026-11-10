extends Control
## Title screen: Play / Continue / Chapters / Settings / Credits / Quit, plus
## the three save slots.

var _menu: VBoxContainer
var _slots: Control
var _sub: Control
var _first: Button
var _hero: TextureRect
var _clock := 0.0
var _slot_mode := "new"


func _ready() -> void:
	theme = UITheme.theme()
	AudioService.music("title")
	_build_backdrop()
	_build_menu()
	_sub = Control.new()
	_sub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub.visible = false
	add_child(_sub)
	if _first:
		_first.grab_focus()


func _build_backdrop() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color("7cc7f5"))
	grad.set_color(1, Color("fff0d9"))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2(0, 0)
	gtex.fill_to = Vector2(0, 1)
	gtex.width = 4
	gtex.height = 128
	var sky := TextureRect.new()
	sky.texture = gtex
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	for short: String in ["bg/picnic_far", "bg/picnic_mid"]:
		var tex := Art.tex(short)
		if tex == null:
			continue
		var hills := TextureRect.new()
		hills.texture = tex
		hills.stretch_mode = TextureRect.STRETCH_TILE
		hills.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		hills.offset_top = -tex.get_height()
		hills.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hills)
	_hero = TextureRect.new()
	_hero.texture = load("res://assets/ui/hero.png") if ResourceLoader.exists("res://assets/ui/hero.png") else null
	_hero.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_hero.offset_left = 110.0
	_hero.offset_top = -160.0
	_hero.offset_right = 520.0
	_hero.offset_bottom = 320.0
	_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hero)
	var logo_tex: Texture2D = load("res://assets/ui/logo.png") if ResourceLoader.exists("res://assets/ui/logo.png") else null
	if logo_tex != null:
		var logo := TextureRect.new()
		logo.texture = logo_tex
		logo.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		logo.offset_left = 60.0
		logo.offset_top = 24.0
		logo.offset_right = 560.0
		logo.offset_bottom = 330.0
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(logo)
	else:
		var title := UITheme.title_label("TATO!", 120)
		title.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		title.position = Vector2(90, 40)
		add_child(title)
		var sub := UITheme.outlined_label("A Little Goose With a Big Appetite", 30)
		sub.position = Vector2(96, 190)
		add_child(sub)


func _build_menu() -> void:
	_menu = VBoxContainer.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_menu.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu.offset_right = -110.0
	_menu.add_theme_constant_override("separation", 12)
	add_child(_menu)
	var any_save := false
	for i in SaveService.SLOT_COUNT:
		if SaveService.slot_exists(i):
			any_save = true
	if any_save:
		_first = _add("Continue", func() -> void: _show_slots("load"))
		_add("New Game", func() -> void: _show_slots("new"))
	else:
		_first = _add("Play", func() -> void: _show_slots("new"))
	_add("Settings", _show_settings)
	_add("Credits", func() -> void: Game.goto(Game.CREDITS_SCENE))
	if not OS.has_feature("web"):
		_add("Quit", func() -> void: Game.quit_game())
	var ver := UITheme.outlined_label("v%s" % str(ProjectSettings.get_setting("application/config/version", "")), 16)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -120.0
	ver.offset_top = -34.0
	add_child(ver)


func _add(text: String, action: Callable) -> Button:
	var b := UITheme.button(text, Vector2(340, 70))
	b.pressed.connect(action)
	_menu.add_child(b)
	return b


func _process(delta: float) -> void:
	_clock += delta
	if _hero != null and not Settings.flag("reduced_motion"):
		_hero.position.y += sin(_clock * 2.2) * 0.25


func _clear_sub() -> void:
	for c in _sub.get_children():
		c.queue_free()
	_sub.visible = false
	_menu.visible = true
	if _first:
		_first.grab_focus()


func _show_settings() -> void:
	_menu.visible = false
	var s := SettingsPanel.new()
	s.closed.connect(_clear_sub)
	_sub.add_child(s)
	_sub.visible = true


func _show_slots(mode: String) -> void:
	_slot_mode = mode
	_menu.visible = false
	_sub.visible = true
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_sub.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UITheme.title_label("Pick a nest" if mode == "new" else "Continue", 40))
	var first: Button = null
	for i in SaveService.SLOT_COUNT:
		var info := SaveService.slot_summary(i)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var text := "Nest %d   -   empty" % (i + 1)
		if not info["empty"]:
			text = "Nest %d   -   %d pages, %d scraps, %s" % [i + 1, int(info["pages"]), int(info["scraps"]), _play_time(float(info["played_seconds"]))]
			if info["complete"]:
				text += "  ★"
		var b := UITheme.button(text, Vector2(620, 70))
		b.add_theme_font_size_override("font_size", 24)
		b.disabled = mode == "load" and bool(info["empty"])
		b.pressed.connect(_pick_slot.bind(i, bool(info["empty"])))
		row.add_child(b)
		if not info["empty"]:
			var del := UITheme.small_button("Erase")
			del.pressed.connect(_confirm_erase.bind(i))
			row.add_child(del)
		box.add_child(row)
		if first == null and not b.disabled:
			first = b
	var back := UITheme.small_button("Back")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_clear_sub)
	box.add_child(back)
	if first:
		first.grab_focus()
	else:
		back.grab_focus()


func _play_time(seconds: float) -> String:
	var m := int(seconds / 60.0)
	return "%dh %02dm" % [m / 60, m % 60]


func _pick_slot(slot: int, empty: bool) -> void:
	if _slot_mode == "new":
		if not empty:
			_confirm("Start over in Nest %d? The old save will be replaced." % (slot + 1), func() -> void: _start_new(slot))
			return
		_start_new(slot)
	else:
		if GameState.load_profile(slot):
			_continue_game()


func _start_new(slot: int) -> void:
	GameState.start_new(slot)
	Game.goto_story("intro", {"level": "W1-L1"})


func _continue_game() -> void:
	if not GameState.is_cleared("W1-L1"):
		Game.start_level("W1-L1")
	else:
		Game.goto_hub()


func _confirm_erase(slot: int) -> void:
	_confirm("Erase Nest %d forever?" % (slot + 1), func() -> void:
		SaveService.delete_slot(slot)
		_clear_sub()
		get_tree().reload_current_scene())


func _confirm(question: String, yes: Callable) -> void:
	for c in _sub.get_children():
		c.queue_free()
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_sub.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var q := UITheme.label(question, 26, UITheme.PLUM, true)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.custom_minimum_size = Vector2(480, 0)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(q)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var no := UITheme.button("No", Vector2(180, 60))
	no.pressed.connect(_clear_sub)
	row.add_child(no)
	var ok := UITheme.button("Yes", Vector2(180, 60))
	ok.pressed.connect(yes)
	row.add_child(ok)
	no.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _sub.visible:
		_clear_sub()
		get_viewport().set_input_as_handled()
