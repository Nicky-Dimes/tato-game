class_name JournalPanel
extends Control
## The Snack Notebook: the twelve power-ups (with the action pictures from
## the item board), the Flavor Bursts found so far, the creatures met, and
## the collection (pages, stars, Treasure Notes, coins).

signal closed

const TABS := ["Powers", "Bursts", "Creatures", "Collection"]

var _body: VBoxContainer
var _tab_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 60.0
	panel.offset_right = -60.0
	panel.offset_top = 30.0
	panel.offset_bottom = -30.0
	add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	outer.add_child(UITheme.title_label("Snack Notebook", 40))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	outer.add_child(tabs)
	for t: String in TABS:
		var b := UITheme.small_button(t)
		b.custom_minimum_size = Vector2(170, 52)
		b.pressed.connect(_show_tab.bind(t))
		tabs.add_child(b)
		_tab_buttons.append(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)
	var back := UITheme.button("Close", Vector2(220, 58))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	outer.add_child(back)
	_show_tab("Powers")
	_tab_buttons[0].grab_focus()


func _show_tab(tab: String) -> void:
	for c in _body.get_children():
		c.queue_free()
	for i in TABS.size():
		_tab_buttons[i].modulate = Color.WHITE if TABS[i] == tab else Color(1, 1, 1, 0.7)
	match tab:
		"Powers":
			_build_powers()
		"Bursts":
			_build_bursts()
		"Creatures":
			_build_creatures()
		"Collection":
			_build_collection()


func _pic(tex: Texture2D, size: Vector2, known: bool = true) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = size
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not known:
		tr.modulate = Color(0.19, 0.08, 0.27, 0.55)   # silhouette, never a spoiler
	return tr


func _card() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.box(UITheme.CREAM_DARK, UITheme.PLUM, 16, 3, false))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func _build_powers() -> void:
	_body.add_child(UITheme.label("One power at a time: the newest food bowl replaces the old power.", 20, UITheme.PLUM_SOFT, true))
	for def in FoodDB.all_foods():
		var known := GameState.knows_food(def.id)
		var card := _card()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		row.add_child(_pic(FoodDB.icon(def.icon_path), Vector2(70, 70), known))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		if known:
			col.add_child(UITheme.label("%s  -  %s" % [def.display_name, def.ability_name], 22, UITheme.PLUM, true))
			var d := UITheme.label(def.description, 18)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(d)
			row.add_child(_pic(FoodDB.icon(def.demo_path), Vector2(330, 70)))
		else:
			col.add_child(UITheme.label("? ? ?", 22, UITheme.PLUM_SOFT, true))
			var w := LevelDB.world("W%d" % def.unlock_world)
			col.add_child(UITheme.label("Waiting in a food bowl in %s." % str(w.get("name", "a later world")), 18, UITheme.PLUM_SOFT))
		_body.add_child(card)


func _build_bursts() -> void:
	_body.add_child(UITheme.label("Flavor Bursts found: %d of %d" % [GameState.bursts_found(), FoodDB.burst_total()], 22, UITheme.PLUM, true))
	var tip := UITheme.label("Pick up a new power while holding a different one: the two flavours burst together and bop everything nearby.", 18, UITheme.PLUM_SOFT)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(tip)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)
	for key: String in GameState.profile["recipe_discoveries"]:
		var rec := FoodDB.resolve_key(key)
		if rec == null:
			continue
		var card := _card()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		card.add_child(row)
		row.add_child(_pic(FoodDB.food_icon(rec.food_a), Vector2(40, 40)))
		row.add_child(UITheme.label("+", 22, UITheme.PLUM, true))
		row.add_child(_pic(FoodDB.food_icon(rec.food_b), Vector2(40, 40)))
		row.add_child(UITheme.label(rec.display_name, 20, UITheme.PLUM, true))
		grid.add_child(card)


func _build_creatures() -> void:
	var met: Array = GameState.profile["enemies_met"]
	_body.add_child(UITheme.label("Creatures met: %d of %d" % [met.size(), EnemyData.kinds().size()], 22, UITheme.PLUM, true))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)
	for kind: String in EnemyData.kinds():
		var known := met.has(kind)
		var card := _card()
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(col)
		col.add_child(_pic(Art.tex("enemies/" + kind), Vector2(84, 84), known))
		var name_l := UITheme.label(str(EnemyData.stat(kind, "name", kind)) if known else "? ? ?", 18, UITheme.PLUM, true)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name_l)
		if known:
			var role := UITheme.label(str(EnemyData.stat(kind, "role", "")), 15, UITheme.PLUM_SOFT)
			role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(role)
		grid.add_child(card)


func _build_collection() -> void:
	var top := UITheme.label("Flavor Pages %d/%d     Stars %d/%d     Treasure Notes %d/%d     Coins %d" % [
		GameState.count("page"), LevelDB.WORLDS.size(),
		GameState.count("star"), LevelDB.star_total(),
		GameState.count("note"), LevelDB.note_total(),
		GameState.wallet()], 20, UITheme.PLUM, true)
	top.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(top)
	for w in LevelDB.WORLDS:
		var wid: String = w["id"]
		var open := GameState.world_unlocked(wid)
		var card := _card()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		row.add_child(_pic(Art.tex("cards/world_%s" % str(w["theme"])), Vector2(150, 66), open))
		var col := VBoxContainer.new()
		row.add_child(col)
		var title := "%d. %s" % [int(w["index"]), str(w["name"]) if open else "? ? ?"]
		if GameState.has_collected("page", wid):
			title += "   -   " + str(w["page"])
		col.add_child(UITheme.label(title, 24, UITheme.PLUM, true))
		if open:
			col.add_child(UITheme.label("Stars %d/15    Treasure Notes %d/15" % [
				GameState.count_in_world("star", wid), GameState.count_in_world("note", wid)], 20))
		_body.add_child(card)
