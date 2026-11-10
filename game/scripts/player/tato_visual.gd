class_name TatoVisual
extends Node2D
## Tato's picture. Frames are the poses cut from the approved concept boards
## (tools/art/extract_tato.py): every frame shares one canvas size and one
## foot anchor, so swapping frames never makes the body jump. Squash and
## stretch, lean, breathing and spin are added here in code, on top of the
## drawn frames, and never touch the collision shape.

const FRAME_DIR := "res://assets/sprites/tato/"
const CANVAS := 192.0
const ANCHOR := Vector2(96, 168)
const SPRITE_SCALE := 0.76

## name -> [frames, fps, loop]
const ANIMS := {
	"idle": [["jump_land"], 1.0, true],
	"look": [["walk_2"], 1.0, true],
	"walk": [["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_1", "walk_2", "walk_3"], 12.0, true],
	"run": [["run_0", "run_1", "run_2", "run_3", "run_4", "run_1", "run_2", "run_3"], 16.0, true],
	"jump": [["jump_takeoff"], 1.0, true],
	"fall": [["jump_flap"], 1.0, true],
	"glide": [["jump_air", "jump_flap"], 11.0, true],
	"flap": [["jump_air"], 1.0, true],
	"crouch": [["jump_crouch"], 1.0, true],
	"slide": [["jump_crouch"], 1.0, true],
	"swim": [["walk_2", "walk_1", "walk_2", "walk_3"], 5.0, true],
	"honk": [["jump_air"], 1.0, true],
	"eat": [["jump_crouch", "jump_land"], 9.0, true],
	"hurt": [["jump_air"], 1.0, true],
	"cheer": [["cheer", "jump_air", "cheer", "jump_flap"], 6.0, true],
	"ball": [["roll_3"], 1.0, true],
	"roll": [["roll_2"], 1.0, true],
	"curl": [["roll_0"], 1.0, true],
	"float": [["jump_land"], 1.0, true],
	"puffed": [["size_puffed"], 1.0, true],
	"climb": [["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_1", "walk_2", "walk_3"], 10.0, true],
	"stretch": [["jump_takeoff"], 1.0, true],
	"charge": [["jump_crouch"], 1.0, true],
	"back": [["back_view"], 1.0, true],
}

static var _textures: Dictionary = {}
static var _shadow_tex: Texture2D

var player: Tato
var body: Node2D            # squash / lean / spin pivot (at the feet)
var sprite: Sprite2D
var back: Node2D            # powers may add nodes behind Tato
var front: Node2D           # ... or in front
var shadow: Node2D

## Set by snack powers.
var spin_speed := 0.0       # radians/sec, for ball forms
var extra_rotation := 0.0   # e.g. wall climbing
var pivot_height := 0.0     # ball forms rotate around their centre
var tint := Color.WHITE
var body_scale := 1.0
var pose_offset := Vector2.ZERO   # e.g. feet on a wall or ceiling

var _anim := ""
var _frame_time := 0.0
var _frame_index := 0
var _squash := Vector2.ONE
var _squash_vel := Vector2.ZERO
var _spin := 0.0
var _lean := 0.0
var _clock := 0.0
var _flap_timer := 0.0
var _blink_left := 0.0
var _force_anim := ""
var _force_left := 0.0
var _honk_marks := 0.0
var _marks: Node2D
var _idle_timer := 0.0
var _hat: Sprite2D


func setup(owner_player: Tato) -> void:
	player = owner_player
	back = Node2D.new()
	back.name = "Back"
	add_child(back)
	body = Node2D.new()
	body.name = "Body"
	add_child(body)
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = -ANCHOR
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	body.add_child(sprite)
	front = Node2D.new()
	front.name = "Front"
	add_child(front)
	_marks = HonkMarks.new()
	_marks.visible = false
	add_child(_marks)
	shadow = Sprite2D.new()
	(shadow as Sprite2D).texture = shadow_texture()
	shadow.top_level = true
	shadow.z_index = 1
	add_child(shadow)
	_set_anim("idle")
	refresh_cosmetics()


static func shadow_texture() -> Texture2D:
	if _shadow_tex == null:
		var grad := Gradient.new()
		grad.set_color(0, Color(0.16, 0.07, 0.22, 0.34))
		grad.set_color(1, Color(0.16, 0.07, 0.22, 0.0))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 64
		tex.height = 18
		_shadow_tex = tex
	return _shadow_tex


static func frame_texture(frame: String) -> Texture2D:
	if _textures.has(frame):
		return _textures[frame]
	var path := FRAME_DIR + frame + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_textures[frame] = tex
	return tex


## Shows the hat picked in the wardrobe (a small picture on Tato's head).
func refresh_cosmetics() -> void:
	if _hat != null and is_instance_valid(_hat):
		_hat.queue_free()
		_hat = null
	var art := WardrobePanel.hat_art(GameState.equipped("hat"))
	if art == "" or not Art.has(art):
		return
	_hat = Art.icon(art, 34.0)
	_hat.position = Vector2(4, -94)
	body.add_child(_hat)


func squash(amount: Vector2) -> void:
	_squash = amount


func flap() -> void:
	_flap_timer = 0.16


func honk_flash() -> void:
	_honk_marks = 0.24
	_marks.visible = true


func start_blink(seconds: float) -> void:
	_blink_left = seconds


func force_anim(anim: String, seconds: float) -> void:
	_force_anim = anim
	_force_left = seconds


func reset_powers() -> void:
	spin_speed = 0.0
	extra_rotation = 0.0
	pivot_height = 0.0
	tint = Color.WHITE
	body_scale = 1.0
	pose_offset = Vector2.ZERO
	_spin = 0.0


func _process(delta: float) -> void:
	if player == null:
		return
	_clock += delta
	var hint := player.anim_hint()
	if _force_left > 0.0:
		_force_left -= delta
		hint = _force_anim
	elif _flap_timer > 0.0:
		_flap_timer -= delta
		if hint == "jump" or hint == "fall" or hint == "glide":
			hint = "flap"
	# a little variety while standing around
	if hint == "idle":
		_idle_timer += delta
		if fmod(_idle_timer, 7.0) > 5.6:
			hint = "look"
	else:
		_idle_timer = 0.0
	_set_anim(hint)
	_advance(delta)

	# --- facing
	scale.x = -1.0 if player.facing < 0.0 else 1.0

	# --- squash & stretch spring back to rest
	var reduced := Settings.flag("reduced_motion")
	var stiffness := 190.0
	var damping := 14.0
	_squash_vel += (Vector2.ONE - _squash) * stiffness * delta
	_squash_vel -= _squash_vel * damping * delta
	_squash += _squash_vel * delta
	_squash = _squash.clamp(Vector2(0.6, 0.6), Vector2(1.5, 1.5))
	var s := _squash if not reduced else Vector2.ONE.lerp(_squash, 0.3)

	# --- procedural motion per animation
	var bob := 0.0
	var lean_target := 0.0
	match _anim:
		"idle", "look", "float", "puffed":
			var breathe := sin(_clock * 2.6) * 0.022
			s *= Vector2(1.0 - breathe * 0.6, 1.0 + breathe)
		"run":
			lean_target = 0.07
		"slide":
			lean_target = 0.38
			s *= Vector2(1.12, 0.86)
		"swim":
			bob = sin(_clock * 3.2) * 3.0
		"jump", "fall", "glide", "flap":
			lean_target = clampf(player.velocity.x / 900.0, -0.2, 0.2) * signf(scale.x)
		"hurt":
			lean_target = -0.5
		"eat":
			s *= Vector2(1.0, 1.0 + sin(_clock * 28.0) * 0.03)
		"cheer":
			bob = -absf(sin(_clock * 7.0)) * 10.0
		"charge":
			s *= Vector2(1.0 + sin(_clock * 40.0) * 0.02, 1.0)
	_lean = lerp_angle(_lean, lean_target, clampf(delta * 14.0, 0.0, 1.0))

	_spin = wrapf(_spin + spin_speed * delta, -PI, PI) if spin_speed != 0.0 else 0.0
	body.position = Vector2(0, bob - pivot_height) + pose_offset
	sprite.position = Vector2(0, pivot_height / maxf(body_scale, 0.01))
	body.rotation = _lean + extra_rotation + _spin
	body.scale = s * body_scale

	# --- tint / invulnerability blink
	var m := tint
	if _blink_left > 0.0:
		_blink_left -= delta
		if not Settings.flag("reduce_flashes"):
			m.a = 0.45 if fmod(_blink_left, 0.16) > 0.08 else 1.0
		else:
			m.a = 0.7
	body.modulate = m

	if _honk_marks > 0.0:
		_honk_marks -= delta
		_marks.modulate.a = clampf(_honk_marks / 0.12, 0.0, 1.0)
		if _honk_marks <= 0.0:
			_marks.visible = false

	_update_shadow()


func _set_anim(anim: String) -> void:
	if not ANIMS.has(anim):
		anim = "idle"
	if anim == _anim:
		return
	_anim = anim
	_frame_index = 0
	_frame_time = 0.0
	_show_frame()


func _advance(delta: float) -> void:
	var spec: Array = ANIMS[_anim]
	var frames: Array = spec[0]
	if frames.size() <= 1:
		return
	var fps: float = spec[1]
	# walk / run cadence follows real ground speed so feet do not skate
	if _anim == "walk" or _anim == "climb":
		fps *= clampf(absf(player.velocity.length()) / Tato.WALK_SPEED, 0.45, 1.3)
	elif _anim == "run":
		fps *= clampf(absf(player.velocity.x) / Tato.RUN_SPEED, 0.7, 1.3)
	_frame_time += delta * fps
	while _frame_time >= 1.0:
		_frame_time -= 1.0
		_frame_index += 1
		if _frame_index >= frames.size():
			_frame_index = 0 if spec[2] else frames.size() - 1
		_show_frame()


func _show_frame() -> void:
	var frames: Array = ANIMS[_anim][0]
	var tex := frame_texture(frames[_frame_index])
	if tex != null:
		sprite.texture = tex


func current_anim() -> String:
	return _anim


func _update_shadow() -> void:
	if player.in_water or not is_inside_tree():
		shadow.visible = false
		return
	var space := get_world_2d().direct_space_state
	var from := player.global_position + Vector2(0, -12)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 360), Layers.WORLD | Layers.ONEWAY)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		shadow.visible = false
		return
	shadow.visible = true
	var point: Vector2 = hit["position"]
	shadow.global_position = point
	var height := clampf((point.y - player.global_position.y) / 300.0, 0.0, 1.0)
	shadow.scale = Vector2.ONE * lerpf(1.0, 0.45, height)
	shadow.modulate.a = lerpf(1.0, 0.3, height)


## The yellow honk marks from the concept art, flicked out beside the beak.
class HonkMarks:
	extends Node2D

	func _draw() -> void:
		var col := Color("ffcf3f")
		var edge := Color("ff9a1f")
		var base := Vector2(46, -78)
		for i in 3:
			var ang := -1.0 + i * 0.5
			var dir := Vector2.from_angle(ang)
			var a := base + dir * 8.0
			var b := base + dir * 30.0
			var side := dir.orthogonal() * (5.0 + i)
			var pts := PackedVector2Array([a, b + side, b - side])
			draw_colored_polygon(pts, col)
			draw_polyline(PackedVector2Array([a, b + side, b - side, a]), edge, 2.0, true)
