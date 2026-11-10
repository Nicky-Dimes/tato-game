class_name Fx
extends Node2D
## Tiny, cheap visual effects (dust puffs, sparkles, rings, floating text).
## Each burst is one node that draws a handful of circles and frees itself,
## which keeps phones and tablets comfortable (no particle systems).

var kind := "puff"
var color := Color.WHITE
var count := 5
var spread := 28.0
var life := 0.4
var rise := 18.0
var size := 7.0
var seed_value := 0
var text := ""
var _age := 0.0
var _dirs: Array[Vector2] = []
var _label: Label

static var live_count := 0
const MAX_LIVE := 40


static func burst(parent: Node, at: Vector2, fx_kind: String, fx_color: Color, fx_count: int = 5, opts: Dictionary = {}) -> Fx:
	if parent == null or not is_instance_valid(parent) or live_count >= MAX_LIVE:
		return null
	if Settings.flag("reduced_motion") and fx_kind != "text":
		fx_count = mini(fx_count, 2)
	var fx := Fx.new()
	fx.kind = fx_kind
	fx.color = fx_color
	fx.count = fx_count
	fx.spread = float(opts.get("spread", 28.0))
	fx.life = float(opts.get("life", 0.4))
	fx.rise = float(opts.get("rise", 18.0))
	fx.size = float(opts.get("size", 7.0))
	fx.z_index = int(opts.get("z", 25))
	parent.add_child(fx)
	fx.global_position = at
	return fx


static func puff(parent: Node, at: Vector2, fx_color: Color = Color(1, 1, 1, 0.85), fx_count: int = 4) -> void:
	burst(parent, at, "puff", fx_color, fx_count)


static func sparkle(parent: Node, at: Vector2, fx_color: Color = Color(1, 0.95, 0.5), fx_count: int = 6) -> void:
	burst(parent, at, "sparkle", fx_color, fx_count, {"spread": 44.0, "life": 0.55, "size": 6.0})


static func pop_ring(parent: Node, at: Vector2, fx_color: Color = Color.WHITE, radius: float = 40.0) -> void:
	burst(parent, at, "ring", fx_color, 1, {"spread": radius, "life": 0.3})


static func float_text(parent: Node, at: Vector2, message: String, fx_color: Color = Color.WHITE) -> void:
	var fx := burst(parent, at, "text", fx_color, 1, {"life": 1.1, "rise": 46.0, "z": 40})
	if fx:
		fx.set_text(message)


func set_text(message: String) -> void:
	text = message
	_label = UITheme.outlined_label(message, 24, color)
	_label.position = Vector2(-150, -18)
	_label.size = Vector2(300, 36)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func _ready() -> void:
	live_count += 1
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var a := rng.randf_range(0.0, TAU)
		if kind == "puff":
			a = rng.randf_range(PI * 1.05, PI * 1.95)   # upward fan
		_dirs.append(Vector2.from_angle(a) * rng.randf_range(0.45, 1.0))


func _exit_tree() -> void:
	live_count = maxi(live_count - 1, 0)


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	if kind == "text":
		var t := _age / life
		position.y -= rise * delta / life
		if _label:
			_label.modulate.a = clampf((1.0 - t) * 3.0, 0.0, 1.0)
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / life, 0.0, 1.0)
	var ease_t := 1.0 - pow(1.0 - t, 2.0)
	var c := color
	c.a *= 1.0 - t
	match kind:
		"puff":
			for d in _dirs:
				draw_circle(d * spread * ease_t + Vector2(0, -rise * ease_t * 0.4), size * (1.0 + t * 0.6) * (0.6 + d.length() * 0.5), c)
		"sparkle":
			for d in _dirs:
				var p := d * spread * ease_t + Vector2(0, -rise * t)
				var s := size * (1.0 - t * 0.7)
				draw_rect(Rect2(p - Vector2(s, s * 0.28), Vector2(s * 2.0, s * 0.56)), c)
				draw_rect(Rect2(p - Vector2(s * 0.28, s), Vector2(s * 0.56, s * 2.0)), c)
		"ring":
			draw_arc(Vector2.ZERO, spread * lerpf(0.3, 1.0, ease_t), 0.0, TAU, 28, c, lerpf(7.0, 2.0, t), true)
		"crumbs":
			for d in _dirs:
				var p2 := d * spread * ease_t + Vector2(0, 60.0 * t * t)
				draw_circle(p2, size * 0.5, c)
