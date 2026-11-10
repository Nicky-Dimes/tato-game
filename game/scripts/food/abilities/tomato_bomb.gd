extends AbilityStrategy
## Bomb Blast: lobs a tomato that bursts in a big SPLAT. Hits everything
## near it and breaks cracked walls.

func start() -> void:
	shoot(Vector2(390, -500), {
		"look": "tomato", "life": 1.4, "radius": 15.0, "fall": 1300.0, "spin": 6.0,
		"splash": 125.0, "splash_damage": damage(), "damage": 1,
	})
	AudioService.voice("honk_boom")
	AudioService.play_varied("throw", -3.0)
	player.honked.emit(&"TOMATO_BOMB")
