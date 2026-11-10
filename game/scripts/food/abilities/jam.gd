extends AbilityStrategy
## Jam Trail: starberry jam drips wherever Tato goes. Sketched outlines he
## passes turn into real, solid platforms for a while. Rain washes it off.

var _paint := 0.0
var _blob := 0.0


func kind() -> String:
	return KIND_TOGGLE


func paint_tags() -> PackedStringArray:
	return PackedStringArray(["paint"])


func start() -> void:
	player.visual.tint = Color(1.0, 0.88, 0.96)
	AudioService.voice("honk_jam")
	AudioService.play("squelch", -3.0)
	player.honk_pose(0.25)
	player.honked.emit(def.get("id"))
	_spray()


func _spray() -> void:
	pulse(player.global_position + Vector2(0, -24), paint_tags(), 118.0, {"life": 0.1, "style": "none", "info": {"paint_time": 10.0}})


func tick(delta: float) -> void:
	_paint -= delta
	if _paint <= 0.0:
		_paint = 0.12
		_spray()
	_blob -= delta
	if _blob <= 0.0 and player.velocity.length() > 30.0:
		_blob = 0.1
		Fx.burst(world(), player.global_position + Vector2(-player.facing * 8.0, -6.0), "crumbs", color(), 1, {"spread": 6.0, "life": 0.7, "size": 12.0, "z": 1})


func stop() -> void:
	player.visual.tint = Color.WHITE
