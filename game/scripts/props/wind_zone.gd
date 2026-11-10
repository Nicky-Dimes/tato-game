extends Prop
## A sideways breeze: `wind w=4 h=3 dir=1 power=1`. Pushes a floating or
## bouncing Tato along; a waddling goose only feels a nudge.
## With `id=<id>` it only blows while that link is on.

var size := Vector2(256, 192)
var blowing := true
var _area: Area2D
var _clock := 0.0
var _dir := 1.0


func _configure() -> void:
	var w := maxi(p_int("w", 3), 1)
	var h := maxi(p_int("h", 3), 1)
	size = Vector2(w, h) * Layers.TILE
	position = Vector2(cell.x * Layers.TILE, (cell.y + 1 - h) * Layers.TILE)
	_dir = signf(p_float("dir", 1.0))
	add_to_group("wind")
	z_index = 3
	_area = add_touch(size, size * 0.5)
	if p_str("id") != "":
		blowing = false
		visible = false


func on_link(count: int) -> void:
	blowing = count >= 1
	visible = blowing


func push() -> float:
	return _dir * p_float("power", 1.0)


func contains(point: Vector2) -> bool:
	return blowing and Rect2(global_position, size).has_point(point)


func _physics_process(delta: float) -> void:
	_clock += delta
	if not blowing:
		return
	if not Settings.flag("reduced_motion") and int(_clock * 12.0) != int((_clock - delta) * 12.0):
		queue_redraw()
	for body in _area.get_overlapping_bodies():
		if body is Tato:
			var player := body as Tato
			var floaty := player.runner.overrides_movement() or not player.is_on_floor()
			var force := (520.0 if floaty else 140.0) * push()
			player.velocity.x += force * delta


func _draw() -> void:
	if not blowing:
		return
	var col := Color(1, 1, 1, 0.25)
	var n := int(size.y / 30.0)
	for i in n:
		var y := 15.0 + i * 30.0
		var off := fmod(_clock * 240.0 + i * 91.0, size.x)
		var x := off if _dir > 0.0 else size.x - off
		draw_line(Vector2(x, y), Vector2(clampf(x - _dir * 46.0, 0.0, size.x), y + sin(off * 0.04) * 4.0), col, 4.0, true)
