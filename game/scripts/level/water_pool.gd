class_name WaterPool
extends Area2D
## A rectangle of water. Tato floats and paddles on top of it; a cold honk
## freezes the surface into temporary ice that can be walked on.

const THEME_COLORS := {
	"picnic": Color(0.36, 0.72, 0.96, 0.62),
	"farm": Color(0.98, 0.72, 0.25, 0.7),      # syrup river
	"fair": Color(0.55, 0.82, 0.98, 0.62),
	"market": Color(0.33, 0.78, 0.8, 0.62),
	"marsh": Color(0.25, 0.5, 0.75, 0.66),
	"kitchen": Color(0.6, 0.75, 0.95, 0.6),
	"nest": Color(0.36, 0.72, 0.96, 0.62),
}

var rect: Rect2
var color := Color(0.36, 0.72, 0.96, 0.62)
var _time := 0.0
var _ice: Array[IceSheet] = []


func setup(px_rect: Rect2, theme: String) -> void:
	rect = px_rect
	color = THEME_COLORS.get(theme, color)
	position = rect.position
	collision_layer = Layers.WATER | Layers.INTERACT
	collision_mask = 0
	monitoring = false
	monitorable = true
	z_index = 5          # drawn in front of Tato so feet look submerged
	add_to_group("water")
	add_to_group("interactable")
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = rect.size * 0.5
	add_child(cs)


func surface_y() -> float:
	return rect.position.y


func _process(delta: float) -> void:
	if Settings.flag("reduced_motion"):
		return
	_time += delta
	# redraw the shimmer a few times a second, not every frame
	if int(_time * 6.0) != int((_time - delta) * 6.0):
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, rect.size), color)
	var top := Color(1, 1, 1, 0.55)
	var segments := int(rect.size.x / 32.0)
	for i in segments:
		var x := i * 32.0 + 4.0
		var wob := sin(_time * 2.0 + i * 0.9) * 2.0
		draw_rect(Rect2(x, 2.0 + wob, 22.0, 4.0), top)
	draw_rect(Rect2(0, 0, rect.size.x, 3.0), Color(1, 1, 1, 0.35))


## Flavour reactions: cold freezes the surface near the honk.
func on_effect(tag: StringName, info: Dictionary) -> bool:
	if tag == &"cold":
		var at: Vector2 = info.get("position", global_position)
		var radius: float = info.get("radius", 160.0)
		freeze_around(at.x, radius, float(info.get("freeze_time", 10.0)))
		return true
	if tag == &"heat":
		var at2: Vector2 = info.get("position", global_position)
		var melted := false
		for sheet in _ice.duplicate():
			if is_instance_valid(sheet) and absf(sheet.global_position.x + sheet.width * 0.5 - at2.x) < sheet.width * 0.5 + 120.0:
				sheet.melt()
				melted = true
		return melted
	return false


func freeze_around(world_x: float, radius: float, seconds: float) -> void:
	var left := maxf(world_x - radius, rect.position.x)
	var right := minf(world_x + radius, rect.end.x)
	# snap to the tile grid so sheets line up
	left = floorf(left / Layers.TILE) * Layers.TILE
	right = ceilf(right / Layers.TILE) * Layers.TILE
	left = maxf(left, rect.position.x)
	right = minf(right, rect.end.x)
	if right - left < 16.0:
		return
	# refresh sheets that already cover this span
	for sheet in _ice:
		if is_instance_valid(sheet) and sheet.global_position.x <= left + 1.0 and sheet.global_position.x + sheet.width >= right - 1.0:
			sheet.refresh(seconds)
			return
	var sheet := IceSheet.new()
	sheet.setup(right - left, seconds * Settings.timer_factor())
	get_parent().add_child(sheet)
	sheet.global_position = Vector2(left, rect.position.y - 6.0)
	_ice.append(sheet)
	sheet.tree_exited.connect(func() -> void: _ice.erase(sheet))
	AudioService.play("freeze")
	Captions.caption("Water freezes into ice")
