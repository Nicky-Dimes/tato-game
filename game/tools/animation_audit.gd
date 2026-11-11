extends Node2D
## Real engine renders of every production cel, with common ground anchors.
## godot --path game res://tools/AnimationAudit.tscn -- --out=/absolute/QA

var _page: Node2D
var _out := "user://"

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(_out)
	for pack: String in ["tato", "garden", "guardians", "flyers", "bosses"]:
		_build_page(pack)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := _out.path_join("frames_%s.png" % pack)
		var error := get_viewport().get_texture().get_image().save_png(path)
		print("Animation audit: ", pack, " -> ", path, " (", error_string(error), ")")
		_page.queue_free()
		await get_tree().process_frame
	get_tree().quit()

func _build_page(pack: String) -> void:
	_page = Node2D.new()
	add_child(_page)
	var bg := ColorRect.new()
	bg.color = Color("eaf2ed")
	bg.size = Vector2(1280, 720)
	_page.add_child(bg)
	_text("TATO!  /  ANIMATION AUDIT  /  " + pack.to_upper(), Vector2(24, 16), 26)
	_text("Actual Godot 4.7.2 render. Tight sprite regions prevent neighboring frames from bleeding in.", Vector2(24, 51), 17)
	_text("Pose-comparison scale only. Gameplay: regular enemies 62–108px; bosses 170–215px.", Vector2(24, 74), 16)
	if pack == "tato":
		for frame in 20:
			var at := Vector2(135 + (frame % 5) * 247, 210 + (frame / 5) * 145)
			var texture := TatoVisual.frame_texture("cel_%d" % frame)
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.material = texture.get_meta("silhouette_material") if texture.has_meta("silhouette_material") else null
			sprite.centered = false
			if texture.has_meta("anchor"):
				sprite.offset = -Vector2(texture.get_meta("anchor"))
				sprite.scale = Vector2.ONE * 85 / float(texture.get_meta("body_height"))
			else:
				var ratio := texture.get_width() / TatoVisual.CANVAS
				sprite.offset = -TatoVisual.ANCHOR * ratio
				sprite.scale = Vector2.ONE * 85 / (texture.get_height() * 0.7)
			sprite.position = at
			_page.add_child(sprite)
			_text("%02d%s" % [frame, "  NEW" if frame >= 16 else ""], at + Vector2(-40, 8), 17)
		return
	var kinds: Array = ProductionArt.BOSS_IDS if pack == "bosses" else ProductionArt.ENEMY_PACKS[pack]
	for frame in 8:
		_text("%d%s" % [frame, " NEW" if frame >= 4 else ""], Vector2(304 + frame * 116, 103), 16)
	for row in kinds.size():
		var baseline := 197 + row * 79
		_text(str(kinds[row]), Vector2(20, baseline - 28), 18)
		var line := Line2D.new()
		line.width = 1
		line.default_color = Color("b5c8c0")
		line.points = PackedVector2Array([Vector2(275, baseline), Vector2(1260, baseline)])
		_page.add_child(line)
		for frame in 8:
			var texture := ProductionArt.boss_frame(kinds[row], frame) if pack == "bosses" else ProductionArt.enemy_frame(kinds[row], frame)
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.material = texture.get_meta("silhouette_material") if texture.has_meta("silhouette_material") else null
			sprite.centered = false
			sprite.offset = -Vector2(texture.get_meta("anchor"))
			sprite.scale = Vector2.ONE * 56 / float(texture.get_meta("body_height"))
			sprite.position = Vector2(330 + frame * 116, baseline)
			_page.add_child(sprite)

func _text(value: String, at: Vector2, font_size: int) -> void:
	var label := UITheme.label(value, font_size, UITheme.PLUM, true)
	label.position = at
	_page.add_child(label)
