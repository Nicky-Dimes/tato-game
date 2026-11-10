extends AbilityStrategy
## Shield Guard: a warm cocoa bubble for a couple of seconds. Nothing hurts
## Tato inside it, creatures that touch it get bumped, shots bounce back.

var _ring: ShieldRing
var _bump := 0.0


func kind() -> String:
	return KIND_TOGGLE


func blocks_hurt() -> bool:
	return true


func start() -> void:
	_ring = ShieldRing.new()
	_ring.tint = accent()
	_ring.position = Vector2(0, -36)
	player.visual.front.add_child(_ring)
	AudioService.voice("honk_puff")
	AudioService.play("shield")
	player.honked.emit(&"COCOA_SHIELD")


func tick(delta: float) -> void:
	_bump -= delta
	if _bump <= 0.0:
		_bump = 0.2
		Hit.burst(player.get_parent(), player.global_position + Vector2(0, -36), 58.0, damage(), element(), player, {"silent": true, "knock": 360.0})
	for shot in player.get_tree().get_nodes_in_group("enemy_shot"):
		var s := shot as Projectile
		if s != null and s.global_position.distance_to(player.global_position + Vector2(0, -36)) < 70.0:
			s.reflect(player)
	if _ring != null and time_left < 0.6:
		_ring.modulate.a = 0.4 + 0.6 * absf(sin(time_left * 14.0))


func stop() -> void:
	if _ring != null and is_instance_valid(_ring):
		_ring.queue_free()
	Fx.pop_ring(world(), player.global_position + Vector2(0, -36), accent(), 60.0)


class ShieldRing:
	extends Node2D

	var tint := Color(1, 0.85, 0.66)

	func _draw() -> void:
		var fill := tint
		fill.a = 0.28
		draw_circle(Vector2.ZERO, 54.0, fill)
		draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 40, Color(0.54, 0.35, 0.24, 0.95), 5.0, true)
		draw_arc(Vector2.ZERO, 47.0, -2.4, -1.2, 12, Color(1, 1, 1, 0.85), 5.0, true)
