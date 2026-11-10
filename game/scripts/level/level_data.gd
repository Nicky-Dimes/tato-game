class_name LevelData
extends RefCounted
## A stage read from a text file in data/levels/. The file has three parts:
##
##   [meta]      key = value lines (id, world, name, kind, theme, music ...)
##   [legend]    one line per custom map letter:  K = chime id=k1 opens=g1
##   [map]       the picture of the stage, one character per 64 px cell
##
## Letters with a built-in meaning are listed in DEFAULT_LEGEND below, so most
## stages only need a legend for things that carry settings (which food a bowl
## holds, which gate a chime opens...).

const AIR := 0
const SOLID := 1        # '#'  natural ground
const STRUCT := 2       # '%'  built blocks (wood, brick, brass)
const ONEWAY := 3       # '='  thin platform you can jump up through
const SLOPE_R := 4      # '/'  rises to the right
const SLOPE_L := 5      # '\'  rises to the left
const WATER := 6        # '~'
const ICE := 7          # 'i'  slippery solid ice (natural, does not melt)

const TERRAIN_CHARS := {
	"#": SOLID, "%": STRUCT, "=": ONEWAY, "/": SLOPE_R, "\\": SLOPE_L, "~": WATER, "i": ICE,
}

## letter -> "type arg key=value ..."
const DEFAULT_LEGEND := {
	"@": "spawn",
	"E": "goal",
	"C": "checkpoint",
	"o": "coin",
	"h": "heart",
	"H": "extraheal",
	"*": "star",
	"n": "note",
	"k": "key",
	"L": "lock",
	"?": "qblock",
	"B": "crate",
	"S": "spring",
	"^": "spikes",
	"v": "spikes flip",
}

var id := ""
var meta: Dictionary = {}
var legend: Dictionary = {}          # char -> {type, args, params}
var rows: PackedStringArray = PackedStringArray()
var width := 0
var height := 0
var cells: PackedByteArray = PackedByteArray()
var entities: Array[Dictionary] = []  # {type, char, cell, args, params}
var errors: PackedStringArray = PackedStringArray()


static func parse(text: String, fallback_id: String = "") -> LevelData:
	var d := LevelData.new()
	d.id = fallback_id
	for ch: String in DEFAULT_LEGEND.keys():
		d.legend[ch] = _parse_legend_value(DEFAULT_LEGEND[ch])
	var section := ""
	var map_lines: Array[String] = []
	for raw: String in text.split("\n"):
		var line := raw.rstrip("\r")
		var trimmed := line.strip_edges()
		if section != "map":
			if trimmed == "" or trimmed.begins_with(";"):
				continue
		if trimmed == "[meta]" or trimmed == "[legend]" or trimmed == "[map]":
			section = trimmed.substr(1, trimmed.length() - 2)
			continue
		match section:
			"meta":
				var eq := trimmed.find("=")
				if eq > 0:
					d.meta[trimmed.substr(0, eq).strip_edges()] = _value(trimmed.substr(eq + 1).strip_edges())
			"legend":
				# the letter is the first character; the rest follows " = "
				var eq2 := line.find("=", 1)
				if eq2 > 0:
					var ch2 := line.substr(0, eq2).strip_edges()
					if ch2.length() == 1:
						d.legend[ch2] = _parse_legend_value(line.substr(eq2 + 1).strip_edges())
					else:
						d.errors.append("legend letter must be one character: '%s'" % ch2)
			"map":
				map_lines.append(line)
	# drop blank lines after the picture
	while map_lines.size() > 0 and map_lines[map_lines.size() - 1].strip_edges() == "":
		map_lines.pop_back()
	if d.meta.has("id"):
		d.id = str(d.meta["id"])
	d.height = map_lines.size()
	for l in map_lines:
		d.width = maxi(d.width, l.length())
	d.cells.resize(d.width * d.height)
	d.cells.fill(AIR)
	for y in d.height:
		var l2 := map_lines[y]
		d.rows.append(l2)
		for x in l2.length():
			var ch3 := l2[x]
			if ch3 == " " or ch3 == ".":
				continue
			if TERRAIN_CHARS.has(ch3):
				d.cells[y * d.width + x] = TERRAIN_CHARS[ch3]
				continue
			if d.legend.has(ch3):
				var entry: Dictionary = d.legend[ch3]
				d.entities.append({
					"type": entry["type"],
					"char": ch3,
					"cell": Vector2i(x, y),
					"args": entry["args"],
					"params": (entry["params"] as Dictionary).duplicate(),
				})
			else:
				d.errors.append("unknown map letter '%s' at %d,%d" % [ch3, x, y])
	return d


static func _parse_legend_value(text: String) -> Dictionary:
	var parts := text.split(" ", false)
	var out := {"type": "", "args": [], "params": {}}
	if parts.size() == 0:
		return out
	out["type"] = parts[0]
	for i in range(1, parts.size()):
		var part := parts[i]
		var eq := part.find("=")
		if eq > 0:
			out["params"][part.substr(0, eq)] = _value(part.substr(eq + 1))
		else:
			(out["args"] as Array).append(part)
			out["params"][part] = true
	return out


static func _value(text: String) -> Variant:
	if text.is_valid_int():
		return text.to_int()
	if text.is_valid_float():
		return text.to_float()
	if text == "true":
		return true
	if text == "false":
		return false
	return text.replace("_", " ") if text.begins_with("\"") else text


func cell(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= width or y >= height:
		return AIR
	return cells[y * width + x]


func cell_v(c: Vector2i) -> int:
	return cell(c.x, c.y)


## Solid for standing/blocking purposes (slopes count, one-way and water do not).
func is_block(x: int, y: int) -> bool:
	var c := cell(x, y)
	return c == SOLID or c == STRUCT or c == ICE or c == SLOPE_R or c == SLOPE_L


func is_full_block(x: int, y: int) -> bool:
	var c := cell(x, y)
	return c == SOLID or c == STRUCT or c == ICE


func pixel_size() -> Vector2:
	return Vector2(width, height) * float(Layers.TILE)


## Bottom-centre of a cell in pixels: where something standing in it rests.
static func cell_floor(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * Layers.TILE, (c.y + 1.0) * Layers.TILE)


static func cell_center(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * Layers.TILE, (c.y + 0.5) * Layers.TILE)


func entities_of(type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entities:
		if e["type"] == type:
			out.append(e)
	return out


func spawn_point() -> Vector2:
	var spawns := entities_of("spawn")
	if spawns.size() > 0:
		return cell_floor(spawns[0]["cell"])
	return Vector2(Layers.TILE * 2, Layers.TILE * 2)


func meta_str(key: String, default_value: String = "") -> String:
	return str(meta.get(key, default_value))


func meta_int(key: String, default_value: int = 0) -> int:
	return int(meta.get(key, default_value))
