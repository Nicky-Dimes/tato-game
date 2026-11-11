class_name ProductionArt
extends RefCounted
## Original runtime atlases; no screenshot crops or generated scene mockups.
const THEMES := ["grassland", "orchard", "candy", "icy", "windy", "castle"]
static var _cache: Dictionary = {}

static func index_for(theme_name: String) -> int:
	return maxi(0, THEMES.find(theme_name))

static func landscape(theme_name: String, plane: String) -> Texture2D:
	var key := theme_name + plane
	if _cache.has(key):
		return _cache[key]
	if plane == "far":
		var name := theme_name if theme_name in THEMES else "grassland"
		var far := load("res://assets/production/%s_far.png" % name) as Texture2D
		_cache[key] = far
		return far
	var atlas := load("res://assets/production/worlds_%s.png" % plane) as Texture2D
	var cell := Vector2(atlas.get_width() / 3.0, atlas.get_height() / 2.0)
	var index := index_for(theme_name)
	var tile := AtlasTexture.new()
	tile.atlas = atlas
	tile.region = Rect2(Vector2(index % 3, index / 3) * cell, cell)
	tile.filter_clip = true
	_cache[key] = tile
	return tile

static func region_for(theme_name: String) -> Vector4:
	var index := index_for(theme_name)
	return Vector4((index % 3) / 3.0, (index / 3) / 2.0, 1.0 / 3.0, 0.5)


const ENEMY_PACKS := {
	"garden": ["slime_blob", "fire_slime", "ice_slime", "shock_slime", "mushroom_hopper", "apple_chomper", "hedgehog_roller"],
	"guardians": ["turtle_tank", "crab_snipper", "onion_knight", "rock_golem", "carrot_archer", "pepper_goblin", "ice_puffin"],
	"flyers": ["candy_imp", "mole_digger", "bee_buzzer", "crow_swooper", "ghost_poof", "pie_bat", "balloon_jelly"],
}

static func enemy_frame(kind: String, frame: int) -> Texture2D:
	var key := kind + str(frame)
	if _cache.has(key):
		return _cache[key]
	for pack: String in ENEMY_PACKS:
		var row: int = ENEMY_PACKS[pack].find(kind)
		if row < 0:
			continue
		var filename := "enemies_%s%s.png" % [pack, "_extra" if frame >= 4 else ""]
		var atlas := load("res://assets/production/" + filename) as Texture2D
		var cell := Vector2(atlas.get_width() / 4.0, atlas.get_height() / 7.0)
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(Vector2(frame % 4, row) * cell, cell)
		texture.filter_clip = true
		apply_metrics(texture, filename, row, frame % 4)
		_cache[key] = texture
		return texture
	return null


const BOSS_IDS := ["mega_mushroot", "gigantapple", "candy_king", "frost_puffin_lord", "sky_airship_turtle", "chef_castle_golem"]
static var _metrics: Dictionary = {}

static func apply_metrics(texture: Texture2D, filename: String, row: int, frame: int = 0) -> void:
	if _metrics.is_empty():
		_metrics = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/animation_layout.json"))
	var metric: Dictionary = _metrics[filename]["frames"][row][frame]
	var rect: Array = metric["region"]
	(texture as AtlasTexture).region = Rect2(rect[0], rect[1], rect[2], rect[3])
	var anchor: Array = metric["anchor"]
	texture.set_meta("anchor", Vector2(anchor[0], anchor[1]))
	texture.set_meta("body_height", float(metric["body_height"]))
	texture.set_meta("ink_height", float(metric["ink_height"]))
	var width := int(rect[2])
	var height := int(rect[3])
	var mask_bytes := Marshalls.base64_to_raw(metric["mask_gzip"]).decompress(width * height, FileAccess.COMPRESSION_GZIP)
	var image := Image.create_from_data(width, height, false, Image.FORMAT_L8, mask_bytes)
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/production/silhouette.gdshader")
	material.set_shader_parameter("silhouette_mask", ImageTexture.create_from_image(image))
	var atlas := (texture as AtlasTexture).atlas
	material.set_shader_parameter("atlas_region", Vector4(float(rect[0]) / atlas.get_width(), float(rect[1]) / atlas.get_height(), float(width) / atlas.get_width(), float(height) / atlas.get_height()))
	texture.set_meta("silhouette_material", material)

static func boss_frame(kind: String, frame: int) -> Texture2D:
	var key := "boss_" + kind + str(frame)
	if _cache.has(key):
		return _cache[key]
	var row := BOSS_IDS.find(kind)
	if row < 0:
		return null
	var filename := "bosses%s.png" % ("_extra" if frame >= 4 else "")
	var rows := 6
	if kind == "chef_castle_golem":
		filename = "chef_castle_corrected.png"
		rows = 2
		row = frame / 4
	var atlas := load("res://assets/production/" + filename) as Texture2D
	var cell := Vector2(atlas.get_width() / 4.0, atlas.get_height() / float(rows))
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(frame % 4, row) * cell, cell)
	texture.filter_clip = true
	apply_metrics(texture, filename, row, frame % 4)
	_cache[key] = texture
	return texture
