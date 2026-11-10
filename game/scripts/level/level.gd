class_name Level
extends Node2D
## One playable stage, built at run time from a text file (see LevelData).
## Owns the terrain, Tato, the camera, the HUD and the stage rules:
## checkpoints, falling out, snack-break respawns, links between switches
## and the things they open, and finishing the stage.

signal completed(stats: Dictionary)
signal link_changed(id: String, active: int)
signal player_respawned

const TILE := Layers.TILE

var level_id := ""
var data: LevelData
var theme := "picnic"
var kind := "core"
var terrain: Terrain
var entities: Node2D
var player: Tato
var camera: CameraRig
var hud: HUD
var touch: TouchControls
var backdrop: Backdrop
var boss: Node = null

var elapsed := 0.0
var finished := false
var scraps_total := 0
var scraps_found := 0
var checkpoint_position := Vector2.ZERO
var checkpoint_inventory: Dictionary = {}
var active_checkpoint: Node = null

var _links: Dictionary = {}          # id -> Array[Node] targets
var _link_sources: Dictionary = {}   # id -> Dictionary(source instance id -> true)
var _pause_menu: PauseMenu
var _replace_prompt: ReplacePrompt
var _dialogue: DialogueBox
var _respawning := false
var _started := false


func _ready() -> void:
	level_id = Game.level_id if Game.level_id != "" else "W1-L1"
	data = LevelDB.load_level(level_id)
	if data == null:
		push_error("Stage %s could not be loaded" % level_id)
		data = LevelData.parse("[map]\n@\n####\n", level_id)
	for e in data.errors:
		push_warning("%s: %s" % [level_id, e])
	var w := LevelDB.world_of(level_id)
	theme = data.meta_str("theme", str(w.get("theme", "nest")))
	kind = data.meta_str("kind", LevelDB.stage_kind(level_id))
	process_mode = Node.PROCESS_MODE_PAUSABLE

	backdrop = Backdrop.new()
	add_child(backdrop)
	backdrop.setup(theme, data.pixel_size())

	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build(data, theme)
	_build_bounds()

	entities = Node2D.new()
	entities.name = "Entities"
	add_child(entities)

	player = Tato.new()
	player.name = "Tato"
	player.level = self
	player.position = data.spawn_point()
	add_child(player)
	checkpoint_position = player.position
	player.last_safe_position = player.position

	_build_entities()

	camera = CameraRig.new()
	add_child(camera)
	camera.setup(player, data.pixel_size())

	hud = HUD.new()
	add_child(hud)
	hud.setup(self)
	touch = TouchControls.new()
	add_child(touch)
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_replace_prompt = ReplacePrompt.new()
	add_child(_replace_prompt)
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.setup(self)

	player.fell_out.connect(_on_fell_out)
	player.got_hurt.connect(_on_player_hurt)
	player.replace_needed.connect(_on_replace_needed)
	GameState.recipe_discovered.connect(_on_recipe_discovered)
	GameState.reset_session()
	if Game.start_checkpoint != "":
		_start_at_checkpoint(Game.start_checkpoint)

	var music := data.meta_str("music", str(w.get("music", "hub")))
	AudioService.music(music)
	hud.show_banner(LevelDB.stage_name(level_id) if data.meta_str("name") == "" else data.meta_str("name"), str(w.get("name", "")))
	_started = true
	var intro := data.meta_str("intro")
	if intro != "" and not GameState.has_flag("seen_" + intro) and not Game.headless_test:
		GameState.set_flag("seen_" + intro)
		say(intro)


func _physics_process(delta: float) -> void:
	if not finished:
		elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if finished or Game.is_transitioning:
		return
	if event.is_action_pressed("pause"):
		if _dialogue.is_open() or _replace_prompt.is_open():
			return
		_pause_menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hint"):
		show_hint_nest()
	elif event.is_action_pressed("map"):
		_pause_menu.open("journal")


# ------------------------------------------------------------------ build --

func _build_bounds() -> void:
	var size := data.pixel_size()
	var walls := StaticBody2D.new()
	walls.name = "Bounds"
	walls.collision_layer = Layers.WORLD
	walls.collision_mask = 0
	for x: float in [-32.0, size.x + 32.0]:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(64, size.y + 2000.0)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(x, size.y * 0.5 - 600.0)
		walls.add_child(cs)
	add_child(walls)


func _build_entities() -> void:
	var counters := {"scrap": 0, "pin": 0, "dish": 0}
	for e in data.entities:
		var type: String = e["type"]
		if type == "spawn":
			continue
		if counters.has(type):
			counters[type] = int(counters[type]) + 1
			var letter := type.substr(0, 1).to_upper()
			e["params"]["collect_id"] = "%s-%s%02d" % [level_id, letter, int(counters[type])]
		var node := EntityFactory.create(self, e)
		if node == null:
			continue
		entities.add_child(node)
		var link_id := str(e["params"].get("id", ""))
		if link_id != "":
			register_link(link_id, node)
	scraps_total = int(counters["scrap"])
	scraps_found = GameState.count_in_level("scrap", level_id)
	# let targets learn their starting state once everything exists
	for id: String in _links.keys():
		_notify_link(id)


# ------------------------------------------------------------- level facts --

func water_at(point: Vector2) -> bool:
	return terrain.water_at(point)


func water_surface_at(point: Vector2) -> float:
	for r in terrain.water_rects:
		if r.has_point(point):
			return r.position.y
	return point.y


func kill_plane_y() -> float:
	return data.pixel_size().y + 180.0


func shake(amount: float) -> void:
	if camera:
		camera.shake(amount)


func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE), floori(point.y / TILE))


func is_solid_at(point: Vector2) -> bool:
	var c := cell_at(point)
	return data.is_block(c.x, c.y)


# ------------------------------------------------------------------ links --

func register_link(id: String, node: Node) -> void:
	if not _links.has(id):
		_links[id] = []
	(_links[id] as Array).append(node)


## A switch, chime, plate ... reports that it is on or off. Everything that
## shares the id hears how many sources are currently on.
func trigger(id: String, on: bool, source: Node) -> void:
	if id == "":
		return
	if not _link_sources.has(id):
		_link_sources[id] = {}
	var sources: Dictionary = _link_sources[id]
	var key := source.get_instance_id()
	if on:
		sources[key] = true
	else:
		sources.erase(key)
	_notify_link(id)


func link_active_count(id: String) -> int:
	return (_link_sources.get(id, {}) as Dictionary).size()


func _notify_link(id: String) -> void:
	var count := link_active_count(id)
	link_changed.emit(id, count)
	for node: Node in _links.get(id, []):
		if is_instance_valid(node) and node.has_method("on_link"):
			node.call("on_link", count)


func nodes_with_id(id: String) -> Array:
	return _links.get(id, [])


# ------------------------------------------------------------- collectibles --

func collect(collect_kind: String, id: String, at: Vector2) -> void:
	var fresh := GameState.collect(collect_kind, id)
	if collect_kind == "scrap" and fresh:
		scraps_found += 1
	hud.on_collect(collect_kind, fresh)
	if fresh:
		Fx.sparkle(self, at, Color(1, 0.92, 0.45), 8)


# -------------------------------------------------------------- checkpoints --

func activate_checkpoint(cp: Node2D) -> void:
	if active_checkpoint == cp:
		return
	if active_checkpoint != null and is_instance_valid(active_checkpoint) and active_checkpoint.has_method("set_lit"):
		active_checkpoint.call("set_lit", false)
	active_checkpoint = cp
	checkpoint_position = cp.global_position
	checkpoint_inventory = player.inventory.snapshot()
	GameState.restore_feathers()
	GameState.profile["checkpoint"] = str(cp.get("checkpoint_id"))
	GameState.profile["current_level"] = level_id if level_id != LevelDB.HUB_ID else str(GameState.profile.get("current_level", ""))
	GameState.save()
	Captions.caption("Snack station reached")


func _start_at_checkpoint(cp_id: String) -> void:
	for node in get_tree().get_nodes_in_group("checkpoint"):
		if str(node.get("checkpoint_id")) == cp_id:
			active_checkpoint = node
			checkpoint_position = (node as Node2D).global_position
			player.global_position = checkpoint_position
			player.last_safe_position = checkpoint_position
			if node.has_method("set_lit"):
				node.call("set_lit", true)
			return


func _on_player_hurt() -> void:
	if GameState.lose_feather():
		call_deferred("respawn_at_checkpoint")


func _on_fell_out() -> void:
	if _respawning or finished:
		return
	_respawning = true
	var out := GameState.lose_feather()
	AudioService.voice("honk_hurt")
	if out:
		respawn_at_checkpoint()
	else:
		player.teleport_to(player.last_safe_position)
		camera.snap()
		Fx.puff(self, player.global_position, Color(1, 1, 1, 0.8), 5)
		player_respawned.emit()
	_respawning = false


## Out of Comfort Feathers: a little "snack break" back at the last station.
## Nothing is lost; puzzle pieces reset so the room can always be solved.
func respawn_at_checkpoint() -> void:
	if finished:
		return
	_respawning = true
	player.set_disabled(true)
	hud.show_message("Snack break!")
	if not Game.headless_test:
		await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	reset_puzzles()
	GameState.restore_feathers()
	if not checkpoint_inventory.is_empty():
		player.inventory.restore(checkpoint_inventory)
	player.teleport_to(checkpoint_position)
	player.last_safe_position = checkpoint_position
	player.set_disabled(false)
	camera.snap()
	_respawning = false
	player_respawned.emit()


## Puts loose puzzle pieces back (crates, melted blocks, switches ...).
func reset_puzzles() -> void:
	for node in get_tree().get_nodes_in_group("resettable"):
		if node.has_method("reset_puzzle") and is_ancestor_of(node):
			node.call("reset_puzzle")
	for t in get_tree().get_nodes_in_group("temporary"):
		if is_ancestor_of(t):
			t.queue_free()


# ------------------------------------------------------------------ finish --

func complete_level() -> void:
	if finished:
		return
	finished = true
	player.celebrate()
	AudioService.duck_music(2.0)
	AudioService.play("level_clear")
	var stats := {
		"time": elapsed,
		"hurt": player.hurt_count,
		"scraps_found": scraps_found,
		"scraps_total": scraps_total,
	}
	var result := Game.finish_level(stats)
	completed.emit(stats)
	if Game.headless_test:
		return
	await get_tree().create_timer(1.3).timeout
	if not is_inside_tree():
		return
	var panel := ResultsPanel.new()
	add_child(panel)
	panel.show_results(self, stats, result)


# ---------------------------------------------------------------- dialogue --

func say(dialogue_id: String, on_done: Callable = Callable()) -> void:
	if Game.headless_test:
		if on_done.is_valid():
			on_done.call()
		return
	_dialogue.play(dialogue_id, player, on_done)


func say_lines(lines: Array, on_done: Callable = Callable()) -> void:
	if Game.headless_test:
		if on_done.is_valid():
			on_done.call()
		return
	_dialogue.play_lines(lines, player, on_done)


func dialogue_open() -> bool:
	return _dialogue != null and _dialogue.is_open()


func show_hint_nest() -> void:
	var hints: Array = HintNest.hints_for(self)
	if hints.is_empty():
		hud.show_message("Honk at things. Eat snacks. Try both together!")
		return
	hud.show_hint(hints)


# ------------------------------------------------------------------ prompts --

func _on_replace_needed(food: StringName) -> void:
	if Game.headless_test:
		player.resolve_replace(FoodInventory.SLOT_A)
		return
	_replace_prompt.ask(player, food)


func _on_recipe_discovered(rec: RecipeDefinition) -> void:
	if not _started or Game.headless_test:
		return
	hud.show_recipe(rec)
