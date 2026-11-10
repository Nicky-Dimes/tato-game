class_name PauseMenu
extends CanvasLayer
## Pause: resume, recipe notebook, hints, settings (with the control list),
## restart, or leave the stage. Works with keyboard, pad, mouse and touch.

var level: Level
var _root: Control
var _main: PanelContainer
var _sub_holder: Control
var _first: Button
var _open := false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(lv: Level) -> void:
	level = lv
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.theme()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.19, 0.08, 0.27, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_main = UITheme.panel()
	_main.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_main.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_main.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(_main)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_main.add_child(box)
	box.add_child(UITheme.title_label("Paused", 44))
	var stage := UITheme.label(LevelDB.stage_name(level.level_id), 22, UITheme.PLUM_SOFT, true)
	stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stage)
	_first = _add(box, "Resume", close)
	_add(box, "Recipe Notebook", func() -> void: _show_sub("journal"))
	_add(box, "Hint Nest", func() -> void:
		close()
		level.show_hint_nest())
	_add(box, "Settings", func() -> void: _show_sub("settings"))
	if level.level_id != LevelDB.HUB_ID:
		_add(box, "Restart stage", func() -> void:
			close()
			Game.restart_level())
		_add(box, "Leave stage", func() -> void:
			close()
			GameState.save()
			Game.leave_level(false))
	else:
		_add(box, "Save and go to title", func() -> void:
			close()
			GameState.save()
			Game.goto_title())

	_sub_holder = Control.new()
	_sub_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub_holder.visible = false
	_root.add_child(_sub_holder)


func _add(box: VBoxContainer, text: String, action: Callable) -> Button:
	var b := UITheme.button(text, Vector2(360, 60))
	b.pressed.connect(action)
	box.add_child(b)
	return b


func open(sub: String = "") -> void:
	if _open:
		return
	_open = true
	get_tree().paused = true
	_root.visible = true
	_main.visible = true
	_sub_holder.visible = false
	AudioService.ui("ui_open")
	_first.grab_focus()
	if sub != "":
		_show_sub(sub)


func close() -> void:
	if not _open:
		return
	_open = false
	_clear_sub()
	_root.visible = false
	get_tree().paused = false
	Settings.save_settings()
	AudioService.ui("ui_back")


func _show_sub(which: String) -> void:
	_clear_sub()
	var panel: Control
	if which == "journal":
		var j := JournalPanel.new()
		j.closed.connect(_back_to_main)
		panel = j
	else:
		var s := SettingsPanel.new()
		s.closed.connect(_back_to_main)
		panel = s
	_sub_holder.add_child(panel)
	_sub_holder.visible = true
	_main.visible = false


func _back_to_main() -> void:
	_clear_sub()
	_main.visible = true
	_first.grab_focus()


func _clear_sub() -> void:
	for c in _sub_holder.get_children():
		c.queue_free()
	_sub_holder.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if _sub_holder.visible:
			_back_to_main()
		else:
			close()
		get_viewport().set_input_as_handled()
