extends Prop
## A reset bell: puts every loose puzzle piece in the room back where it
## started, so a puzzle can never be left unsolvable.

func _configure() -> void:
	add_child(Art.standing("props/reset"))
	add_sense(Vector2(70, 80), Vector2(0, -40))


func can_interact(_player: Tato) -> bool:
	return true


func prompt() -> String:
	return "Reset puzzle"


func interact(_player: Tato) -> void:
	level.reset_puzzles()
	AudioService.play("reset")
	Fx.pop_ring(level, global_position + Vector2(0, -40), Color(0.7, 0.9, 1.0), 80.0)
	Captions.caption("Everything pops back into place")
