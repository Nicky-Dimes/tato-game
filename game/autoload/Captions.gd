extends CanvasLayer
## On-screen captions for sounds that matter to puzzles ("♪ chime rings",
## "the gate rumbles open"), so no puzzle depends on hearing alone.

const MAX_LINES := 3
const HOLD := 2.4

var _box: VBoxContainer
var _lines: Array[Dictionary] = []   # {label, ttl}


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_top = -210.0
	_box.offset_bottom = -150.0
	_box.offset_left = 0.0
	_box.offset_right = 0.0
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)


func caption(text: String) -> void:
	if not Settings.flag("captions") or text == "":
		return
	# refresh instead of repeating an identical line
	for line in _lines:
		if (line["label"] as Label).text == text:
			line["ttl"] = HOLD
			return
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0.19, 0.08, 0.27))
	label.add_theme_constant_override("outline_size", 8)
	if UITheme.font_bold():
		label.add_theme_font_override("font", UITheme.font_bold())
	_box.add_child(label)
	_lines.append({"label": label, "ttl": HOLD})
	while _lines.size() > MAX_LINES:
		var old: Dictionary = _lines.pop_front()
		(old["label"] as Label).queue_free()


func clear() -> void:
	for line in _lines:
		(line["label"] as Label).queue_free()
	_lines.clear()


func _process(delta: float) -> void:
	var i := 0
	while i < _lines.size():
		var line: Dictionary = _lines[i]
		line["ttl"] = float(line["ttl"]) - delta
		var label: Label = line["label"]
		label.modulate.a = clampf(float(line["ttl"]) / 0.4, 0.0, 1.0)
		if float(line["ttl"]) <= 0.0:
			label.queue_free()
			_lines.remove_at(i)
		else:
			i += 1
