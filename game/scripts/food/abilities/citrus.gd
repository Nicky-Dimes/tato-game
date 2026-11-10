extends AbilityStrategy
## Flash Zing: a zing of light. A beam shoots ahead (or up while holding
## up), bounces off mirrors and wakes lamps; a soft flash around Tato
## reveals hidden ink and bright fungi. The beam needs a clear line of sight.

func start() -> void:
	var dir := Vector2(player.facing, 0.0)
	if player.move_y < -0.5:
		dir = Vector2.UP
	elif player.move_y > 0.5 and not player.is_on_floor():
		dir = Vector2.DOWN
	player.honk_pose(0.3)
	player.noise = 1.0
	AudioService.voice("honk_zing")
	AudioService.play("zing")
	var origin := player.global_position + Vector2(player.facing * 16.0, -40.0)
	pulse(origin, PackedStringArray(["light", "honk"]), 185.0, {
		"life": 0.3, "style": "flash",
		"color": Color(1.0, 0.95, 0.5, 0.5 if Settings.flag("reduce_flashes") else 0.95),
	})
	LightBeam.fire(world(), origin, dir, player)
	player.honked.emit(&"CITRUS")


func anim() -> String:
	return "honk"
