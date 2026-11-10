class_name HUD
extends CanvasLayer
## In-stage display: Comfort Feathers, the two Flavor Pockets, Honk Charge,
## the fusion hint, finds, prompts, tips, captions-style messages and the
## recipe discovery card. It only listens to signals; it never drives play.

var level: Level
var root: Control
var _feathers: Array[TextureRect] = []
var _pockets: Array[PocketWidget] = []
var _beak: PocketWidget
var _charge: ChargeMeter
var _fusion: Label
var _scraps: Label
var _timer_label: Label
var _prompt: PanelContainer
var _prompt_label: Label
var _tip: PanelContainer
var _tip_label: Label
var _tip_owner: Object = null
var _banner: VBoxContainer
var _message: Label
var _card: PanelContainer
var _toast_box: VBoxContainer
var _hint_step := 0
var _hint_lines: Array = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(lv: Level) -> void:
	level = lv
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.theme()
	add_child(root)

	# --- top-left cluster
	var left := VBoxContainer.new()
	left.position = Vector2(24, 18)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_theme_constant_override("separation", 6)
	root.add_child(left)

	var feather_row := HBoxContainer.new()
	feather_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feather_row.add_theme_constant_override("separation", 2)
	left.add_child(feather_row)
	for i in GameState.MAX_FEATHERS:
		var f := TextureRect.new()
		f.texture = Art.tex("items/feather")
		f.custom_minimum_size = Vector2(40, 40)
		f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		feather_row.add_child(f)
		_feathers.append(f)

	var pocket_row := HBoxContainer.new()
	pocket_row.add_theme_constant_override("separation", 8)
	pocket_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(pocket_row)
	for i in 2:
		var pw := PocketWidget.new()
		pw.letter = "A" if i == 0 else "B"
		pw.slot = i
		pw.tapped.connect(_on_pocket_tapped)
		pocket_row.add_child(pw)
		_pockets.append(pw)
	_beak = PocketWidget.new()
	_beak.letter = ""
	_beak.slot = FoodInventory.NONE
	_beak.small = true
	_beak.icon = Art.tex("ui/honk")
	_beak.tapped.connect(_on_pocket_tapped)
	pocket_row.add_child(_beak)
	_charge = ChargeMeter.new()
	pocket_row.add_child(_charge)

	_fusion = UITheme.outlined_label("", 20)
	_fusion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_fusion)

	# --- top-right cluster
	var right := HBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -330.0
	right.offset_right = -96.0
	right.offset_top = 22.0
	right.alignment = BoxContainer.ALIGNMENT_END
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)
	_timer_label = UITheme.outlined_label("", 24)
	_timer_label.visible = false
	right.add_child(_timer_label)
	var scrap_icon := TextureRect.new()
	scrap_icon.texture = Art.tex("items/scrap")
	scrap_icon.custom_minimum_size = Vector2(36, 36)
	scrap_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrap_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scrap_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(scrap_icon)
	_scraps = UITheme.outlined_label("0/0", 24)
	right.add_child(_scraps)
	if level.scraps_total == 0:
		scrap_icon.visible = false
		_scraps.visible = false

	# --- interact prompt (bottom centre)
	_prompt = PanelContainer.new()
	_prompt.add_theme_stylebox_override("panel", UITheme.box(UITheme.CREAM, UITheme.PLUM, 22, 4))
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.offset_top = -128.0
	_prompt.offset_bottom = -76.0
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	_prompt_label = UITheme.label("", 24, UITheme.PLUM, true)
	_prompt.add_child(_prompt_label)
	root.add_child(_prompt)

	# --- tip from signposts (top centre)
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", UITheme.box(UITheme.CREAM, UITheme.PLUM, 22, 4))
	_tip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_tip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tip.offset_top = 96.0
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	_tip_label = UITheme.label("", 24, UITheme.PLUM, true)
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size = Vector2(520, 0)
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.add_child(_tip_label)
	root.add_child(_tip)

	# --- stage banner
	_banner = VBoxContainer.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 120.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_message = UITheme.title_label("", 54)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.grow_vertical = Control.GROW_DIRECTION_BOTH
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message.visible = false
	root.add_child(_message)

	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_toast_box.offset_left = -380.0
	_toast_box.offset_right = -20.0
	_toast_box.offset_top = 80.0
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_box)

	var inv := level.player.inventory
	inv.slot_changed.connect(func(_s: int, _f: StringName) -> void: _refresh_pockets())
	inv.active_changed.connect(func(_a: int) -> void: _refresh_pockets())
	GameState.feathers_changed.connect(_on_feathers)
	GameState.charge_changed.connect(func(v: float) -> void: _charge.set_value(v / GameState.MAX_CHARGE))
	GameState.toast.connect(show_toast)
	level.player.interact_target_changed.connect(_on_target)
	level.player.runner.ability_denied.connect(func(_d: Resource, reason: String) -> void:
		if reason == "charge":
			_charge.flash())
	Controls.device_changed.connect(func(_d: String) -> void: _refresh_pockets(); _on_target(level.player.interact_target))
	_refresh_pockets()
	_on_feathers(GameState.feathers)
	_charge.set_value(GameState.honk_charge / GameState.MAX_CHARGE)
	_update_scraps()


func _process(_delta: float) -> void:
	if level == null or level.player == null:
		return
	var runner := level.player.runner
	for pw in _pockets:
		pw.timer_fraction = 0.0
	if runner.current != null:
		var id := runner.active_id()
		for pw in _pockets:
			if level.player.inventory.food_in(pw.slot) == id:
				pw.timer_fraction = runner.time_fraction()
				pw.queue_redraw()
	if _timer_label.visible:
		_timer_label.text = format_time(level.elapsed)


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func show_timer(value: bool) -> void:
	_timer_label.visible = value


func _refresh_pockets() -> void:
	var inv := level.player.inventory
	for pw in _pockets:
		var food := inv.food_in(pw.slot)
		pw.icon = FoodDB.food_icon(food) if food != &"" else null
		pw.tint = FoodDB.food(food).color if food != &"" else UITheme.CREAM_DARK
		pw.active = inv.active == pw.slot
		pw.queue_redraw()
	_beak.active = inv.active == FoodInventory.NONE
	_beak.queue_redraw()
	var rec := inv.current_recipe()
	if rec == null:
		_fusion.text = ""
	else:
		var known := GameState.knows_recipe(rec)
		_fusion.text = "%s  Fuse: %s" % [Controls.prompt("fusion"), rec.display_name if known else "? ? ?"]


func _on_pocket_tapped(_slot: int) -> void:
	# tapping a pocket is the touch way to swap
	Input.action_press("ability_swap")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("ability_swap")


func _on_feathers(value: int) -> void:
	for i in _feathers.size():
		_feathers[i].modulate = Color.WHITE if i < value else Color(0.25, 0.15, 0.35, 0.45)
	if Settings.feathers_protected():
		for f in _feathers:
			f.modulate = Color(1.0, 0.95, 0.7)


func _update_scraps() -> void:
	_scraps.text = "%d/%d" % [level.scraps_found, level.scraps_total]


func on_collect(_kind: String, _fresh: bool) -> void:
	_update_scraps()


func _on_target(target: Node) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("prompt"):
		_prompt.visible = false
		return
	_prompt_label.text = "%s   %s" % [Controls.prompt("eat_interact"), str(target.call("prompt"))]
	_prompt.visible = true
	_prompt.reset_size()


func show_tip(owner_obj: Object, text: String) -> void:
	_tip_owner = owner_obj
	_tip_label.text = Controls.fill(text)
	_tip.visible = true
	_tip.reset_size()


func hide_tip(owner_obj: Object) -> void:
	if _tip_owner == owner_obj:
		_tip.visible = false
		_tip_owner = null


func show_banner(title: String, subtitle: String) -> void:
	for c in _banner.get_children():
		c.queue_free()
	if subtitle != "":
		var sub := UITheme.outlined_label(subtitle, 26)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner.add_child(sub)
	_banner.add_child(UITheme.title_label(title, 50))
	var t := create_tween()
	t.tween_property(_banner, "modulate:a", 1.0, 0.4)
	t.tween_interval(2.2)
	t.tween_property(_banner, "modulate:a", 0.0, 0.6)


func show_message(text: String, seconds: float = 1.4) -> void:
	_message.text = text
	_message.visible = true
	_message.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_property(_message, "modulate:a", 0.0, 0.4)
	t.tween_callback(func() -> void: _message.visible = false)


func show_toast(text: String, icon: Texture2D = null) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.box(UITheme.CREAM, UITheme.PLUM, 18, 4))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	if icon != null:
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(40, 40)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(tr)
	var l := UITheme.label(text, 22, UITheme.PLUM, true)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(250, 0)
	row.add_child(l)
	_toast_box.add_child(panel)
	var t := panel.create_tween()
	t.tween_interval(3.0)
	t.tween_property(panel, "modulate:a", 0.0, 0.5)
	t.tween_callback(panel.queue_free)


## The "delight" card when a recipe is used for the first time. About two
## seconds; any button skips it.
func show_recipe(rec: RecipeDefinition) -> void:
	if _card != null and is_instance_valid(_card):
		_card.queue_free()
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UITheme.box(UITheme.CREAM, UITheme.PLUM, 28, 6))
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.offset_top = 150.0
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(box)
	var head := UITheme.label("New recipe!" if rec.named else "Kitchen experiment!", 22, UITheme.PLUM_SOFT, true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(icons)
	for fid: StringName in [rec.food_a, rec.food_b]:
		var tr := TextureRect.new()
		tr.texture = FoodDB.food_icon(fid)
		tr.custom_minimum_size = Vector2(56, 56)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icons.add_child(tr)
		if fid == rec.food_a:
			icons.add_child(UITheme.label("+", 34, UITheme.PLUM, true))
	box.add_child(UITheme.title_label(rec.display_name, 42, rec.color.lightened(0.2)))
	var desc := UITheme.label(rec.description, 22)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(460, 0)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(desc)
	root.add_child(_card)
	AudioService.play("recipe")
	AudioService.duck_music(1.6)
	Captions.caption("♪ A happy jingle: new recipe")
	_card.pivot_offset = Vector2(250, 80)
	_card.scale = Vector2(0.6, 0.6)
	var card := _card
	var t := card.create_tween()
	t.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.0)
	t.tween_property(card, "modulate:a", 0.0, 0.3)
	t.tween_callback(card.queue_free)
	_refresh_pockets()


func show_hint(lines: Array) -> void:
	if lines != _hint_lines:
		_hint_lines = lines
		_hint_step = 0
	var text := str(_hint_lines[mini(_hint_step, _hint_lines.size() - 1)])
	_hint_step = mini(_hint_step + 1, _hint_lines.size() - 1)
	GameState.profile["hints_used"] = int(GameState.profile.get("hints_used", 0)) + 1
	show_tip(self, "Hint Nest: " + text)
	var t := create_tween()
	t.tween_interval(6.0)
	t.tween_callback(func() -> void: hide_tip(self))


## One Flavor Pocket.
class PocketWidget:
	extends Control

	signal tapped(slot: int)

	var letter := "A"
	var slot := 0
	var icon: Texture2D
	var tint := Color("f3e6d2")
	var active := false
	var small := false
	var timer_fraction := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _ready() -> void:
		custom_minimum_size = Vector2(52, 52) if small else Vector2(70, 70)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit(slot)
			accept_event()

	func _draw() -> void:
		var r := size.x * 0.5
		var c := size * 0.5
		if active:
			draw_circle(c, r, Color("ffcf3f"))
		draw_circle(c, r - 4.0, Color("301444"))
		draw_circle(c, r - 8.0, tint.lerp(Color("fff9ef"), 0.62) if icon != null and not small else Color("fff9ef"))
		if icon != null:
			var s := (r - 12.0) * 2.0
			draw_texture_rect(icon, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
		if timer_fraction > 0.0:
			draw_arc(c, r - 6.0, -PI * 0.5, -PI * 0.5 + TAU * timer_fraction, 32, Color("ffffff"), 5.0, true)
		if letter != "":
			var font := UITheme.font_bold()
			if font:
				draw_string_outline(font, Vector2(2, 18), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Color("301444"))
				draw_string(font, Vector2(2, 18), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)


## Honk Charge: an arc that fills.
class ChargeMeter:
	extends Control

	var value := 1.0
	var _flash := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(70, 70)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_value(v: float) -> void:
		value = clampf(v, 0.0, 1.0)
		queue_redraw()

	func flash() -> void:
		_flash = 0.5
		set_process(true)

	func _process(delta: float) -> void:
		if _flash > 0.0:
			_flash -= delta
			queue_redraw()
		else:
			set_process(false)

	func _draw() -> void:
		var c := size * 0.5
		var r := size.x * 0.5 - 8.0
		var start := PI * 0.75
		var sweep := PI * 1.5
		draw_arc(c, r, start, start + sweep, 32, Color("301444"), 14.0, true)
		draw_arc(c, r, start, start + sweep, 32, Color("5b3a78"), 8.0, true)
		var col := Color("ffcf3f") if value > 0.3 else Color("ff9a1f")
		if _flash > 0.0 and fmod(_flash, 0.16) > 0.08:
			col = Color("f0452e")
		if value > 0.01:
			draw_arc(c, r, start, start + sweep * value, 32, col, 8.0, true)
		var icon := Art.tex("ui/honk")
		if icon != null:
			draw_texture_rect(icon, Rect2(c - Vector2(17, 17), Vector2(34, 34)), false)
