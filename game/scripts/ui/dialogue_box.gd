class_name DialogueBox
extends CanvasLayer
## Short conversations. Tato only ever honks (with a face that says the
## rest); friends speak a line or two at a time. Any action button or a tap
## moves on, and holding nothing is ever required.

var _root: Control
var _panel: PanelContainer
var _name: Label
var _text: Label
var _portrait: TextureRect
var _hint: Label
var _lines: Array = []
var _index := 0
var _open := false
var _player: Tato
var _on_done := Callable()
var _typing: Tween
var _full := false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.theme()
	_root.visible = false
	_root.gui_input.connect(_on_gui_input)
	add_child(_root)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.box(UITheme.CREAM, UITheme.PLUM, 28, 6))
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 150.0
	_panel.offset_right = -150.0
	_panel.offset_top = -214.0
	_panel.offset_bottom = -34.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_panel.add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(132, 132)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_name = UITheme.label("", 26, UITheme.ORANGE_DARK, true)
	col.add_child(_name)
	_text = UITheme.label("", 26)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_text)
	_hint = UITheme.label("", 18, UITheme.PLUM_SOFT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)


func is_open() -> bool:
	return _open


func play(dialogue_id: String, player: Tato, on_done: Callable = Callable()) -> void:
	play_lines(Story.dialogue(dialogue_id), player, on_done)


func play_lines(lines: Array, player: Tato, on_done: Callable = Callable()) -> void:
	if lines.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	_lines = lines
	_index = 0
	_player = player
	_on_done = on_done
	_open = true
	_root.visible = true
	if _player != null and is_instance_valid(_player):
		_player.set_disabled(true)
	_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var who := str(line.get("who", "tato"))
	var text := Controls.fill(str(line.get("text", "")))
	_name.text = Story.speaker_name(who)
	_text.text = text
	_portrait.texture = Story.portrait(who, str(line.get("face", "happy")))
	_hint.text = "%s  next" % Controls.prompt("jump") if Controls.device != Controls.DEVICE_TOUCH else "tap to continue"
	_full = false
	_text.visible_ratio = 0.0
	if _typing and _typing.is_valid():
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, maxf(0.15, text.length() / 55.0))
	_typing.tween_callback(func() -> void: _full = true)
	if who == "tato":
		AudioService.voice(str(line.get("honk", "honk_happy")), -3.0)
	else:
		AudioService.play("talk_" + who, -6.0)
		if not AudioService.has_sound("talk_" + who):
			AudioService.play("talk", -6.0)
	Captions.caption("")


func _advance() -> void:
	if not _full:
		if _typing and _typing.is_valid():
			_typing.kill()
		_text.visible_ratio = 1.0
		_full = true
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		AudioService.ui("ui_move", -8.0)
		_show_line()


func _close() -> void:
	_open = false
	_root.visible = false
	if _player != null and is_instance_valid(_player):
		_player.set_disabled(false)
		_player.control_lock = 0.15
	var cb := _on_done
	_on_done = Callable()
	if cb.is_valid():
		cb.call()


func _on_gui_input(event: InputEvent) -> void:
	if _open and event is InputEventMouseButton and event.pressed:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	for action: String in ["jump", "attack", "ui_accept"]:
		if event.is_action_pressed(action):
			_advance()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		# skip the rest of the conversation
		_close()
		get_viewport().set_input_as_handled()
