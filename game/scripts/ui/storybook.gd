extends Control
## Picture-book pages for the opening, the page found after each boss, and
## the ending. Pages come from data/text/stories.json: a picture cut from
## the boards plus one or two sentences. Any button or a tap turns the page;
## Skip jumps to the end.

var _pages: Array = []
var _index := 0
var _pic: TextureRect
var _text: Label
var _hint: Label
var _then: Dictionary = {}
var _done := false


func _ready() -> void:
	theme = UITheme.theme()
	var id := str(Game.scene_args.get("story", "intro"))
	_then = Game.scene_args.get("then", {})
	_pages = Story.story_pages(id)
	AudioService.music("story" if id != "ending" else "ending")
	var bg := ColorRect.new()
	bg.color = Color("fdf2e0")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_pic = TextureRect.new()
	_pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pic.offset_left = 80.0
	_pic.offset_right = -80.0
	_pic.offset_top = 30.0
	_pic.offset_bottom = -210.0
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_pic)
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 110.0
	panel.offset_right = -110.0
	panel.offset_top = -196.0
	panel.offset_bottom = -30.0
	add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	_text = UITheme.label("", 28, UITheme.PLUM, true)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_text)
	_hint = UITheme.label("", 18, UITheme.PLUM_SOFT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)
	var skip := UITheme.small_button("Skip")
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -150.0
	skip.offset_right = -20.0
	skip.offset_top = 16.0
	skip.offset_bottom = 68.0
	skip.pressed.connect(_finish)
	add_child(skip)
	if _pages.is_empty():
		_finish.call_deferred()
	else:
		_show()


func _show() -> void:
	var page: Dictionary = _pages[_index]
	_pic.texture = Art.tex(str(page.get("art", "")))
	_text.text = str(page.get("text", ""))
	_hint.text = "%d / %d      tap or press a button" % [_index + 1, _pages.size()]
	Captions.clear()
	_pic.modulate.a = 0.0
	create_tween().tween_property(_pic, "modulate:a", 1.0, 0.35)
	if page.has("honk"):
		AudioService.voice(str(page["honk"]))


func _next() -> void:
	AudioService.ui("ui_move")
	_index += 1
	if _index >= _pages.size():
		_finish()
	else:
		_show()


func _finish() -> void:
	if _done:
		return
	_done = true
	if _then.has("level"):
		Game.start_level(str(_then["level"]))
	elif _then.has("scene"):
		Game.goto(str(_then["scene"]))
	elif _then.has("hub"):
		Game.goto_hub()
	else:
		Game.goto_title()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_next()


func _unhandled_input(event: InputEvent) -> void:
	for action: String in ["jump", "attack", "ui_accept"]:
		if event.is_action_pressed(action):
			_next()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_finish()
