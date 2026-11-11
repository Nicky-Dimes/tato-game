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
var _power_name: Label
var _power_hint: Label
var _readiness: ProgressBar
var _journey: ProgressBar
var _objective: Label
var _legend: Label
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

	# Container layout preserves readable spacing at every window aspect ratio.
	var header := HBoxContainer.new()
	header.name = "GameplayHeader"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 16
	header.offset_right = -16
	header.offset_top = 14
	header.offset_bottom = 100
	header.add_theme_constant_override("separation", 12)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)
	var health := _plate(header, 284)
	var health_row := HBoxContainer.new()
	health_row.add_theme_constant_override("separation", 10)
	health.add_child(health_row)
	var portrait := _icon("ui/tato_hud_portrait", 60)
	health_row.add_child(portrait)
	var health_info := VBoxContainer.new()
	health_info.alignment = BoxContainer.ALIGNMENT_CENTER
	health_row.add_child(health_info)
	health_info.add_child(UITheme.label("TATO!", 17, UITheme.CREAM, true))
	var hearts := HBoxContainer.new()
	hearts.add_theme_constant_override("separation", 2)
	health_info.add_child(hearts)
	for i in GameState.MAX_HEARTS:
		var heart := _icon("items/heart", 32)
		hearts.add_child(heart)
		_hearts.append(heart)
	var power := _plate(header, 272)
	var power_row := HBoxContainer.new()
	power_row.add_theme_constant_override("separation", 10)
	power.add_child(power_row)
	_badge = PowerBadge.new()
	_badge.name = "ActivePowerBadge"
	power_row.add_child(_badge)
	var power_info := VBoxContainer.new()
	power_info.alignment = BoxContainer.ALIGNMENT_CENTER
	power_info.add_theme_constant_override("separation", 2)
	power_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_row.add_child(power_info)
	_power_name = UITheme.label("Honk", 23, UITheme.CREAM, true)
	_power_name.name = "PowerName"
	power_info.add_child(_power_name)
	_readiness = ProgressBar.new()
	_readiness.name = "AttackReadiness"
	_readiness.custom_minimum_size = Vector2(150, 10)
	_readiness.max_value = 1.0
	_readiness.step = 0.001
	_readiness.show_percentage = false
	_readiness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readiness.add_theme_stylebox_override("background", UITheme.box(Color("211c39"), UITheme.PEACH, 5, 1, false))
	_readiness.add_theme_stylebox_override("fill", UITheme.box(UITheme.YELLOW, UITheme.ORANGE, 5, 0, false))
	for style_name in ["background", "fill"]:
		var style := _readiness.get_theme_stylebox(style_name).duplicate() as StyleBoxFlat
		style.set_content_margin_all(0)
		_readiness.add_theme_stylebox_override(style_name, style)
	power_info.add_child(_readiness)
	_power_hint = UITheme.label("", 15, UITheme.PEACH)
	power_info.add_child(_power_hint)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)
	var counts := _plate(header, 264)
	var right := HBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 8)
	counts.add_child(right)
	right.add_child(_icon("items/coin", 34))
	_coins = UITheme.label("0", 28, UITheme.CREAM, true)
	_coins.custom_minimum_size.x = 42
	right.add_child(_coins)
	right.add_child(_icon("items/treasure_note", 34))
	_notes = UITheme.label("0/3", 25, UITheme.CREAM, true)
	right.add_child(_notes)
	_key_icon = _icon("items/key", 26)
	right.add_child(_key_icon)
	_keys = UITheme.label("0", 22, UITheme.CREAM, true)
	right.add_child(_keys)
	var pause := UITheme.button("II", Vector2(74, 76))
	pause.name = "PauseButton"
	pause.tooltip_text = "Pause / " + Controls.prompt("pause")
	pause.pressed.connect(func() -> void:
		if not level.finished:
			level._pause_menu.open())
	header.add_child(pause)

	var stage := PanelContainer.new()
	stage.name = "StageProgress"
	stage.position = Vector2(18, 112)
	stage.custom_minimum_size = Vector2(300, 0)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_theme_stylebox_override("panel", UITheme.box(Color("fff1ce"), Color("a56938"), 16, 2))
	root.add_child(stage)
	var stage_info := VBoxContainer.new()
	stage_info.add_theme_constant_override("separation", 3)
	stage.add_child(stage_info)
	var stage_title := UITheme.label(level.level_id + "  ·  " + LevelDB.stage_name(level.level_id), 19, UITheme.PLUM, true)
	stage_info.add_child(stage_title)
	_objective = UITheme.label("", 14, UITheme.PLUM_SOFT)
	stage_info.add_child(_objective)
	_journey = ProgressBar.new()
	_journey.max_value = 1.0
	_journey.step = 0.001
	_journey.show_percentage = false
	_journey.custom_minimum_size = Vector2(0, 7)
	_journey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_info.add_child(_journey)

	var tools := HBoxContainer.new()
	tools.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tools.offset_left = -286
	tools.offset_right = -18
	tools.offset_top = 114
	tools.add_theme_constant_override("separation", 8)
	root.add_child(tools)
	for entry: Array in [["Notebook", "journal"], ["Map", "map"]]:
		var button := UITheme.small_button(entry[0])
		button.name = entry[0] + "Button"
		var section: String = entry[1]
		button.pressed.connect(func() -> void:
			if not level.finished:
				level._pause_menu.open(section))
		tools.add_child(button)
	_timer_label = UITheme.outlined_label("", 19)
	_timer_label.position = Vector2(24, 209)
	_timer_label.visible = Settings.flag("show_timer") or level.kind == "optional"
	root.add_child(_timer_label)
	_boost_row = HBoxContainer.new()
	_boost_row.position = Vector2(338, 112)
	_boost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boost_row)
	for b: Array in BOOSTS:
		var icon := BoostIcon.new()
		icon.texture = Art.tex(b[1])
		icon.visible = false
		_boost_row.add_child(icon)
		_boost_icons[b[0]] = icon
	for entry: Array in [["orb_guard", "pickups/orb"], ["slow", "pickups/time"]]:
		var icon := BoostIcon.new()
		icon.texture = Art.tex(entry[1])
		icon.visible = false
		_boost_row.add_child(icon)
		_boost_icons[entry[0]] = icon
	_legend = UITheme.outlined_label("", 17)
	_legend.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_legend.offset_left = 22
	_legend.offset_top = -36
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_legend)
	_update_controls()
	Controls.bindings_changed.connect(_update_controls)
	Controls.device_changed.connect(func(_device: String) -> void: _update_controls())

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
	_tip.offset_top = 204.0
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
	_banner.offset_top = 214.0
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
	_toast_box.offset_top = 184.0
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
	level.player.power_changed.connect(_on_power_changed)
	level.player.interact_target_changed.connect(_on_target)
	Controls.device_changed.connect(func(_d: String) -> void: _on_target(level.player.interact_target))
	_on_power_changed(level.player.power.power)
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
	_readiness.value = 1.0 - _badge.cooldown
	_power_hint.text = "%s  ·  %s" % [Controls.prompt("attack"), "Ready" if _badge.cooldown <= 0 else "Recharging"]
	_journey.value = clampf(p.position.x / maxf(1.0, level.data.pixel_size().x), 0, 1)
	_legend.visible = not Controls.using_touch()
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
	_objective.text = "Notes %d/%d  ·  %s" % [level.notes_found, level.notes_total, "Find the Flavor Page" if level.kind == "boss" else "Reach the flag"]
	_coins.text = str(GameState.stage_coins)
	_notes.text = "%d/%d" % [level.notes_found, level.notes_total]
	_keys.text = str(GameState.keys)
	_keys.visible = GameState.keys > 0
	_key_icon.visible = GameState.keys > 0


func _plate(parent: Node, width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 80)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UITheme.box(Color("343052"), Color("ffdc83"), 23, 3))
	parent.add_child(panel)
	return panel


func _on_power_changed(id: StringName) -> void:
	_badge.set_power(id)
	var definition := level.player.power.definition()
	_power_name.text = definition.ability_name if definition != null else "Honk"
	_power_name.tooltip_text = definition.description if definition != null else "A friendly honk that bops nearby creatures. Collect food for a new attack."


func _update_controls() -> void:
	_legend.text = "%s / %s  Move     %s  Jump / flap     %s  Attack     %s  Pause" % [Controls.prompt("move_left"), Controls.prompt("move_right"), Controls.prompt("jump"), Controls.prompt("attack"), Controls.prompt("pause")]


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
	_banner.visible = false
	_tip_owner = owner_obj
	_tip_label.text = Controls.fill(text)
	_tip.visible = true
	_tip.reset_size()


func hide_tip(owner_obj: Object) -> void:
	if _tip_owner == owner_obj:
		_tip.visible = false
		_banner.visible = true
		_tip_owner = null


func show_banner(title: String, subtitle: String) -> void:
	for c in _banner.get_children():
		c.queue_free()
	if subtitle != "":
		var sub := UITheme.outlined_label(subtitle, 26)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner.add_child(sub)
	_banner.add_child(UITheme.title_label(title, 38))
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
		icon = FoodDB.food_icon(id) if id != &"" else TatoVisual.frame_texture("cel_0")
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
