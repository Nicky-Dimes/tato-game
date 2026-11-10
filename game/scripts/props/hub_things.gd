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
			_sprite = Art.standing("props/worldgate_open" if open else "props/worldgate_locked")
			add_child(_sprite)
			var w := LevelDB.world(_world)
			_label = UITheme.outlined_label("%d" % int(w.get("index", 1)), 34, UITheme.YELLOW if open else Color(0.8, 0.8, 0.85))
			_label.position = Vector2(-60, -190)
			_label.size = Vector2(120, 40)
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(_label)
			if GameState.has_collected("page", _world):
				var star := Art.centered("items/page")
				star.position = Vector2(0, -212)
				add_child(star)
		"book":
			add_child(Art.standing("props/book_stand"))
		"wardrobe":
			add_child(Art.standing("props/wardrobe"))
		_:
			add_child(Art.standing("props/door"))
	add_sense(Vector2(110, 150), Vector2(0, -75))


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
			return "Read the Recipe Notebook"
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
				level.hud.show_message("Find the %s first" % str(prev.get("page", "last page")), 2.0)
		"book":
			level._pause_menu.open("journal")
		"wardrobe":
			level.open_wardrobe()
		_:
			var to := p_str("to")
			if to != "":
				Game.start_level(to)
