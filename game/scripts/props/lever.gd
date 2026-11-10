extends Prop
## A lever. Bop it with any attack (or walk up and press up) to flip it.
## `opens=<id>`; `once` locks after the first flip.

var on := false
var _start := false


func _configure() -> void:
	add_sense(Vector2(70, 80), Vector2(0, -40))
	add_solid(Vector2(50, 60), Vector2(0, -30), Layers.INTERACT)
	add_to_group("resettable")
	add_to_group("hittable")
	_start = p_flag("on")
	if _start:
		flip(false)


func can_interact(_player: Tato) -> bool:
	return not (p_flag("once") and on)


func prompt() -> String:
	return "Pull lever"


func uses_attack_button() -> bool:
	return true


func interact(_player: Tato) -> void:
	flip()


func take_hit(_damage: int, _info: Dictionary) -> bool:
	if p_flag("once") and on:
		return false
	flip()
	return true


func flip(announce: bool = true) -> void:
	on = not on
	queue_redraw()
	if announce:
		AudioService.play("lever")
		Captions.caption("Clunk! A lever flips")
	level.trigger(p_str("opens"), on, self)


func reset_puzzle() -> void:
	if on != _start and not p_flag("once"):
		flip(false)


func _draw() -> void:
	var lean := 0.6 if on else -0.6
	var tip := Vector2(sin(lean), -cos(lean)) * 52.0 + Vector2(0, -14)
	draw_line(Vector2(0, -14), tip, Color("3a1f4d"), 12.0)
	draw_line(Vector2(0, -14), tip, Color("e2e7fa"), 6.0)
	draw_circle(tip, 13.0, Color("3a1f4d"))
	draw_circle(tip, 9.5, Color("6fc96a") if on else Color("f0452e"))
	draw_rect(Rect2(-28, -22, 56, 22), Color("8a93b0"))
	draw_rect(Rect2(-28, -22, 56, 22), Color("3a1f4d"), false, 3.0)
