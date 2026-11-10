extends AbilityStrategy
## Honey Shot: a gooey glob that glues a creature to the spot.

func start() -> void:
	shoot(Vector2(500, -120), {"look": "honey", "life": 1.2, "radius": 14.0, "fall": 620.0, "bounces": 1})
	AudioService.voice("honk_sticky")
	AudioService.play_varied("squelch", -3.0)
	player.honked.emit(&"HONEYCOMB")
