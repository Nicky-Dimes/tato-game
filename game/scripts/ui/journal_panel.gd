class_name JournalPanel
extends Control
## Mimi's Recipe Notebook: snacks met so far, the twelve signature recipes
## (names stay "? ? ?" until first cooked), kitchen experiments, and the
## collection (pages, scraps, pins, dishes, medals).

signal closed

const TABS := ["Snacks", "Recipes", "Collection"]

var _body: VBoxContainer
var _tab_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70.0
	panel.offset_right = -70.0
	panel.offset_top = 34.0
	panel.offset_bottom = -34.0
	add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	outer.add_child(UITheme.title_label("Recipe Notebook", 40))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	outer.add_child(tabs)
	for t: String in TABS:
		var b := UITheme.small_button(t)
		b.custom_minimum_size = Vector2(190, 52)
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
	_show_tab("Snacks")
	_tab_buttons[0].grab_focus()


func _show_tab(tab: String) -> void:
	for c in _body.get_children():
		c.queue_free()
	for i in TABS.size():
		_tab_buttons[i].modulate = Color.WHITE if TABS[i] == tab else Color(1, 1, 1, 0.7)
	match tab:
		"Snacks":
			_build_snacks()
		"Recipes":
			_build_recipes()
		"Collection":
			_build_collection()


func _icon(tex: Texture2D, size: float, known: bool) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(size, size)
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


func _build_snacks() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_body.add_child(grid)
	for def in FoodDB.all_foods():
		var known := GameState.knows_food(def.id)
		var card := _card()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		row.add_child(_icon(FoodDB.icon(def.icon_path), 72, known))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		if known:
			col.add_child(UITheme.label("%s  -  %s" % [def.display_name, def.ability_name], 22, UITheme.PLUM, true))
			var d := UITheme.label(def.description, 18)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(d)
			var r := UITheme.label("Watch out: " + def.risk, 16, UITheme.PLUM_SOFT)
			r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(r)
		else:
			col.add_child(UITheme.label("? ? ?", 22, UITheme.PLUM_SOFT, true))
			col.add_child(UITheme.label("A snack from world %d." % def.unlock_world, 18, UITheme.PLUM_SOFT))
		grid.add_child(card)


func _build_recipes() -> void:
	var found := GameState.named_recipes_found()
	_body.add_child(UITheme.label("Signature recipes: %d of %d      Kitchen experiments: %d" % [found, FoodDB.RECIPE_IDS.size(), GameState.experiments_found()], 22, UITheme.PLUM, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_body.add_child(grid)
	for rec in FoodDB.named_recipes():
		grid.add_child(_recipe_card(rec, GameState.knows_recipe(rec)))
	var extra: Array = []
	for key: String in GameState.profile["recipe_discoveries"]:
		var rec2 := FoodDB.resolve_key(key)
		if rec2 != null and not rec2.named:
			extra.append(rec2)
	if extra.size() > 0:
		_body.add_child(UITheme.label("Kitchen experiments", 24, UITheme.ORANGE_DARK, true))
		var grid2 := GridContainer.new()
		grid2.columns = 2
		grid2.add_theme_constant_override("h_separation", 10)
		grid2.add_theme_constant_override("v_separation", 10)
		_body.add_child(grid2)
		for rec3: RecipeDefinition in extra:
			grid2.add_child(_recipe_card(rec3, true))


func _recipe_card(rec: RecipeDefinition, known: bool) -> PanelContainer:
	var card := _card()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	# ingredients are shown once the player has met both snacks
	var a_known := GameState.knows_food(rec.food_a)
	var b_known := GameState.knows_food(rec.food_b)
	row.add_child(_icon(FoodDB.food_icon(rec.food_a), 52, known or a_known))
	row.add_child(UITheme.label("+", 26, UITheme.PLUM, true))
	row.add_child(_icon(FoodDB.food_icon(rec.food_b), 52, known or b_known))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	if known:
		col.add_child(UITheme.label(rec.display_name, 22, UITheme.PLUM, true))
		var d := UITheme.label(rec.description, 18)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(d)
	else:
		col.add_child(UITheme.label("? ? ?", 22, UITheme.PLUM_SOFT, true))
		col.add_child(UITheme.label("Carry both snacks and fuse them to find out.", 18, UITheme.PLUM_SOFT))
	return card


func _build_collection() -> void:
	var top := UITheme.label("Flavor Pages %d/%d     Recipe Scraps %d/%d     Goose Pins %d/%d     Secret Dishes %d/%d     Feather Medals %d" % [
		GameState.count("page"), LevelDB.WORLDS.size(),
		GameState.count("scrap"), LevelDB.scrap_total(),
		GameState.count("pin"), LevelDB.pin_total(),
		GameState.count("dish"), LevelDB.dish_total(),
		GameState.medal_count()], 20, UITheme.PLUM, true)
	top.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(top)
	for w in LevelDB.WORLDS:
		var wid: String = w["id"]
		var open := GameState.world_unlocked(wid)
		var card := _card()
		var col := VBoxContainer.new()
		card.add_child(col)
		var title := "%d. %s" % [int(w["index"]), str(w["name"]) if open else "? ? ?"]
		if GameState.has_collected("page", wid):
			title += "   -   " + str(w["page"])
		col.add_child(UITheme.label(title, 24, UITheme.PLUM, true))
		if open:
			col.add_child(UITheme.label("Scraps %d/%d    Pins %d/%d    Dishes %d/%d" % [
				GameState.count_in_world("scrap", wid), LevelDB.SCRAPS_PER_WORLD,
				GameState.count_in_world("pin", wid), LevelDB.PINS_PER_WORLD,
				GameState.count_in_world("dish", wid), LevelDB.DISHES_PER_WORLD], 20))
			var names: Array[String] = []
			for id: String in GameState.profile["secret_dishes"]:
				if id.begins_with(wid):
					names.append(Story.dish_name(id))
			if names.size() > 0:
				var dl := UITheme.label("Dishes: " + ", ".join(names), 18, UITheme.PLUM_SOFT)
				dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				col.add_child(dl)
		_body.add_child(card)
