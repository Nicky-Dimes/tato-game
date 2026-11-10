extends Prop
## Platforms that are only there for a while after the right flavour
## touches them. One script, four looks:
##   inkplat   hidden ink, shown by light            (Flash Zing)
##   glowcap   a fungus cap that firms up in light   (Flash Zing)
##   sketch    a dotted outline, made real by jam    (Jam Trail); `ink` = only Quiet Ink
##   sunstep   a ghostly cloud, made solid by sun    (Sunbeam Steps)
## `w=3` width in cells, `t=8` seconds solid. Rain washes painted sketches.

const TAGS := {"inkplat": &"light", "glowcap": &"light", "sketch": &"paint", "sunstep": &"reveal"}
const COLORS := {
	"inkplat": Color("5b3a78"), "glowcap": Color("56e0c0"),
	"sketch": Color("e0389a"), "sunstep": Color("ffe27a"),
}

var solid := false
var _kind := "sketch"
var _w := 3
var _timer := 0.0
var _body: StaticBody2D
var _clock := 0.0


func _configure() -> void:
	_kind = p_str("type", "sketch")
	_w = maxi(p_int("w", 3), 1)
	position = Vector2(cell.x * Layers.TILE, cell.y * Layers.TILE)
	_body = StaticBody2D.new()
	_body.collision_layer = 0
	_body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(_w * Layers.TILE, 16)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(_w * Layers.TILE * 0.5, 8)
	cs.one_way_collision = true
	cs.one_way_collision_margin = 6.0
	_body.add_child(cs)
	add_child(_body)
	add_sense(Vector2(_w * Layers.TILE, 44), Vector2(_w * Layers.TILE * 0.5, 10))
	add_to_group("resettable")
	z_index = 1


func on_effect(tag: StringName, info: Dictionary) -> bool:
	if tag != TAGS.get(_kind, &"paint"):
		return false
	if p_flag("ink") and not (info.get("tags", PackedStringArray()) as PackedStringArray).has("ink"):
		return false
	var seconds := p_float("t", float(info.get("paint_time", info.get("solid_time", 8.0))))
	_timer = seconds * Settings.timer_factor()
	if not solid:
		solid = true
		_body.collision_layer = Layers.ONEWAY
		AudioService.play("appear", -4.0)
		queue_redraw()
	return true


func _physics_process(delta: float) -> void:
	_clock += delta
	if not solid:
		return
	var drain := 1.0
	if _kind == "sketch":
		for r in get_tree().get_nodes_in_group("rain"):
			if r.has_method("contains") and r.call("contains", global_position + Vector2(_w * Layers.TILE * 0.5, 0)):
				drain = 8.0
				break
	_timer -= delta * drain
	if _timer < 1.5:
		modulate.a = 0.5 + 0.5 * absf(sin(_timer * 10.0))
	if _timer <= 0.0:
		reset_puzzle()


func reset_puzzle() -> void:
	solid = false
	_body.collision_layer = 0
	modulate.a = 1.0
	queue_redraw()


func _draw() -> void:
	var w := _w * float(Layers.TILE)
	var col: Color = COLORS.get(_kind, Color.WHITE)
	if solid:
		match _kind:
			"sunstep":
				_blob_row(w, Color(1.0, 0.97, 0.8), col)
			"glowcap":
				draw_rect(Rect2(4, 0, w - 8, 18), col)
				draw_rect(Rect2(4, 0, w - 8, 6), col.lightened(0.4))
				draw_rect(Rect2(4, 0, w - 8, 18), Color("1e1a3c"), false, 3.0)
			_:
				draw_rect(Rect2(0, 0, w, 18), col)
				draw_rect(Rect2(0, 0, w, 6), col.lightened(0.35))
				draw_rect(Rect2(0, 0, w, 18), Color("3a1f4d"), false, 3.0)
		return
	# not there yet: a hint of where it will be (never a full spoiler-free blank)
	var faint := col
	faint.a = 0.5 if _kind == "sketch" or _kind == "sunstep" else 0.22
	if p_flag("ink"):
		faint = Color(0.6, 0.55, 1.0, 0.4)
	var x := 0.0
	while x < w:
		draw_rect(Rect2(x, 0, minf(14.0, w - x), 3), faint)
		draw_rect(Rect2(x, 15, minf(14.0, w - x), 3), faint)
		x += 24.0
	draw_rect(Rect2(0, 0, 3, 18), faint)
	draw_rect(Rect2(w - 3, 0, 3, 18), faint)


func _blob_row(w: float, fill: Color, edge: Color) -> void:
	var n := maxi(int(w / 34.0), 2)
	for i in n:
		draw_circle(Vector2(18.0 + i * (w - 36.0) / maxf(n - 1, 1), 10.0), 17.0, edge)
	for i in n:
		draw_circle(Vector2(18.0 + i * (w - 36.0) / maxf(n - 1, 1), 9.0), 13.0, fill)
