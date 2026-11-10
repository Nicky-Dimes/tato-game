class_name TouchControls
extends CanvasLayer
## On-screen controls for phones and tablets, using the buttons drawn on the
## Gameplay Redesign board: Move (left / right), Jump and Attack. That is all
## the game needs. Sliding the moving thumb down crouches / drops / slides;
## sliding it up looks up (and talks). Shown when a touch is seen (or always,
## via Settings).

const MOVE_SIZE := Vector2(250, 132)
const JUMP_R := 68.0
const ATTACK_R := 76.0

var level: Level
var _pad: Pad
var _move_touch := -1
var _held: Dictionary = {}       # touch index -> action
var _move_rect := Rect2()
var _jump_c := Vector2.ZERO
var _attack_c := Vector2.ZERO
var _pause_rect := Rect2()


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pad = Pad.new()
	_pad.owner_controls = self
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pad)
	Controls.device_changed.connect(func(_d: String) -> void: _refresh())
	Settings.changed.connect(func(_k: String) -> void: _refresh())
	_pad.resized.connect(_layout)
	_refresh()


func setup(lv: Level) -> void:
	level = lv
	if level != null and level.player != null:
		level.player.power_changed.connect(func(_p: StringName) -> void: _pad.queue_redraw())
		level.player.interact_target_changed.connect(func(_t: Node) -> void: _pad.queue_redraw())


func _refresh() -> void:
	_pad.visible = Controls.using_touch()
	_pad.modulate.a = clampf(Settings.num("touch_opacity"), 0.2, 1.0)
	if not _pad.visible:
		_release_all()
	_layout()


func size_factor() -> float:
	return clampf(Settings.num("touch_size"), 0.7, 1.5)


func _layout() -> void:
	var view := _pad.size
	var k := size_factor()
	_move_rect = Rect2(Vector2(34, view.y - 34 - MOVE_SIZE.y * k), MOVE_SIZE * k)
	_jump_c = Vector2(view.x - 110 * k, view.y - 104 * k)
	_attack_c = Vector2(view.x - 268 * k, view.y - 96 * k)
	_pause_rect = Rect2(view.x - 84, 12, 72, 72)
	_pad.queue_redraw()


func _input(event: InputEvent) -> void:
	if not _pad.visible:
		return
	if event is InputEventScreenTouch:
		var pos := _to_pad(event.position)
		if event.pressed:
			_press(event.index, pos)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag and event.index == _move_touch:
		_apply_move(_to_pad(event.position))


func _to_pad(screen_pos: Vector2) -> Vector2:
	return _pad.get_global_transform_with_canvas().affine_inverse() * screen_pos


func _press(index: int, pos: Vector2) -> void:
	if get_tree().paused:
		return
	if _pause_rect.has_point(pos):
		_tap_action("pause")
		return
	var k := size_factor()
	if pos.distance_to(_jump_c) <= JUMP_R * k * 1.2:
		_hold(index, "jump")
		return
	if pos.distance_to(_attack_c) <= ATTACK_R * k * 1.2:
		_hold(index, "attack")
		return
	# the whole left half is the move pad, so a thumb never misses it
	if pos.x < _pad.size.x * 0.5 and pos.y > _pad.size.y * 0.3 and _move_touch == -1:
		_move_touch = index
		_apply_move(pos)


func _hold(index: int, action: String) -> void:
	_held[index] = action
	Input.action_press(action)
	_pad.queue_redraw()


func _release(index: int) -> void:
	if index == _move_touch:
		_move_touch = -1
		_clear_move()
	if _held.has(index):
		Input.action_release(_held[index])
		_held.erase(index)
	_pad.queue_redraw()


func _release_all() -> void:
	for index: int in _held.keys():
		Input.action_release(_held[index])
	_held.clear()
	_move_touch = -1
	_clear_move()


func _tap_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _apply_move(pos: Vector2) -> void:
	var mid := _move_rect.get_center()
	var dx := pos.x - mid.x
	if dx < -8.0:
		Input.action_press("move_left")
		Input.action_release("move_right")
	elif dx > 8.0:
		Input.action_press("move_right")
		Input.action_release("move_left")
	# thumb slid below / above the pad
	if pos.y > _move_rect.end.y - 6.0:
		Input.action_press("move_down")
	else:
		Input.action_release("move_down")
	if pos.y < _move_rect.position.y - 34.0:
		Input.action_press("move_up")
	else:
		Input.action_release("move_up")
	_pad.queue_redraw()


func _clear_move() -> void:
	for a: String in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)


func _exit_tree() -> void:
	_release_all()


class Pad:
	extends Control

	var owner_controls: TouchControls

	func _draw() -> void:
		var tc := owner_controls
		if tc == null:
			return
		var k := tc.size_factor()
		var plum := Color("301444")
		# --- move pair
		var move := Art.tex("ui/btn_move")
		if move != null:
			draw_texture_rect(move, tc._move_rect, false)
		var left_down := Input.is_action_pressed("move_left") and tc._move_touch != -1
		var right_down := Input.is_action_pressed("move_right") and tc._move_touch != -1
		if left_down:
			draw_rect(Rect2(tc._move_rect.position, Vector2(tc._move_rect.size.x * 0.5, tc._move_rect.size.y)), Color(1, 1, 1, 0.3))
		if right_down:
			draw_rect(Rect2(tc._move_rect.position + Vector2(tc._move_rect.size.x * 0.5, 0), Vector2(tc._move_rect.size.x * 0.5, tc._move_rect.size.y)), Color(1, 1, 1, 0.3))
		# --- jump
		var jump := Art.tex("ui/btn_jump")
		var jr := TouchControls.JUMP_R * k * (0.92 if tc._held.values().has("jump") else 1.0)
		if jump != null:
			draw_texture_rect(jump, Rect2(tc._jump_c - Vector2(jr, jr), Vector2(jr, jr) * 2.0), false)
		# --- attack: the red button, with the active power on it
		var ar := TouchControls.ATTACK_R * k * (0.92 if tc._held.values().has("attack") else 1.0)
		draw_circle(tc._attack_c, ar, Color("7a1830"))
		draw_circle(tc._attack_c, ar - 6.0, Color("f0506a"))
		draw_arc(tc._attack_c, ar - 12.0, -2.5, -1.2, 12, Color(1, 1, 1, 0.6), 6.0, true)
		var icon: Texture2D = null
		var label := ""
		if tc.level != null and tc.level.player != null:
			var p := tc.level.player
			if p.interact_target != null and is_instance_valid(p.interact_target) and p.interact_target.has_method("uses_attack_button"):
				label = "GO"
			elif p.power.has_power():
				icon = FoodDB.food_icon(p.power.power)
			else:
				label = "HONK"
		if icon != null:
			var s := ar * 1.25
			var kk := s / float(maxi(icon.get_width(), icon.get_height()))
			var sz := Vector2(icon.get_width(), icon.get_height()) * kk
			draw_texture_rect(icon, Rect2(tc._attack_c - sz * 0.5, sz), false)
		elif label != "":
			var font := UITheme.font_title()
			if font:
				var fs := int(ar * 0.42)
				var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string_outline(font, tc._attack_c + Vector2(-w * 0.5, fs * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, plum)
				draw_string(font, tc._attack_c + Vector2(-w * 0.5, fs * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		# --- pause
		var pr := tc._pause_rect
		draw_circle(pr.get_center(), 34.0, Color(plum.r, plum.g, plum.b, 0.55))
		draw_circle(pr.get_center(), 28.0, Color(1, 0.98, 0.94, 0.9))
		draw_rect(Rect2(pr.get_center() + Vector2(-11, -12), Vector2(8, 24)), plum)
		draw_rect(Rect2(pr.get_center() + Vector2(3, -12), Vector2(8, 24)), plum)
