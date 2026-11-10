extends AbilityStrategy
## Multi Shot: three melon slices in a fan.

func start() -> void:
	for angle: float in [-0.3, 0.0, 0.3]:
		var v := Vector2(580, 0).rotated(angle)
		shoot(Vector2(v.x, v.y - 60.0), {"look": "melon", "life": 0.9, "radius": 12.0, "fall": 520.0, "spin": 9.0})
	AudioService.voice("honk_melon")
	AudioService.play_varied("shot", -3.0)
	player.honked.emit(&"WATERMELON")
