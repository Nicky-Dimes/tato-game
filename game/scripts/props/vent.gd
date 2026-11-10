extends Prop
## A steam vent: puffs hot steam upward on a rhythm (`on=1.6 off=1.8 h=3`).
## Steam stings (a Comfort Feather) and pops bubbles. A cold honk freezes
## the vent shut for a while, and a frozen vent is safe to stand on.

var _area: Area2D
var _clock := 0.0
var _frozen := 0.0
var _h := 3
var _on := 1.6
var _off := 1.8
var blasting := false


func _configure() -> void:
	_h = maxi(p_int("h", 3), 1)
	_on = p_float("on", 1.6)
	_off = p_float("off", 1.8) * Settings.timer_factor()
	_clock = p_float("phase", 0.0)
	add_child(Art.standing("props/vent"))
	_area = add_touch(Vector2(44, _h * Layers.TILE), Vector2(0, -20 - _h * Layers.TILE * 0.5))
	add_sense(Vector2(60, 50), Vector2(0, -20))
	add_to_group("resettable")
	add_to_group("hazard")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"cold":
		_frozen = p_float("freeze", 8.0) * Settings.timer_factor()
		blasting = false
		AudioService.play("freeze", -4.0)
		Captions.caption("The vent freezes shut")
		queue_redraw()
		return true
	if tag == &"heat" and _frozen > 0.0:
		_frozen = 0.0
		return true
	return false


func _physics_process(delta: float) -> void:
	if _frozen > 0.0:
		_frozen -= delta
		if _frozen <= 0.0:
			_clock = _on
		queue_redraw()
		return
	_clock = fmod(_clock + delta, _on + _off)
	var now := _clock < _on
	if now != blasting:
		blasting = now
		if blasting and level != null and level.player != null and level.player.global_position.distance_to(global_position) < 700.0:
			AudioService.play("steam", -8.0)
	if blasting:
		for body in _area.get_overlapping_bodies():
			if body is Tato:
				(body as Tato).hurt(global_position + Vector2(0, 40))
	if not Settings.flag("reduced_motion") or blasting != now:
		queue_redraw()


func reset_puzzle() -> void:
	_frozen = 0.0


func _draw() -> void:
	if _frozen > 0.0:
		draw_rect(Rect2(-26, -34, 52, 16), Color("a9e4f5"))
		draw_rect(Rect2(-26, -34, 52, 16), Color("35507a"), false, 3.0)
		return
	var warn := _clock > _on + _off - 0.5
	if blasting:
		var top := -20.0 - _h * Layers.TILE
		for i in 5:
			var t := fmod(_clock * 2.2 + i * 0.2, 1.0)
			var y := lerpf(-24.0, top, t)
			draw_circle(Vector2(sin(i * 2.4 + _clock * 9.0) * 10.0, y), 15.0 + 9.0 * t, Color(1, 1, 1, 0.6 * (1.0 - t * 0.6)))
	elif warn:
		draw_circle(Vector2(0, -34), 7.0, Color(1, 1, 1, 0.7))
