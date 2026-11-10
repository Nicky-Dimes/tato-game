class_name HUD
extends CanvasLayer
## In-stage display, laid out like the HUD on the item board: hearts and the
## active power badge on the left; coins, Treasure Notes and keys on the
## right; boosts under the hearts; a boss bar when there is a boss. It only
## listens to signals; it never drives play.

const BOOSTS := [
	["wings_time", "pickups/wings", 10.0], ["magnet_time", "pickups/magnet", 12.0],
	["super_jump_time", "pickups/mushroom", 12.0], ["slow_fall_time", "pickups/feather", 12.0],
	["luck_time", "pickups/clover", 15.0], ["star_time", "pickups/rainbow_star", 8.0],
]

var level: Level
var root: Control
var _hearts: Array[TextureRect] = []
var _badge: PowerBadge
var _coins: Label
var _notes: Label
var _keys: Label
var _key_icon: TextureRect
var _boost_row: HBoxContainer
var _boost_icons: Dictionary = {}
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
var _boss_bar: ProgressBar
var _boss_name: Label
var _hint_step := 0
var _hint_lines: Array = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS


func _icon(short: String, size: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.tex(short)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func setup(lv: Level) -> void:
	level = lv
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.theme()
	add_child(root)

	# Production HUD plates: actual painted assets behind existing functional controls.
	var health_plate := TextureRect.new()
	health_plate.texture = Art.tex("ui/hud_left")
	health_plate.position = Vector2(8, 6)
	health_plate.size = Vector2(436, 102)
	health_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	health_plate.stretch_mode = TextureRect.STRETCH_SCALE
	health_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(health_plate)
	var counter_plate := TextureRect.new()
	counter_plate.texture = Art.tex("ui/hud_right")
	counter_plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	counter_plate.offset_left = -555.0
	counter_plate.offset_right = -101.0
	counter_plate.offset_top = 8.0
	counter_plate.offset_bottom = 104.0
	counter_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	counter_plate.stretch_mode = TextureRect.STRETCH_SCALE
	counter_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(counter_plate)

	# --- top-left: hearts + power badge, boosts underneath
	var left := VBoxContainer.new()
	left.position = Vector2(30, 27)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_theme_constant_override("separation", 4)
	root.add_child(left)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 4)
	left.add_child(top)
	for i in GameState.MAX_HEARTS:
		var h := _icon("items/heart", 44.0)
		top.add_child(h)
		_hearts.append(h)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(8, 0)
	top.add_child(gap)
	_badge = PowerBadge.new()
	top.add_child(_badge)
	_boost_row = HBoxContainer.new()
	_boost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boost_row.add_theme_constant_override("separation", 6)
	left.add_child(_boost_row)
	for b: Array in BOOSTS:
		var bi := BoostIcon.new()
		bi.texture = Art.tex(b[1])
		bi.visible = false
		_boost_row.add_child(bi)
		_boost_icons[b[0]] = bi
	var orb := BoostIcon.new()
	orb.texture = Art.tex("pickups/orb")
	orb.visible = false
	_boost_row.add_child(orb)
	_boost_icons["orb_guard"] = orb
	var slow := BoostIcon.new()
	slow.texture = Art.tex("pickups/time")
	slow.visible = false
	_boost_row.add_child(slow)
	_boost_icons["slow"] = slow

	# --- top-right: coins, notes, keys (leaves room for the pause button)
	var right := HBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -470.0
	right.offset_right = -100.0
	right.offset_top = 29.0
	right.alignment = BoxContainer.ALIGNMENT_END
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_theme_constant_override("separation", 8)
	root.add_child(right)
	_timer_label = UITheme.outlined_label("", 26)
	_timer_label.visible = Settings.flag("show_timer") or level.kind == "optional"
	right.add_child(_timer_label)
	_key_icon = _icon("items/key", 38.0)
	right.add_child(_key_icon)
	_keys = UITheme.outlined_label("0", 28)
	right.add_child(_keys)
	right.add_child(_icon("items/treasure_note", 40.0))
	_notes = UITheme.outlined_label("0/3", 28)
	right.add_child(_notes)
	right.add_child(_icon("items/coin", 38.0))
	_coins = UITheme.outlined_label("0", 28)
	_coins.custom_minimum_size = Vector2(54, 0)
	right.add_child(_coins)

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
	_toast_box.offset_top = 84.0
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_box)

	# --- boss bar (hidden until a boss says hello)
	var boss_box := VBoxContainer.new()
	boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_box.offset_top = -74.0
	boss_box.offset_bottom = -18.0
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_box)
	_boss_name = UITheme.outlined_label("", 22)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size = Vector2(460, 22)
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.RED
	fill.set_corner_radius_all(10)
	fill.border_color = UITheme.PLUM
	fill.set_border_width_all(3)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	boss_box.add_child(_boss_bar)
	_boss_bar.visible = false
	_boss_name.visible = false

	GameState.hearts_changed.connect(_on_hearts)
	GameState.coins_changed.connect(func(_s: int, _w: int) -> void: refresh_counts())
	GameState.keys_changed.connect(func(_k: int) -> void: refresh_counts())
	GameState.toast.connect(show_toast)
	level.player.power_changed.connect(func(_p: StringName) -> void: _badge.set_power(level.player.power.power))
	level.player.interact_target_changed.connect(_on_target)
	Controls.device_changed.connect(func(_d: String) -> void: _on_target(level.player.interact_target))
	_badge.set_power(level.player.power.power)
	_on_hearts(GameState.hearts)
	refresh_counts()


func _process(_delta: float) -> void:
	if level == null or level.player == null:
		return
	var p := level.player
	for b: Array in BOOSTS:
		var left := float(p.get(b[0]))
		var icon: BoostIcon = _boost_icons[b[0]]
		icon.visible = left > 0.0
		if left > 0.0:
			icon.fraction = clampf(left / float(b[2]), 0.0, 1.0)
			icon.queue_redraw()
	(_boost_icons["orb_guard"] as BoostIcon).visible = p.orb_guard
	(_boost_icons["slow"] as BoostIcon).visible = level.enemy_time < 1.0
	_badge.cooldown = 0.0
	var def := p.power.definition()
	if def != null and p.runner.cooldowns.has(def.id):
		_badge.cooldown = clampf(float(p.runner.cooldowns[def.id]) / maxf(def.cooldown, 0.01), 0.0, 1.0)
	_badge.queue_redraw()
	if _timer_label.visible:
		_timer_label.text = format_time(level.elapsed)


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _on_hearts(value: int) -> void:
	for i in _hearts.size():
		_hearts[i].modulate = Color.WHITE if i < value else Color(0.2, 0.12, 0.3, 0.45)
	if Settings.hearts_protected():
		for h in _hearts:
			h.modulate = Color(1.0, 0.95, 0.75)


func refresh_counts() -> void:
	_coins.text = str(GameState.stage_coins)
	_notes.text = "%d/%d" % [level.notes_found, level.notes_total]
	_keys.text = str(GameState.keys)
	_keys.visible = GameState.keys > 0
	_key_icon.visible = GameState.keys > 0


func on_boost() -> void:
	pass


func _on_target(target: Node) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("prompt"):
		_prompt.visible = false
		return
	_prompt_label.text = "%s   %s" % [Controls.prompt("move_up" if Controls.device != Controls.DEVICE_TOUCH else "attack"), str(target.call("prompt"))]
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


## The friendly "oops" when hearts run out: the flopped-Tato drawing from
## the redesign board, then straight back to the checkpoint.
func show_defeat() -> void:
	var pic := TextureRect.new()
	pic.texture = Art.tex("tato_big/defeat")
	pic.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pic.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pic.grow_vertical = Control.GROW_DIRECTION_BOTH
	pic.custom_minimum_size = Vector2(220, 170)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.offset_top = -60.0
	root.add_child(pic)
	show_message("Oops! Back to the checkpoint", 1.0)
	var t := pic.create_tween()
	t.tween_interval(1.0)
	t.tween_property(pic, "modulate:a", 0.0, 0.3)
	t.tween_callback(pic.queue_free)


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


## The little card when a Flavor Burst is found for the first time.
func show_recipe(rec: RecipeDefinition) -> void:
	if _card != null and is_instance_valid(_card):
		_card.queue_free()
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UITheme.box(UITheme.CREAM, UITheme.PLUM, 24, 5))
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.offset_top = 140.0
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(box)
	var head := UITheme.label("New Flavor Burst!", 20, UITheme.PLUM_SOFT, true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(icons)
	for fid: StringName in [rec.food_a, rec.food_b]:
		var tr := TextureRect.new()
		tr.texture = FoodDB.food_icon(fid)
		tr.custom_minimum_size = Vector2(48, 48)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icons.add_child(tr)
		if fid == rec.food_a:
			icons.add_child(UITheme.label("+", 30, UITheme.PLUM, true))
	box.add_child(UITheme.title_label(rec.display_name, 36, rec.color.lightened(0.2)))
	root.add_child(_card)
	AudioService.play("recipe")
	var card := _card
	var t := card.create_tween()
	t.tween_interval(1.8)
	t.tween_property(card, "modulate:a", 0.0, 0.3)
	t.tween_callback(card.queue_free)


func show_hint(lines: Array) -> void:
	if lines != _hint_lines:
		_hint_lines = lines
		_hint_step = 0
	var text := str(_hint_lines[mini(_hint_step, _hint_lines.size() - 1)])
	_hint_step = (_hint_step + 1) % _hint_lines.size()
	GameState.profile["hints_used"] = int(GameState.profile.get("hints_used", 0)) + 1
	show_tip(self, "Hint: " + text)
	var t := create_tween()
	t.tween_interval(6.0)
	t.tween_callback(func() -> void: hide_tip(self))


func show_boss(boss_name: String) -> void:
	_boss_name.text = boss_name
	_boss_name.visible = true
	_boss_bar.visible = true
	_boss_bar.value = 1.0


func set_boss_health(fraction: float) -> void:
	_boss_bar.value = clampf(fraction, 0.0, 1.0)


func hide_boss() -> void:
	_boss_name.visible = false
	_boss_bar.visible = false


## The round yellow badge that shows the active power (as on the item board).
class PowerBadge:
	extends Control

	var icon: Texture2D
	var cooldown := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(62, 62)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_power(id: StringName) -> void:
		icon = FoodDB.food_icon(id) if id != &"" else Art.tex("ui/btn_jump")
		modulate = Color.WHITE
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := size.x * 0.5
		draw_circle(c, r, Color("301444"))
		draw_circle(c, r - 4.0, Color("ffcf3f"))
		draw_circle(c, r - 9.0, Color("fff3c4"))
		if icon != null:
			var s := (r - 9.0) * 1.7
			var k := s / float(maxi(icon.get_width(), icon.get_height()))
			var sz := Vector2(icon.get_width(), icon.get_height()) * k
			draw_texture_rect(icon, Rect2(c - sz * 0.5, sz), false)
		if cooldown > 0.0:
			draw_arc(c, r - 6.0, -PI * 0.5, -PI * 0.5 + TAU * cooldown, 24, Color(0.19, 0.08, 0.27, 0.7), 6.0, true)


## A boost icon with a ring that runs down.
class BoostIcon:
	extends Control

	var texture: Texture2D
	var fraction := 1.0

	func _ready() -> void:
		custom_minimum_size = Vector2(40, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 20.0, Color(0.19, 0.08, 0.27, 0.55))
		if texture != null:
			var k := 28.0 / float(maxi(texture.get_width(), texture.get_height()))
			var sz := Vector2(texture.get_width(), texture.get_height()) * k
			draw_texture_rect(texture, Rect2(c - sz * 0.5, sz), false)
		draw_arc(c, 19.0, -PI * 0.5, -PI * 0.5 + TAU * fraction, 24, Color("ffcf3f"), 3.0, true)
