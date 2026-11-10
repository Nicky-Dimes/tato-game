class_name NoodleRope
extends Node2D
## The stretchy noodle (and tether) drawn between two points.

var a := Vector2.ZERO
var b := Vector2.ZERO
var wiggle := 0.0
var fill := Color("f2c879")
var slack := 0.0


func set_points(from: Vector2, to: Vector2, time: float = 0.0) -> void:
	a = from
	b = to
	wiggle = time
	queue_redraw()


func _draw() -> void:
	var pts := PackedVector2Array()
	var n := 14
	var dir := b - a
	if dir.length() < 2.0:
		return
	var normal := dir.orthogonal().normalized()
	for i in n + 1:
		var t := float(i) / n
		var wave := sin(t * 14.0 + wiggle * 22.0) * 5.0 * sin(t * PI)
		var sag := sin(t * PI) * slack
		pts.append(to_local(a + dir * t + normal * wave + Vector2(0, sag)))
	draw_polyline(pts, Color("3a1f4d"), 13.0, true)
	draw_polyline(pts, fill, 7.0, true)
	draw_circle(to_local(b), 9.0, Color("3a1f4d"))
	draw_circle(to_local(b), 6.0, fill.lightened(0.25))
