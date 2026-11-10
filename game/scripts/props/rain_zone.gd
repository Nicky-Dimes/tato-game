extends Prop
## Rain: `rain w=4 h=6`. Washes jam off sketched platforms and rinses honey
## from Tato's feet.

var size := Vector2(256, 384)
var _clock := 0.0
var _area: Area2D


func _configure() -> void:
	var w := maxi(p_int("w", 3), 1)
	var h := maxi(p_int("h", 5), 1)
	size = Vector2(w, h) * Layers.TILE
	position = Vector2(cell.x * Layers.TILE, (cell.y + 1 - h) * Layers.TILE)
	add_to_group("rain")
	z_index = 4
	_area = add_touch(size, size * 0.5)


func contains(point: Vector2) -> bool:
	return Rect2(global_position, size).has_point(point)


func _physics_process(delta: float) -> void:
	_clock += delta
	if not Settings.flag("reduced_motion") and int(_clock * 14.0) != int((_clock - delta) * 14.0):
		queue_redraw()
	for body in _area.get_overlapping_bodies():
		if body is Tato:
			var def: Resource = (body as Tato).runner.active_def()
			if def != null and (def.get("tags") as PackedStringArray).has("sticky"):
				(body as Tato).runner.cancel()
				Captions.caption("Rain rinses the honey away")


func _draw() -> void:
	var col := Color(0.75, 0.9, 1.0, 0.45)
	var n := int(size.x / 22.0)
	for i in n:
		var x := 11.0 + i * 22.0
		var off := fmod(_clock * 520.0 + i * 137.0, size.y)
		draw_line(Vector2(x, off), Vector2(x - 5.0, minf(off + 26.0, size.y)), col, 3.0)
		var off2 := fmod(off + size.y * 0.5, size.y)
		draw_line(Vector2(x + 9.0, off2), Vector2(x + 4.0, minf(off2 + 26.0, size.y)), col, 3.0)
