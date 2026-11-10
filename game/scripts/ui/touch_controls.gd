class_name TouchControls
extends CanvasLayer
## On-screen controls for phones and tablets. Left side: a floating stick
## (put a thumb down anywhere and drag). Right side: Jump, Honk, Eat and
## Fuse buttons. Tapping a Flavor Pocket in the HUD swaps pockets.
## Shows itself when a touch is seen (or always, via Settings).

const BUTTONS := [
	# action, label, radius, offset from the bottom-right corner
	["jump", "JUMP", 66.0, Vector2(-112, -112)],
	["honk_primary", "HONK", 56.0, Vector2(-262, -92)],
	["eat_interact", "EAT", 48.0, Vector2(-232, -232)],
	["fusion", "FUSE", 48.0, Vector2(-96, -262)],
]
const STICK_RADIUS := 78.0
const DEAD := 0.28

var _pad: Control
var _stick_touch := -1
var _stick_origin := Vector2.ZERO
var _stick_now := Vector2.ZERO
var _held: Dictionary = {}       # touch index -> action
var _pause_rect := Rect2()
var _hint_rect := Rect2()


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pad = Pad.new()
	(_pad as Pad).owner_controls = self
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pad)
	Controls.device_changed.connect(func(_d: String) -> void: _refresh())
	Settings.changed.connect(func(_k: String) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	_pad.visible = Controls.using_touch()
	_pad.modulate.a = clampf(Settings.num("touch_opacity"), 0.2, 1.0)
	if not _pad.visible:
		_release_all()
	_pad.queue_redraw()


func size_factor() -> float:
	return clampf(Settings.num("touch_size"), 0.7, 1.5)


func button_center(i: int) -> Vector2:
	var view := _pad.size
	var off: Vector2 = BUTTONS[i][3]
	return view + off * size_factor()


func button_radius(i: int) -> float:
	return float(BUTTONS[i][2]) * size_factor()


func _input(event: InputEvent) -> void:
	if not _pad.visible:
		return
	if event is InputEventScreenTouch:
		var pos: Vector2 = _to_pad(event.position)
		if event.pressed:
			_press(event.index, pos)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch:
			_stick_now = _to_pad(event.position)
			_apply_stick()
			_pad.queue_redraw()


func _to_pad(screen_pos: Vector2) -> Vector2:
	return _pad.get_global_transform_with_canvas().affine_inverse() * screen_pos


func _press(index: int, pos: Vector2) -> void:
	if get_tree().paused:
		return
	var view := _pad.size
	_pause_rect = Rect2(view.x - 84, 12, 72, 72)
	_hint_rect = Rect2(view.x - 84, 96, 72, 60)
	if _pause_rect.has_point(pos):
		_tap_action("pause")
		return
	for i in BUTTONS.size():
		if pos.distance_to(button_center(i)) <= button_radius(i) * 1.18:
			var action: String = BUTTONS[i][0]
			_held[index] = action
			Input.action_press(action)
			_pad.queue_redraw()
			return
	if pos.x < view.x * 0.5 and pos.y > view.y * 0.22 and _stick_touch == -1:
		_stick_touch = index
		_stick_origin = pos
		_stick_now = pos
		_pad.queue_redraw()


func _release(index: int) -> void:
	if index == _stick_touch:
		_stick_touch = -1
		_clear_stick()
	if _held.has(index):
		Input.action_release(_held[index])
		_held.erase(index)
	_pad.queue_redraw()


func _release_all() -> void:
	for index: int in _held.keys():
		Input.action_release(_held[index])
	_held.clear()
	_stick_touch = -1
	_clear_stick()


func _tap_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _apply_stick() -> void:
	var d := (_stick_now - _stick_origin) / (STICK_RADIUS * size_factor())
	if d.length() > 1.0:
		# let the base follow a long drag so the thumb never runs out of room
		_stick_origin = _stick_now - d.normalized() * STICK_RADIUS * size_factor()
		d = d.normalized()
	_set_axis("move_left", "move_right", d.x)
	# up / down need a firmer push so walking does not crouch by accident
	_set_axis("move_up", "move_down", d.y if absf(d.y) > 0.6 else 0.0)


func _set_axis(neg: String, pos: String, v: float) -> void:
	if v > DEAD:
		Input.action_press(pos, minf(1.0, v))
		Input.action_release(neg)
	elif v < -DEAD:
		Input.action_press(neg, minf(1.0, -v))
		Input.action_release(pos)
	else:
		Input.action_release(neg)
		Input.action_release(pos)


func _clear_stick() -> void:
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
		var plum := Color("301444")
		var font := UITheme.font_bold()
		for i in TouchControls.BUTTONS.size():
			var c := tc.button_center(i)
			var r := tc.button_radius(i)
			var action: String = TouchControls.BUTTONS[i][0]
			var down := tc._held.values().has(action)
			draw_circle(c, r, Color(plum.r, plum.g, plum.b, 0.55))
			var face := Color("ffcf3f") if i == 0 else Color("fff9ef")
			if down:
				face = Color("ff9a1f")
			face.a = 0.9
			draw_circle(c, r - 6.0, face)
			if font:
				var label: String = TouchControls.BUTTONS[i][1]
				var fs := int(r * 0.42)
				var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, c + Vector2(-w * 0.5, fs * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, plum)
		# pause button
		var pr := Rect2(size.x - 84, 12, 72, 72)
		draw_circle(pr.get_center(), 34.0, Color(plum.r, plum.g, plum.b, 0.55))
		draw_circle(pr.get_center(), 28.0, Color(1, 0.98, 0.94, 0.9))
		draw_rect(Rect2(pr.get_center() + Vector2(-11, -12), Vector2(8, 24)), plum)
		draw_rect(Rect2(pr.get_center() + Vector2(3, -12), Vector2(8, 24)), plum)
		# stick
		if tc._stick_touch != -1:
			var sr := TouchControls.STICK_RADIUS * tc.size_factor()
			draw_circle(tc._stick_origin, sr, Color(plum.r, plum.g, plum.b, 0.3))
			draw_arc(tc._stick_origin, sr, 0.0, TAU, 40, Color(1, 1, 1, 0.7), 4.0, true)
			var knob := tc._stick_origin + (tc._stick_now - tc._stick_origin).limit_length(sr)
			draw_circle(knob, sr * 0.48, Color(1, 0.98, 0.94, 0.9))
			draw_arc(knob, sr * 0.48, 0.0, TAU, 28, plum, 4.0, true)
		else:
			# resting hint for where the stick lives
			var rest := Vector2(150, size.y - 150)
			var sr2 := TouchControls.STICK_RADIUS * tc.size_factor()
			draw_arc(rest, sr2, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 4.0, true)
			draw_circle(rest, sr2 * 0.42, Color(1, 0.98, 0.94, 0.35))
