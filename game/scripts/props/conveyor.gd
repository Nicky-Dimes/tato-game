extends Prop
## A conveyor belt: `conveyor w=4 dir=1 speed=130`. Carries whatever stands
## on it. A cold snap (Snowball Express, Ice Slide) freezes it still for a
## while. With `id=<id>` a link switches it off instead.

var _body: StaticBody2D
var _w := 4
var _dir := 1.0
var _speed := 130.0
var _frozen := 0.0
var _off := false
var _scroll := 0.0


func _configure() -> void:
	_w = maxi(p_int("w", 4), 1)
	_dir = signf(p_float("dir", 1.0))
	_speed = p_float("speed", 130.0)
	position = Vector2(cell.x * Layers.TILE, cell.y * Layers.TILE)
	_body = add_solid(Vector2(_w * Layers.TILE, 28), Vector2(_w * Layers.TILE * 0.5, 14), Layers.WORLD | Layers.INTERACT)
	_body.add_to_group("safe_ground_moving")
	add_to_group("resettable")
	_apply()


func on_link(count: int) -> void:
	_off = count >= 1
	_apply()


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"cold":
		if _frozen <= 0.0:
			AudioService.play("freeze", -4.0)
			Captions.caption("The belt freezes still")
		_frozen = p_float("freeze", 7.0) * Settings.timer_factor()
		_apply()
		return true
	if tag == &"heat" and _frozen > 0.0:
		_frozen = 0.0
		_apply()
		return true
	return false


func running() -> bool:
	return _frozen <= 0.0 and not _off


func _apply() -> void:
	_body.constant_linear_velocity = Vector2(_dir * _speed, 0) if running() else Vector2.ZERO
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _frozen > 0.0:
		_frozen -= delta
		if _frozen <= 0.0:
			_apply()
	if running() and not Settings.flag("reduced_motion"):
		_scroll = fmod(_scroll + _dir * _speed * delta, 32.0)
		if int(_scroll) % 3 == 0:
			queue_redraw()


func reset_puzzle() -> void:
	_frozen = 0.0
	_apply()


func _draw() -> void:
	var w := _w * float(Layers.TILE)
	var base := Color("6e7794") if running() else Color("a9e4f5")
	draw_rect(Rect2(0, 0, w, 28), base)
	draw_rect(Rect2(0, 0, w, 8), base.lightened(0.3))
	var x := fposmod(_scroll, 32.0) - 32.0
	while x < w:
		if x + 10.0 > 0.0 and x + 22.0 < w:
			var pts := PackedVector2Array([Vector2(x + 10, 12), Vector2(x + 22, 18), Vector2(x + 10, 24)])
			if _dir < 0.0:
				pts = PackedVector2Array([Vector2(x + 22, 12), Vector2(x + 10, 18), Vector2(x + 22, 24)])
			draw_colored_polygon(pts, Color("ffcf3f") if running() else Color("ffffff"))
		x += 32.0
	draw_rect(Rect2(0, 0, w, 28), Color("3a1f4d"), false, 3.0)
