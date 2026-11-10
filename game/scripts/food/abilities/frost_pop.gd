extends "res://scripts/food/abilities/popcorn.gd"
## Frost Pop (Frostberry + Popcorn): quick bounces, and every landing
## freezes puddles and pond water under Tato, so he can bounce across them.

var _chill := 0.0


func tick(delta: float) -> void:
	# freeze the water just before touching it, so there is ice to bounce on
	_chill -= delta
	if _chill <= 0.0 and player.velocity.y > 0.0:
		_chill = 0.08
		pulse(player.global_position + Vector2(0, 46.0), PackedStringArray(["cold"]), 96.0, {"life": 0.08, "style": "none", "info": {"freeze_time": 6.0}})


func _landing_extra(at: Vector2) -> void:
	pulse(at + Vector2(0, 8.0), PackedStringArray(["cold"]), 130.0, {"life": 0.2, "style": "ring", "color": Color(0.75, 0.96, 1.0, 0.9), "info": {"freeze_time": 6.0}})
