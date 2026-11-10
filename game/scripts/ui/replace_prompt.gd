class_name ReplacePrompt
extends CanvasLayer
## Both pockets are full and Tato found a third snack: which pocket gets
## swapped? Time slows right down while choosing; not choosing keeps both.
## (In Cozy Mode the timer never runs out.)

const WINDOW := 4.0

var _root: Control
var _open := false
var _player: Tato
var _food: StringName
var _left := 0.0
var _bar: ProgressBar
var _buttons: Array[Button] = []
var _title: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.theme()
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	_title = UITheme.label("Pockets full! Swap which snack?", 26, UITheme.PLUM, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	for i in 2:
		var b := UITheme.button("", Vector2(210, 96))
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_choose.bind(i))
		row.add_child(b)
		_buttons.append(b)
	var keep := UITheme.small_button("Keep both")
	keep.pressed.connect(_choose.bind(-1))
	keep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(keep)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 16)
	_bar.max_value = 1.0
	box.add_child(_bar)


func is_open() -> bool:
	return _open


func ask(player: Tato, food: StringName) -> void:
	_player = player
	_food = food
	_open = true
	_left = WINDOW
	var def := FoodDB.food(food)
	_title.text = "Pockets full! Put %s where?" % (def.display_name if def else "it")
	for i in 2:
		var cur := FoodDB.food(player.inventory.food_in(i))
		_buttons[i].text = "%s: swap %s" % ["A" if i == 0 else "B", cur.display_name if cur else "?"]
		_buttons[i].icon = FoodDB.icon(cur.icon_path) if cur else null
	_bar.visible = not Settings.flag("cozy_mode")
	_root.visible = true
	Engine.time_scale = 0.12
	_buttons[0].grab_focus()
	AudioService.ui("ui_open")


func _process(delta: float) -> void:
	if not _open:
		return
	if not Settings.flag("cozy_mode"):
		# real seconds, not slowed game time
		_left -= delta / maxf(Engine.time_scale, 0.01)
		_bar.value = clampf(_left / WINDOW, 0.0, 1.0)
		if _left <= 0.0:
			_choose(-1)


func _choose(slot: int) -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	Engine.time_scale = 1.0
	if _player != null and is_instance_valid(_player):
		_player.resolve_replace(slot)
		_player.control_lock = 0.15
