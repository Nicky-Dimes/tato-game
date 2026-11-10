extends "res://scripts/food/abilities/jam.gd"
## Quiet Ink (Moonmint + Starberry Jam): paints paths (including the
## moonlit ones only this ink can fill in) while Tato is hush-quiet and
## unseen by watchful creatures.

func paint_tags() -> PackedStringArray:
	return PackedStringArray(["paint", "ink", "quiet"])


func is_quiet() -> bool:
	return true


func is_stealthy() -> bool:
	return true


func start() -> void:
	super.start()
	player.visual.tint = Color(0.82, 0.8, 1.0, 0.7)
	Captions.caption("Tato fades into the moonlight")


func tick(delta: float) -> void:
	super.tick(delta)
	player.noise = 0.0
