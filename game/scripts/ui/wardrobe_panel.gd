class_name WardrobePanel
extends Control
## The wardrobe in the Home Nest: little things for Tato to wear on his head,
## bought with coins. Looks only; nothing here changes how the game plays,
## and nothing costs real money.

signal closed

## id, name, picture, price
const HATS := [
	["", "Nothing", "", 0],
	["flower", "Daisy", "pickups/flower", 20],
	["leaf", "Leaf", "pickups/leaf", 20],
	["clover", "Lucky Clover", "pickups/clover", 40],
	["cherry", "Cherries", "pickups/cherry", 40],
	["candy", "Lollipop Swirl", "pickups/candy", 60],
	["feather", "Feather", "pickups/feather", 60],
	["mushroom", "Mushroom Cap", "pickups/mushroom", 80],
	["moon", "Moon", "pickups/moon", 100],
	["sun", "Sunny", "pickups/sun", 100],
	["star", "Star", "items/star", 150],
	["crown", "Crown", "world/castle_gem1", 250],
]

var _grid: GridContainer
var _coins: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.19, 0.08, 0.27, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := UITheme.panel()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UITheme.title_label("Wardrobe", 40))
	_coins = UITheme.label("", 24, UITheme.PLUM, true)
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_coins)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(_grid)
	var done := UITheme.button("Done", Vector2(220, 58))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(func() -> void: closed.emit())
	box.add_child(done)
	_fill()
	done.grab_focus()


static func hat_art(id: String) -> String:
	for h: Array in HATS:
		if h[0] == id:
			return h[2]
	return ""


func _fill() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_coins.text = "Coins: %d" % GameState.wallet()
	var worn := GameState.equipped("hat")
	for h: Array in HATS:
		var id: String = h[0]
		var owned := id == "" or GameState.owns_cosmetic(id)
		var text := str(h[1])
		if id == worn:
			text += "\n(wearing)"
		elif not owned:
			text += "\n%d coins" % int(h[3])
		var b := UITheme.button(text, Vector2(190, 110))
		b.add_theme_font_size_override("font_size", 20)
		b.icon = Art.tex(h[2]) if h[2] != "" else null
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not owned and GameState.wallet() < int(h[3])
		b.pressed.connect(_pick.bind(id, int(h[3])))
		_grid.add_child(b)


func _pick(id: String, price: int) -> void:
	if id != "" and not GameState.owns_cosmetic(id):
		if not GameState.spend_coins(price):
			return
		GameState.unlock_cosmetic(id)
		AudioService.play("coin_big")
	GameState.equip("hat", id)
	_fill()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		closed.emit()
		get_viewport().set_input_as_handled()
