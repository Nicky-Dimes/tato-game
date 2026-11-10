extends Prop
## Warm rising air. Lifts a bubbled Tato quickly and slows a gliding fall.
## As a level entity: `updraft w=2 h=6` (anchored at the bottom-left cell).
## Braziers create one above themselves with setup_zone().

var size := Vector2(128, 384)
var blowing := true
var strength := 1.0
var _area: Area2D
var _clock := 0.0


func _configure() -> void:
	var w := maxi(p_int("w", 1), 1)
	var h := maxi(p_int("h", 4), 1)
	size = Vector2(w, h) * Layers.TILE
	position = Vector2(cell.x * Layers.TILE, (cell.y + 1 - h) * Layers.TILE)
	strength = p_float("power", 1.0)
	_build()
	if p_str("id") != "":
		blowing = false


func setup_zone(lv: Level, top_left: Vector2, zone_size: Vector2) -> void:
	level = lv
	position = top_left
	size = zone_size
	_build()


func _build() -> void:
	add_to_group("updraft")
	z_index = 3
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.PLAYER
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = size * 0.5
	_area.add_child(cs)
	add_child(_area)


func set_blowing(value: bool) -> void:
	blowing = value
	visible = value
	queue_redraw()


func on_link(count: int) -> void:
	set_blowing(count >= 1)


func contains(point: Vector2) -> bool:
	return blowing and Rect2(global_position, size).has_point(point)


func _physics_process(delta: float) -> void:
	_clock += delta
	if not blowing:
		return
	if not Settings.flag("reduced_motion") and int(_clock * 12.0) != int((_clock - delta) * 12.0):
		queue_redraw()
	for body in _area.get_overlapping_bodies():
		if body is Tato:
			_lift(body as Tato, delta)


func _lift(player: Tato, delta: float) -> void:
	var def: Resource = player.runner.active_def()
	var floaty := def != null and (def.get("tags") as PackedStringArray).has("bubble")
	if floaty:
		player.velocity.y = move_toward(player.velocity.y, -330.0 * strength, 1500.0 * delta)
	elif not player.is_on_floor() and not player.in_water:
		# a plain goose gets a soft cushion: enough to glide further, not to climb
		if player.velocity.y > -40.0:
			player.velocity.y -= 1150.0 * strength * delta


func _draw() -> void:
	if not blowing:
		return
	var col := Color(1, 1, 1, 0.22)
	var n := int(size.x / 26.0)
	for i in n:
		var x := 13.0 + i * 26.0
		var off := fmod(_clock * 150.0 + i * 57.0, size.y)
		var y := size.y - off
		var length := 34.0 + (i % 3) * 12.0
		draw_line(Vector2(x, y), Vector2(x + sin(off * 0.05) * 5.0, maxf(y - length, 0.0)), col, 5.0, true)
