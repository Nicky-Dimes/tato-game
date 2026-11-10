extends AbilityStrategy
## Pop Shot: a burst of kernels that arcs up and out. Good against things overhead.

func start() -> void:
	for i in 5:
		var angle := -1.35 + i * 0.26
		var v := Vector2(cos(angle), sin(angle)) * (470.0 + (i % 2) * 70.0)
		shoot(Vector2(absf(v.x) + 120.0, v.y), {"look": "kernel", "life": 1.0, "radius": 10.0, "fall": 1050.0, "bounces": 1})
	AudioService.voice("honk_pop")
	AudioService.play_varied("pop", -2.0)
	player.honked.emit(&"POPCORN")
