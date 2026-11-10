extends AbilityStrategy
## Fire Honk: a cone of warmth. Melts wax and ice, lights braziers, spins
## pinwheels. Hold up to aim it overhead.

func start() -> void:
	var dir := Vector2(player.facing, 0.0)
	if player.move_y < -0.5:
		dir = Vector2(player.facing * 0.35, -1.0).normalized()
	player.honk_pose(0.32)
	player.noise = 1.0
	AudioService.voice("honk_fire")
	var origin := player.global_position + Vector2(player.facing * 18.0, -40.0)
	pulse(origin, PackedStringArray(["heat", "honk"]), 235.0, {
		"cone": dir, "angle": 0.66, "life": 0.34, "style": "cone",
		"color": Color(1.0, 0.55, 0.15, 0.95),
	})
	for i in 3:
		Fx.burst(world(), origin + dir * (50.0 + i * 55.0), "puff", Color(1.0, 0.72 - i * 0.12, 0.2, 0.85), 3, {"spread": 22.0, "life": 0.35, "size": 9.0})
	player.honked.emit(&"PEPPER")
	if player.level != null:
		player.level.shake(2.0)


func anim() -> String:
	return "honk"
