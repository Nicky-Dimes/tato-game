extends AbilityStrategy
## Ice Slide: a frosty honk that freezes water into ice, cools vents and
## chills creatures, followed by a speedy belly slide (very far on ice).

func start() -> void:
	var dir := Vector2(player.facing, 0.0)
	if player.move_y > 0.5 or not player.is_on_floor():
		dir = Vector2(player.facing * 0.5, 1.0).normalized()
	elif player.move_y < -0.5:
		dir = Vector2(player.facing * 0.35, -1.0).normalized()
	player.honk_pose(0.3)
	player.noise = 1.0
	AudioService.voice("honk_ice")
	AudioService.play("freeze", -4.0)
	var origin := player.global_position + Vector2(player.facing * 18.0, -34.0)
	pulse(origin, PackedStringArray(["cold", "honk"]), 230.0, {
		"cone": dir, "angle": 0.85, "life": 0.34, "style": "cone",
		"color": Color(0.7, 0.95, 1.0, 0.95), "info": {"freeze_time": 10.0},
	})
	for i in 3:
		Fx.burst(world(), origin + dir * (50.0 + i * 55.0), "sparkle", Color(0.85, 0.98, 1.0), 3, {"spread": 26.0, "life": 0.4, "size": 6.0})
	if player.is_on_floor() and player.move_y <= 0.5:
		player.force_slide(470.0, 0.55)
		AudioService.play("slide", -4.0)
	player.honked.emit(&"FROST")


func anim() -> String:
	return "slide" if player.sliding else "honk"
