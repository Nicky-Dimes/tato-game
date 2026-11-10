extends Prop
## A platform that glides back and forth.
##   w=3          width in cells
##   dx=4 dy=0    how far it travels (cells)
##   t=3          seconds for one trip
##   id=<id>      if set, it only moves while that link is on (and returns when off)
##   thin         you can jump up through it

var _body: AnimatableBody2D
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _phase := 0.0
var _period := 3.0
var _linked := false
var _active := true
var _width := 3


func _configure() -> void:
	_width = maxi(p_int("w", 3), 1)
	position = Vector2(cell.x * Layers.TILE, cell.y * Layers.TILE)
	_from = position
	_to = _from + Vector2(p_float("dx", 0.0), p_float("dy", 0.0)) * Layers.TILE
	_period = maxf(p_float("t", 3.0), 0.5)
	_linked = p_str("id") != ""
	_active = not _linked and not p_flag("pull")
	_body = AnimatableBody2D.new()
	_body.collision_layer = Layers.ONEWAY if p_flag("thin") else Layers.WORLD
	_body.collision_mask = 0
	_body.sync_to_physics = false
	_body.add_to_group("safe_ground_moving")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(_width * Layers.TILE, 22)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(_width * Layers.TILE * 0.5, 11)
	cs.one_way_collision = p_flag("thin")
	_body.add_child(cs)
	add_child(_body)
	for i in _width:
		var s := Art.icon(WorldKit.art(level.theme, "plat"), 64.0)
		s.position = Vector2((i + 0.5) * Layers.TILE, 14)
		_body.add_child(s)
	if p_flag("pull"):
		add_to_group("taffy_target")
		add_sense(Vector2(_width * Layers.TILE, 60), Vector2(_width * Layers.TILE * 0.5, 0))


func on_link(count: int) -> void:
	if _linked:
		_active = count >= maxi(p_int("needs", 1), 1)


## Taffy Balloon: tug the platform toward its far point for a while.
func on_effect(tag: StringName, info: Dictionary) -> bool:
	if tag == &"pull" and p_flag("pull"):
		_active = true
		_hold = float(info.get("hold", 5.0)) * Settings.timer_factor()
		Captions.caption("The platform is tugged closer")
		return true
	return false


var _hold := 0.0


func _physics_process(delta: float) -> void:
	var before := _phase
	if _linked or p_flag("pull"):
		if p_flag("pull") and _active:
			_hold -= delta
			if _hold <= 0.0:
				_active = false
		_phase = move_toward(_phase, 1.0 if _active else 0.0, delta / _period)
	elif _active:
		_phase = fmod(_phase + delta / (_period * 2.0), 1.0)
	var k := _phase
	if not (_linked or p_flag("pull")):
		k = 1.0 - absf(_phase * 2.0 - 1.0)
		k = k * k * (3.0 - 2.0 * k)
	if before != _phase or not (_linked or p_flag("pull")):
		_body.position = (_to - _from) * k


func center() -> Vector2:
	return _body.global_position + Vector2(_width * Layers.TILE * 0.5, 0)
