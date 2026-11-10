class_name SettingsPanel
extends Control
## Settings used by both the title screen and the pause menu: sound, play
## and comfort options, display, and button remapping. Every change applies
## at once and is saved on its own file, apart from game progress.

signal closed

const TABS := ["Sound", "Play", "Comfort", "Controls"]

## key, label, kind, extra
const ROWS := {
	"Sound": [
		["master_volume", "Everything", "slider", null],
		["music_volume", "Music", "slider", null],
		["sfx_volume", "Sound effects", "slider", null],
		["voice_volume", "Tato's honks", "slider", null],
		["captions", "Captions for sounds", "toggle", null],
	],
	"Play": [
		["cozy_mode", "Cozy Mode (no feather loss, longer timers, bigger honk)", "toggle", null],
		["challenge_mode", "Challenge Mode (shorter timers)", "toggle", null],
		["infinite_feathers", "Endless Comfort Feathers", "toggle", null],
		["timer_scale", "Puzzle timer length", "range", [1.0, 2.0, 0.25]],
		["auto_run", "Run automatically after a moment", "toggle", null],
		["auto_eat", "Eat snacks just by touching the bowl", "toggle", null],
		["show_timer", "Show stage timer", "toggle", null],
	],
	"Comfort": [
		["reduced_motion", "Reduced motion", "toggle", null],
		["screen_shake", "Screen shake", "slider", null],
		["reduce_flashes", "Reduce flashes", "toggle", null],
		["high_contrast", "High-contrast prompts", "toggle", null],
		["ui_scale", "Text and menu size", "range", [0.75, 1.5, 0.05]],
		["fullscreen", "Full screen", "toggle", null],
		["touch_controls", "Touch buttons", "option", ["auto", "on", "off"]],
		["touch_size", "Touch button size", "range", [0.7, 1.5, 0.1]],
		["touch_opacity", "Touch button visibility", "range", [0.3, 1.0, 0.1]],
		["quality", "Graphics detail", "option", ["auto", "low", "high"]],
	],
}

var _body: VBoxContainer
var _tab_buttons: Array[Button] = []
var _tab := "Sound"
var _capture_action := ""
var _capture_kind := ""
var _capture_slot := 0
var _capture_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 90.0
	panel.offset_right = -90.0
	panel.offset_top = 40.0
	panel.offset_bottom = -40.0
	add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	outer.add_child(UITheme.title_label("Settings", 40))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	outer.add_child(tabs)
	for t: String in TABS:
		var b := UITheme.small_button(t)
		b.custom_minimum_size = Vector2(170, 52)
		b.pressed.connect(_show_tab.bind(t))
		tabs.add_child(b)
		_tab_buttons.append(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)
	var back := UITheme.button("Done", Vector2(220, 58))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void:
		Settings.save_settings()
		closed.emit())
	outer.add_child(back)
	_show_tab("Sound")
	_tab_buttons[0].grab_focus()


func _show_tab(tab: String) -> void:
	_tab = tab
	_capture_action = ""
	for c in _body.get_children():
		c.queue_free()
	for i in TABS.size():
		_tab_buttons[i].modulate = Color.WHITE if TABS[i] == tab else Color(1, 1, 1, 0.7)
	if tab == "Controls":
		_build_controls()
		return
	for row: Array in ROWS[tab]:
		var key: String = row[0]
		if key == "fullscreen" and OS.has_feature("web"):
			continue
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 16)
		var label := UITheme.label(row[1], 22)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_child(label)
		match row[2]:
			"toggle":
				var cb := CheckButton.new()
				cb.button_pressed = Settings.flag(key)
				cb.toggled.connect(func(v: bool) -> void:
					Settings.set_value(key, v)
					AudioService.ui("ui_select"))
				line.add_child(cb)
			"slider":
				line.add_child(_slider(key, 0.0, 1.0, 0.05))
			"range":
				var r: Array = row[3]
				line.add_child(_slider(key, r[0], r[1], r[2]))
			"option":
				var ob := OptionButton.new()
				var opts: Array = row[3]
				for o: String in opts:
					ob.add_item(o.capitalize())
				ob.selected = maxi(opts.find(str(Settings.get_value(key))), 0)
				ob.custom_minimum_size = Vector2(160, 46)
				ob.item_selected.connect(func(i: int) -> void: Settings.set_value(key, opts[i]))
				line.add_child(ob)
		_body.add_child(line)
	if tab == "Play":
		var note := UITheme.label("Cozy Mode and assists never lock story rewards.", 18, UITheme.PLUM_SOFT)
		_body.add_child(note)


func _slider(key: String, lo: float, hi: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = Settings.num(key)
	s.custom_minimum_size = Vector2(300, 36)
	s.value_changed.connect(func(v: float) -> void:
		Settings.set_value(key, v)
		if key.ends_with("_volume"):
			AudioService.ui("ui_move"))
	return s


func _build_controls() -> void:
	var head := HBoxContainer.new()
	var h0 := UITheme.label("Action", 20, UITheme.PLUM_SOFT, true)
	h0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(h0)
	for t: String in ["Key", "Other key", "Gamepad"]:
		var h := UITheme.label(t, 20, UITheme.PLUM_SOFT, true)
		h.custom_minimum_size = Vector2(170, 0)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_child(h)
	_body.add_child(head)
	for action in Controls.ACTIONS:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var label := UITheme.label(str(Controls.ACTION_LABELS.get(action, action)), 22)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
		var keys: Array = Controls.bindings[action]["keys"]
		var pad: Array = Controls.bindings[action]["pad"]
		line.add_child(_bind_button(action, "keys", 0, Controls.key_name(keys[0]) if keys.size() > 0 else "-"))
		line.add_child(_bind_button(action, "keys", 1, Controls.key_name(keys[1]) if keys.size() > 1 else "-"))
		line.add_child(_bind_button(action, "pad", 0, Controls.pad_name(pad[0]) if pad.size() > 0 else "-"))
		_body.add_child(line)
	var reset := UITheme.small_button("Reset controls")
	reset.custom_minimum_size = Vector2(240, 52)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset.pressed.connect(func() -> void:
		Controls.reset_bindings()
		_show_tab("Controls"))
	_body.add_child(reset)
	var note := UITheme.label("Pick a box, then press the new key or button. Esc cancels. Left stick always moves.", 18, UITheme.PLUM_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(note)


func _bind_button(action: String, kind: String, slot: int, text: String) -> Button:
	var b := UITheme.small_button(text)
	b.custom_minimum_size = Vector2(170, 46)
	b.pressed.connect(func() -> void:
		_capture_action = action
		_capture_kind = kind
		_capture_slot = slot
		_capture_button = b
		b.text = "press...")
	return b


func _input(event: InputEvent) -> void:
	if _capture_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			_capture_action = ""
			_show_tab("Controls")
			return
		if _capture_kind == "keys":
			Controls.rebind(_capture_action, "keys", _capture_slot, int(event.physical_keycode))
			_capture_action = ""
			_show_tab("Controls")
	elif event is InputEventJoypadButton and event.pressed and _capture_kind == "pad":
		get_viewport().set_input_as_handled()
		Controls.rebind(_capture_action, "pad", _capture_slot, int(event.button_index))
		_capture_action = ""
		_show_tab("Controls")
