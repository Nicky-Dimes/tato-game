extends AbilityStrategy
## Fire Shot: a fireball straight ahead. Melts ice, lights torches.

func start() -> void:
	shoot(Vector2(640, 0), {"look": "fire", "life": 0.85, "radius": 19.0})
	AudioService.voice("honk_fire")
	AudioService.play_varied("shot_fire", -3.0)
	player.honked.emit(&"FIRE_PEPPER")
