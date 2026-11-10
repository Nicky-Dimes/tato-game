class_name Terrain
extends Node2D
## Builds a stage's ground from LevelData: merged collision boxes (so Tato
## never snags on tile seams), slopes, one-way platforms, water volumes and
## the auto-tiled picture (one batched TileMapLayer, cheap on phones).

const TILE := Layers.TILE
const SUB := 64                 # atlas sub-tile size in texture pixels (2x art)
const ATLAS_COLS := 8
const ATLAS_ROWS := 15
const MATERIAL_BASE := {LevelData.SOLID: 0, LevelData.STRUCT: 5, LevelData.ICE: 10}

var data: LevelData
var theme := "picnic"
var tiles: TileMapLayer
var solid_body: StaticBody2D
var ice_body: StaticBody2D
var oneway_body: StaticBody2D
var water_rects: Array[Rect2] = []
var water_areas: Array[Area2D] = []


func build(level: LevelData, theme_name: String) -> void:
	data = level
	theme = theme_name
	_build_collision()
	_build_water()
	_build_tiles()


# ---------------------------------------------------------------- collision --

func _build_collision() -> void:
	solid_body = StaticBody2D.new()
	solid_body.name = "Solid"
	solid_body.collision_layer = Layers.WORLD
	solid_body.collision_mask = 0
	add_child(solid_body)
	ice_body = StaticBody2D.new()
	ice_body.name = "Ice"
	ice_body.collision_layer = Layers.WORLD
	ice_body.collision_mask = 0
	ice_body.add_to_group("ice")
	add_child(ice_body)
	oneway_body = StaticBody2D.new()
	oneway_body.name = "OneWay"
	oneway_body.collision_layer = Layers.ONEWAY
	oneway_body.collision_mask = 0
	add_child(oneway_body)

	for rect in merged_rects(func(c: int) -> bool: return c == LevelData.SOLID or c == LevelData.STRUCT):
		_add_box(solid_body, rect)
	for rect in merged_rects(func(c: int) -> bool: return c == LevelData.ICE):
		_add_box(ice_body, rect)
	_build_slopes()
	# one-way platforms: thin strips along the top of each run
	for y in data.height:
		var x := 0
		while x < data.width:
			if data.cell(x, y) == LevelData.ONEWAY:
				var start := x
				while x < data.width and data.cell(x, y) == LevelData.ONEWAY:
					x += 1
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - start) * TILE, 14)
				var cs := CollisionShape2D.new()
				cs.shape = shape
				cs.position = Vector2((start + x) * 0.5 * TILE, y * TILE + 7)
				cs.one_way_collision = true
				cs.one_way_collision_margin = 6.0
				oneway_body.add_child(cs)
			else:
				x += 1


func _add_box(body: StaticBody2D, cells_rect: Rect2i) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(cells_rect.size) * TILE
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = (Vector2(cells_rect.position) + Vector2(cells_rect.size) * 0.5) * TILE
	body.add_child(cs)


## Greedy merge of matching cells into as few rectangles as possible.
func merged_rects(matches: Callable) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	var used := PackedByteArray()
	used.resize(data.width * data.height)
	used.fill(0)
	for y in data.height:
		var x := 0
		while x < data.width:
			var idx := y * data.width + x
			if used[idx] == 0 and matches.call(data.cells[idx]):
				var w := 1
				while x + w < data.width and used[idx + w] == 0 and matches.call(data.cells[idx + w]):
					w += 1
				var h := 1
				var grow := true
				while grow and y + h < data.height:
					for i in w:
						var j := (y + h) * data.width + x + i
						if used[j] != 0 or not matches.call(data.cells[j]):
							grow = false
							break
					if grow:
						h += 1
				for yy in h:
					for xx in w:
						used[(y + yy) * data.width + x + xx] = 1
				out.append(Rect2i(x, y, w, h))
				x += w
			else:
				x += 1
	return out


func _build_slopes() -> void:
	# Each diagonal run of slope cells becomes one long triangle so there are
	# no seams along the ramp.
	var done := {}
	for y in data.height:
		for x in data.width:
			var c := data.cell(x, y)
			if (c != LevelData.SLOPE_R and c != LevelData.SLOPE_L) or done.has(Vector2i(x, y)):
				continue
			var dir := 1 if c == LevelData.SLOPE_R else -1
			# walk down to the lowest cell of this run
			var bx := x
			var by := y
			while data.cell(bx - dir, by + 1) == c:
				bx -= dir
				by += 1
			# then count upward
			var n := 0
			var solid_under := true
			while data.cell(bx + dir * n, by - n) == c:
				done[Vector2i(bx + dir * n, by - n)] = true
				for k in range(1, n + 1):
					if not data.is_block(bx + dir * n, by - n + k):
						solid_under = false
				n += 1
			if solid_under:
				_add_slope(bx, by, n, dir)
			else:
				for i in n:
					_add_slope(bx + dir * i, by - i, 1, dir)


func _add_slope(x: int, y: int, n: int, dir: int) -> void:
	var pts := PackedVector2Array()
	if dir > 0:
		pts.append(Vector2(x * TILE, (y + 1) * TILE))
		pts.append(Vector2((x + n) * TILE, (y + 1 - n) * TILE))
		pts.append(Vector2((x + n) * TILE, (y + 1) * TILE))
	else:
		pts.append(Vector2((x + 1) * TILE, (y + 1) * TILE))
		pts.append(Vector2((x + 1 - n) * TILE, (y + 1) * TILE))
		pts.append(Vector2((x + 1 - n) * TILE, (y + 1 - n) * TILE))
	var shape := ConvexPolygonShape2D.new()
	shape.points = pts
	var cs := CollisionShape2D.new()
	cs.shape = shape
	solid_body.add_child(cs)


# -------------------------------------------------------------------- water --

func _build_water() -> void:
	for rect in merged_rects(func(c: int) -> bool: return c == LevelData.WATER):
		var px := Rect2(Vector2(rect.position) * TILE, Vector2(rect.size) * TILE)
		# the surface sits a little below the top of the cell
		px.position.y += 14.0
		px.size.y -= 14.0
		water_rects.append(px)
		var pool := WaterPool.new()
		pool.setup(px, theme)
		add_child(pool)
		water_areas.append(pool)


func water_at(point: Vector2) -> bool:
	for r in water_rects:
		if r.has_point(point):
			return true
	return false


# -------------------------------------------------------------------- tiles --

func _build_tiles() -> void:
	var path := "res://assets/tiles/tiles_%s.svg" % theme
	if not ResourceLoader.exists(path):
		path = "res://assets/tiles/tiles_picnic.svg"
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var ts := TileSet.new()
	ts.tile_size = Vector2i(SUB, SUB)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(SUB, SUB)
	for ay in ATLAS_ROWS:
		for ax in ATLAS_COLS:
			src.create_tile(Vector2i(ax, ay))
	ts.add_source(src, 0)
	tiles = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = ts
	tiles.scale = Vector2(float(TILE) / (SUB * 2.0), float(TILE) / (SUB * 2.0))
	tiles.collision_enabled = false
	tiles.navigation_enabled = false
	tiles.z_index = 0
	add_child(tiles)

	for y in data.height:
		var x := 0
		while x < data.width:
			var c := data.cell(x, y)
			match c:
				LevelData.SOLID, LevelData.STRUCT, LevelData.ICE:
					_place_block(x, y, c)
				LevelData.SLOPE_R, LevelData.SLOPE_L:
					_place_slope(x, y, c)
				LevelData.ONEWAY:
					var start := x
					while x + 1 < data.width and data.cell(x + 1, y) == LevelData.ONEWAY:
						x += 1
					_place_plank(start, x, y)
			x += 1


func _material_of(x: int, y: int) -> int:
	var c := data.cell(x, y)
	if MATERIAL_BASE.has(c):
		return c
	# slopes borrow the material of the ground under / beside them
	for off: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, 1), Vector2i(-1, 1)]:
		var n := data.cell(x + off.x, y + off.y)
		if MATERIAL_BASE.has(n):
			return n
	return LevelData.SOLID


## Does the neighbour at (nx, ny) cover the side it shares with the cell in
## direction (dx, dy) from it? (Slopes only fill some of their sides.)
func _joins(nx: int, ny: int, dx: int, dy: int) -> bool:
	if nx < 0 or nx >= data.width:
		return true   # ground continues off the sides of the map
	if ny >= data.height:
		return true   # and below it
	var c := data.cell(nx, ny)
	if c == LevelData.SOLID or c == LevelData.STRUCT or c == LevelData.ICE:
		return true
	if c == LevelData.SLOPE_R:
		# full right side and bottom; full corner bottom-right
		if dx == -1 and dy == 0:
			return true      # neighbour is to our left: we touch its right side
		if dx == 0 and dy == -1:
			return true      # neighbour is above: we touch its bottom
		if dx == -1 and dy == -1:
			return true
		return false
	if c == LevelData.SLOPE_L:
		if dx == 1 and dy == 0:
			return true
		if dx == 0 and dy == -1:
			return true
		if dx == 1 and dy == -1:
			return true
		return false
	return false


func _place_block(x: int, y: int, material: int) -> void:
	var base: int = MATERIAL_BASE[material]
	for q in 4:
		var qx := q % 2
		var qy := q / 2
		var dx := -1 if qx == 0 else 1
		var dy := -1 if qy == 0 else 1
		var h := _joins(x + dx, y, dx, 0)
		var v := _joins(x, y + dy, 0, dy)
		var d := _joins(x + dx, y + dy, dx, dy)
		var atlas: Vector2i
		if not h and not v:
			atlas = Vector2i(q, base + 0)
		elif h and not v:
			atlas = Vector2i(q, base + 1)
		elif not h and v:
			atlas = Vector2i(q, base + 2)
		elif not d:
			atlas = Vector2i(q, base + 3)
		else:
			var variant := q
			if material == LevelData.SOLID:
				variant = absi((x * 7 + y * 13 + q * 5 + x * y) % 4)
			atlas = Vector2i(variant, base + 4)
		tiles.set_cell(Vector2i(x * 2 + qx, y * 2 + qy), 0, atlas)


func _place_slope(x: int, y: int, c: int) -> void:
	var base: int = MATERIAL_BASE[_material_of(x, y)]
	var ax := 4 if c == LevelData.SLOPE_R else 6
	for q in 4:
		var qx := q % 2
		var qy := q / 2
		tiles.set_cell(Vector2i(x * 2 + qx, y * 2 + qy), 0, Vector2i(ax + qx, base + qy))


func _place_plank(x0: int, x1: int, y: int) -> void:
	var first := x0 * 2
	var last := x1 * 2 + 1
	for sx in range(first, last + 1):
		var part := 1
		if sx == first:
			part = 0
		elif sx == last:
			part = 2
		tiles.set_cell(Vector2i(sx, y * 2), 0, Vector2i(4 + part, 2))
