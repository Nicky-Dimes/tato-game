extends "res://scripts/food/abilities/melon.gd"
## Snowball Express (Frostberry + Watermelon): a bigger, faster, frosty ball.
## Freezes water as it rolls over, stops conveyor belts and smashes tough
## crates and heavy ice.

var _chill := 0.0


func _init() -> void:
	radius = 42.0
	top_speed = 520.0
	big = true


func ring_art() -> String:
	return "fx/snow_ring"


func _extra_move(delta: float) -> void:
	_chill -= delta
	if _chill <= 0.0:
		_chill = 0.1
		var ahead := player.global_position + Vector2(signf(player.velocity.x) * 70.0, 6.0)
		pulse(ahead, PackedStringArray(["cold"]), 130.0, {"life": 0.08, "style": "none", "info": {"freeze_time": 7.0}})
		if absf(player.velocity.x) > 120.0:
			Fx.burst(world(), player.global_position, "sparkle", Color(0.9, 0.98, 1.0), 2, {"spread": 30.0, "life": 0.4, "size": 5.0})
