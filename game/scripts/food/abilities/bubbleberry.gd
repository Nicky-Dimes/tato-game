extends AbilityStrategy
## A useful forward attack first; bubbles rise gently only after crossing the fight.
func start() -> void:
	for i in 2:
		var bubble := shoot(Vector2(480 + i * 45, 0), {"look": "bubble", "life": 2.3, "radius": 22.0, "wobble": 8.0, "fall": 0.0})
		bubble.global_position.y = player.global_position.y - 44.0 - i * 8.0
	AudioService.voice("honk_bubble")
	AudioService.play_varied("bubble_up", -3.0)
	player.honked.emit(&"BUBBLEBERRY")
