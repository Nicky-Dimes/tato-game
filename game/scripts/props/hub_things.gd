extends Prop
## Home Nest furniture: one script, picked by type.
##   worldgate W1     a gate to a world's stage map (locked until earned)
##   book             Mimi's Recipe Notebook
##   door to=<stage>  walk into another stage (the Snack Trial room, etc.)
##   wardrobe         hats and ribbons

var _kind := "worldgate"
var _world := "W1"
var _label: Label
var _sprite: Sprite2D


func _configure() -> void:
	_kind = p_str("type", "worldgate")
	match _kind:
		"worldgate":
			_world = arg(0, "W1")
			var open := GameState.world_unlocked(_world)
			var w := LevelDB.world(_world)
			_sprite = Art.sized("cards/world_%s" % str(w.get("theme", "grassland")), 104.0)
			_sprite.position = Vector2(0, -40)
			if not open:
				_sprite.modulate = Color(0.35, 0.3, 0.45)
			add_child(_sprite)
			_label = UITheme.outlined_label("%d. %s" % [int(w.get("index", 1)), str(w.get("name", "")) if open else "? ? ?"], 22, UITheme.YELLOW if open else Color(0.8, 0.8, 0.85))
			_label.position = Vector2(-130, -184)
			_label.size = Vector2(260, 30)
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(_label)
			if GameState.has_collected("page", _world):
				var star := Art.icon("items/star", 34.0)
				star.position = Vector2(0, -206)
				add_child(star)
		"book":
			add_child(Art.sized("items/crate", 52.0))
			var note := Art.icon("items/treasure_note", 50.0)
			note.position = Vector2(0, -80)
			add_child(note)
			bob(note, 4.0, 1.8)
		"wardrobe":
			add_child(Art.sized("items/crate", 52.0))
			var feather := Art.icon("pickups/feather", 48.0)
			feather.position = Vector2(0, -80)
			add_child(feather)
			bob(feather, 4.0, 1.6)
		_:
			add_child(Art.sized(WorldKit.art(level.theme, "flag"), 96.0))
	add_sense(Vector2(110, 150), Vector2(0, -75))


func uses_attack_button() -> bool:
	return true


func can_interact(_player: Tato) -> bool:
	return true


func prompt() -> String:
	match _kind:
		"worldgate":
			var w := LevelDB.world(_world)
			if GameState.world_unlocked(_world):
				return "Enter %s" % str(w.get("name", ""))
			return "Locked"
		"book":
			return "Open the Snack Notebook"
		"wardrobe":
			return "Open the wardrobe"
	return "Go in"


func interact(_player: Tato) -> void:
	match _kind:
		"worldgate":
			if GameState.world_unlocked(_world):
				AudioService.play("gate_open")
				Game.goto_world_map(_world)
			else:
				AudioService.play("deny")
				var prev := LevelDB.world("W%d" % (int(LevelDB.world(_world).get("index", 2)) - 1))
				level.hud.show_message("Beat %s first" % str(prev.get("boss", "the last boss")), 2.0)
		"book":
			level._pause_menu.open("journal")
		"wardrobe":
			level.open_wardrobe()
		_:
			var to := p_str("to")
			if to != "":
				Game.start_level(to)
