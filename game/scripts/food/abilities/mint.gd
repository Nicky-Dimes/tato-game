extends AbilityStrategy
## Quiet Honk: for a little while Tato's feet are silent and listening
## creatures cannot hear him. Each press sends a soft hush-honk that calms
## jumpy creatures (it does not ring chimes).

var _hush_cd := 0.0
var _notes := 0.0


func kind() -> String:
	return KIND_TOGGLE


func is_quiet() -> bool:
	return true


func start() -> void:
	player.visual.tint = Color(0.82, 1.0, 0.95)
	player.noise = 0.0
	_hush()
	player.honked.emit(&"MINT")
	Captions.caption("Shhh... Tato tiptoes")


func button_pressed_again() -> void:
	if _hush_cd <= 0.0:
		_hush()


func _hush() -> void:
	_hush_cd = 0.6
	player.honk_pose(0.25)
	AudioService.voice("honk_quiet", -4.0)
	pulse(player.global_position + Vector2(player.facing * 12.0, -40.0), PackedStringArray(["quiet"]), 200.0, {
		"life": 0.4, "style": "ring", "color": Color(0.55, 1.0, 0.88, 0.7),
	})


func tick(delta: float) -> void:
	_hush_cd = maxf(_hush_cd - delta, 0.0)
	player.noise = 0.0
	_notes -= delta
	if _notes <= 0.0:
		_notes = 0.7
		Fx.burst(world(), player.global_position + Vector2(0, -80), "sparkle", Color(0.6, 1.0, 0.9, 0.8), 1, {"spread": 14.0, "life": 0.6, "size": 4.0})


func stop() -> void:
	player.visual.tint = Color.WHITE
