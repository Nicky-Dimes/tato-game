extends AbilityStrategy
## Laser Beam: a bright beam that goes through every creature in a line and
## stops at solid ground.

const LENGTH := 880.0


func start() -> void:
	var from := player.muzzle()
	var dir := Vector2(player.facing, 0.0)
	var end := Hit.line(player.get_parent() as Node2D, from, dir, LENGTH, damage(), element(), player, 26.0)
	var beam := Beam.new()
	beam.a = from
	beam.b = end
	beam.z_index = 16
	world().add_child(beam)
	AudioService.voice("honk_zing")
	AudioService.play_varied("beam", -2.0)
	player.honked.emit(&"LEMON_BEAM")


class Beam:
	extends Node2D

	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var _age := 0.0

	func _process(delta: float) -> void:
		_age += delta
		queue_redraw()
		if _age >= 0.25:
			queue_free()

	func _draw() -> void:
		var t := _age / 0.25
		var w := 22.0 * (1.0 - t)
		var glow := Color(1.0, 0.93, 0.3, 0.4 if not Settings.flag("reduce_flashes") else 0.2)
		draw_line(a, b, glow, w + 14.0)
		draw_line(a, b, Color("ffe94a"), w)
		draw_line(a, b, Color(1, 1, 1), w * 0.4)
		draw_circle(b, w * 0.9, Color(1, 1, 1, 0.8))
