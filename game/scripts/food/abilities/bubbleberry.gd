extends AbilityStrategy
## Bubble Trap: two wobbly bubbles. A creature caught in one floats away.

func start() -> void:
	for i in 2:
		shoot(Vector2(300 + i * 70, -30 - i * 50), {"look": "bubble", "life": 1.5, "radius": 16.0, "wobble": 50.0, "fall": -60.0})
	AudioService.voice("honk_bubble")
	AudioService.play_varied("bubble_up", -3.0)
	player.honked.emit(&"BUBBLEBERRY")
