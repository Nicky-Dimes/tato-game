extends Prop
## Everything Tato collects by touching it. One script, picked by the level
## letter's type:
##   coin, heart, extraheal, star, note, key
##   pickup <name>   one of the 20 level pickups from the item board:
##     gem crystal            treasure (10 / 5 coins)
##     treat                  this world's own treat from the world board (5 coins)
##     flower leaf candy moon sun   charms (2 coins each)
##     cherry grape banana corn     fruit: +1 heart if hurt, else 5 coins
##     clover        lucky: coins count double for a while
##     orb           a guard bubble that soaks up one hit
##     feather       floaty falls for a while
##     mushroom      super jump for a while
##     wings         endless flaps for a while
##     magnet        coins fly to Tato for a while
##     time          creatures slow right down for a while
##     rainbow_star  nothing can hurt Tato; creatures poof on touch
##     egg           a surprise (one of the above)

const CHARMS := ["flower", "leaf", "candy", "moon", "sun"]
const FRUIT := ["cherry", "grape", "banana", "corn"]
const SURPRISES := ["gem", "wings", "magnet", "mushroom", "feather", "orb", "clover", "cherry"]

var kind := "coin"
var what := ""
var collect_id := ""
var _taken := false
var _already := false
var _sprite: Sprite2D
var _vel := Vector2.ZERO
var _loose := 0.0


func _configure() -> void:
	kind = p_str("type", "coin")
	what = arg(0, "gem") if kind == "pickup" else kind
	collect_id = p_str("collect_id")
	position = LevelData.cell_center(cell)
	var art := "items/" + what
	var size := 40.0
	match kind:
		"coin":
			size = 34.0
		"heart":
			size = 40.0
		"extraheal":
			art = "items/extra_heal"
			size = 64.0
		"star":
			size = 52.0
		"note":
			art = "items/treasure_note"
			size = 50.0
		"key":
			size = 46.0
		"pickup":
			art = "pickups/" + what
			size = 44.0
			if what == "treat":
				# the world's own treat; worlds without one show a crystal
				art = WorldKit.art(level.theme, "treat") if WorldKit.has_treat(level.theme) else "pickups/crystal"
				size = 46.0
	_sprite = Art.icon(art, size)
	add_child(_sprite)
	bob(_sprite, 4.0, 1.4 + fmod(cell.x * 0.37, 0.6))
	_already = (kind == "star" or kind == "note") and GameState.has_collected(kind, collect_id)
	if _already:
		_sprite.modulate = Color(1, 1, 1, 0.3)
	var touch := add_touch(Vector2(size, size))
	touch.body_entered.connect(func(body: Node) -> void:
		if body is Tato:
			grab(body as Tato))
	if kind == "coin" or kind == "pickup":
		add_to_group("grabbable")


## Coins knocked out of a creature or a block hop out and can be taken at once.
func toss(vel: Vector2) -> void:
	_vel = vel
	_loose = 0.9


func _physics_process(delta: float) -> void:
	if _taken:
		return
	if _loose > 0.0:
		_loose -= delta
		_vel.y += 1300.0 * delta
		position += _vel * delta
		if level != null and level.is_solid_at(global_position + Vector2(0, 14)) and _vel.y > 0.0:
			_vel = Vector2(_vel.x * 0.5, -_vel.y * 0.4)
			if absf(_vel.y) < 60.0:
				_loose = 0.0
	var p := level.player if level != null else null
	if p != null and kind == "coin" and p.magnet_time > 0.0:
		var d := (p.global_position + Vector2(0, -30)) - global_position
		if d.length() < 260.0:
			position += d.normalized() * 520.0 * delta


func grab(player: Tato) -> void:
	if _taken:
		return
	_taken = true
	var at := global_position
	match kind:
		"coin":
			GameState.add_coins(2 if player.luck_time > 0.0 else 1)
			AudioService.play_varied("coin", -6.0, 0.06)
		"heart":
			if not GameState.add_heart(1):
				GameState.add_coins(5)
			AudioService.play("heart")
			Fx.float_text(level, at + Vector2(0, -30), "+1 heart", UITheme.PINK)
		"extraheal":
			GameState.restore_hearts()
			AudioService.play("heart")
			Fx.float_text(level, at + Vector2(0, -40), "Hearts full!", UITheme.PINK)
		"star":
			if not _already:
				AudioService.play("star")
				Fx.float_text(level, at + Vector2(0, -40), "Star!", UITheme.YELLOW)
			level.collect("star", collect_id, at)
		"note":
			if not _already:
				AudioService.play("note")
				Fx.float_text(level, at + Vector2(0, -40), "Treasure Note!", UITheme.CREAM)
			level.collect("note", collect_id, at)
		"key":
			GameState.add_key()
			AudioService.play("key")
			Fx.float_text(level, at + Vector2(0, -40), "Key!", UITheme.YELLOW)
		"pickup":
			_use(what, player, at)
	Fx.sparkle(level, at, Color(1, 0.92, 0.45), 6)
	if kind in ["heart", "extraheal", "star", "note", "key"]:
		Fx.pop_ring(level, at, Color(1, 0.85, 0.55, 0.85), 34.0)
	queue_free()


func _use(item: String, player: Tato, at: Vector2) -> void:
	var say := ""
	var coins := 0
	if item == "egg":
		item = SURPRISES[randi() % SURPRISES.size()]
		Fx.pop_ring(level, at, Color(1, 1, 1), 50.0)
	if item == "gem":
		coins = 10
	elif item == "treat":
		coins = 5
		say = str(WorldKit.TREAT_NAMES.get(level.theme, "Treat")) + "!"
	elif item == "crystal":
		coins = 5
	elif CHARMS.has(item):
		coins = 2
		level.charms += 1
	elif FRUIT.has(item):
		if GameState.add_heart(1):
			say = "Yum! +1 heart"
		else:
			coins = 5
			say = "Yum!"
	elif item == "clover":
		player.luck_time = 15.0
		say = "Lucky! Double coins"
	elif item == "orb":
		player.orb_guard = true
		say = "Guard bubble"
	elif item == "feather":
		player.slow_fall_time = 12.0
		say = "Feather fall"
	elif item == "mushroom":
		player.super_jump_time = 12.0
		say = "Super jump!"
	elif item == "wings":
		player.wings_time = 10.0
		say = "Wings! Flap forever"
	elif item == "magnet":
		player.magnet_time = 12.0
		say = "Coin magnet"
	elif item == "time":
		level.slow_time(8.0)
		say = "Slow motion!"
	elif item == "rainbow_star":
		player.start_star(8.0)
		say = "Rainbow power!"
	if coins > 0:
		GameState.add_coins(coins * (2 if player.luck_time > 0.0 else 1))
		if say == "":
			say = "+%d" % coins
	AudioService.play("pickup" if coins == 0 else "coin_big")
	if say != "":
		Fx.float_text(level, at + Vector2(0, -34), say, UITheme.YELLOW)
	level.hud.on_boost()
