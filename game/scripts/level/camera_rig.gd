class_name CameraRig
extends Camera2D
## Follows Tato with a gentle look-ahead and never shows outside the stage.
## Shake is scaled by the player's setting and switched off by Reduced Motion.

var target: Node2D
var level_size := Vector2(1280, 720)
var look_ahead := 90.0
var _look := 0.0
var _shake := 0.0
var _focus: Variant = null       # optional Vector2 the camera eases to (cutscenes, bosses)
var _zoom_target := 1.0


func setup(follow: Node2D, size: Vector2) -> void:
	target = follow
	level_size = size
	limit_left = 0
	limit_top = 0
	limit_right = int(size.x)
	limit_bottom = int(size.y)
	position_smoothing_enabled = false
	_fit_zoom()
	if target:
		global_position = target.global_position + Vector2(0, -60)
	get_viewport().size_changed.connect(_fit_zoom)
	make_current()


func _fit_zoom() -> void:
	# Never show beyond a small stage: zoom in until the stage fills the view.
	var view := get_viewport_rect().size
	var z := maxf(1.0, maxf(view.x / maxf(level_size.x, 1.0), view.y / maxf(level_size.y, 1.0)))
	_zoom_target = z
	zoom = Vector2(z, z)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount * Settings.shake_amount())


func focus_on(point: Variant) -> void:
	_focus = point


func snap() -> void:
	if target:
		global_position = target.global_position + Vector2(0, -60)
		reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var goal: Vector2
	if _focus != null:
		goal = _focus
	else:
		var facing := 1.0
		if target is Tato:
			facing = (target as Tato).facing
			var speed := absf((target as Tato).velocity.x)
			var want := facing * look_ahead * clampf(speed / 200.0, 0.0, 1.0)
			_look = lerpf(_look, want, clampf(delta * 2.2, 0.0, 1.0))
		goal = target.global_position + Vector2(_look, -70.0)
	var k := 1.0 - exp(-delta * (5.0 if Settings.flag("reduced_motion") else 8.0))
	global_position = global_position.lerp(goal, k)
	if _shake > 0.05:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = lerpf(_shake, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	else:
		offset = Vector2.ZERO
