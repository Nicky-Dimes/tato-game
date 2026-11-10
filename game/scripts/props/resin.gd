extends Prop
## Soft amber resin: `resin w=3 t=8`. Too gooey to stand on until warmth
## (or a Caramel Coat) bakes it hard for a while; then it softens again.

var hard := false
var _body: StaticBody2D
var _timer := 0.0
var _w := 2


func _configure() -> void:
	_w = maxi(p_int("w", 2), 1)
	position = Vector2(cell.x * Layers.TILE, cell.y * Layers.TILE)
	_body = add_solid(Vector2(_w * Layers.TILE, 22), Vector2(_w * Layers.TILE * 0.5, 11), 0)
	_body.add_to_group("safe_ground")
	add_sense(Vector2(_w * Layers.TILE, 40), Vector2(_w * Layers.TILE * 0.5, 14))
	add_to_group("resettable")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"heat" or tag == &"bridge":
		_timer = p_float("t", 8.0) * Settings.timer_factor()
		if not hard:
			hard = true
			_body.collision_layer = Layers.WORLD
			AudioService.play("caramel")
			Captions.caption("The resin bakes hard")
			queue_redraw()
		return true
	return false


func _physics_process(delta: float) -> void:
	if not hard:
		return
	_timer -= delta
	if _timer < 1.5:
		modulate.a = 0.6 + 0.4 * absf(sin(_timer * 10.0))
	if _timer <= 0.0:
		reset_puzzle()
		Captions.caption("The resin goes soft again")


func reset_puzzle() -> void:
	hard = false
	_body.collision_layer = 0
	modulate.a = 1.0
	queue_redraw()


func _draw() -> void:
	var w := _w * float(Layers.TILE)
	if hard:
		draw_rect(Rect2(0, 0, w, 22), Color("c8742a"))
		draw_rect(Rect2(0, 0, w, 7), Color("ffd27a"))
		draw_rect(Rect2(0, 0, w, 22), Color("3a1f4d"), false, 3.0)
	else:
		var n := int(w / 32.0)
		for i in n:
			var x := 16.0 + i * 32.0
			draw_circle(Vector2(x, 12.0 + (i % 2) * 4.0), 15.0, Color(1.0, 0.72, 0.22, 0.55))
			draw_circle(Vector2(x - 4.0, 8.0 + (i % 2) * 4.0), 4.0, Color(1, 1, 1, 0.5))
