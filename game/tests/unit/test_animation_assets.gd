extends TestCase
## Export/integration contract for all 28 characters, including the 112 added cels.

func _valid_cel(texture: Texture2D, label: String, anchored: bool = true) -> void:
	check(texture != null, label + " exists")
	if texture == null:
		return
	check(texture.get_width() > 8 and texture.get_height() > 8, label + " has usable dimensions")
	if texture is AtlasTexture:
		var rect: Rect2 = texture.region
		check(rect.position.x >= 0 and rect.position.y >= 0, label + " starts inside atlas")
		check(rect.end.x <= texture.atlas.get_width() + 0.1 and rect.end.y <= texture.atlas.get_height() + 0.1, label + " ends inside atlas")
	if anchored:
		check(texture.has_meta("anchor") and texture.has_meta("body_height"), label + " has normalization metadata")
		check(texture.has_meta("silhouette_material"), label + " isolates its own silhouette")
		if texture.has_meta("anchor"):
			var anchor: Vector2 = texture.get_meta("anchor")
			check(anchor.x >= 0 and anchor.y >= 0 and anchor.x <= texture.get_width() + 1 and anchor.y <= texture.get_height() + 1, label + " anchor stays inside cel")


func test_all_character_cels_load_with_valid_regions_and_anchors() -> void:
	for frame in 20:
		_valid_cel(TatoVisual.frame_texture("cel_%d" % frame), "Tato %d" % frame, frame >= 16)
	for pack: String in ProductionArt.ENEMY_PACKS:
		for kind: String in ProductionArt.ENEMY_PACKS[pack]:
			for frame in 8:
				_valid_cel(ProductionArt.enemy_frame(kind, frame), "%s %d" % [kind, frame])
	for kind: String in ProductionArt.BOSS_IDS:
		for frame in 8:
			_valid_cel(ProductionArt.boss_frame(kind, frame), "%s %d" % [kind, frame])


func test_golem_frame_size_and_boss_gameplay_scale() -> void:
	var largest_regular := 0.0
	for kind: String in EnemyData.kinds():
		for frame in 8:
			var texture := ProductionArt.enemy_frame(kind, frame)
			var pixels := float(EnemyData.stat(kind, "h")) * float(texture.get_meta("ink_height")) / float(texture.get_meta("body_height"))
			largest_regular = maxf(largest_regular, pixels)
	for frame in 8:
		var texture := ProductionArt.enemy_frame("rock_golem", frame)
		var pixels := 86.0 * float(texture.get_meta("ink_height")) / float(texture.get_meta("body_height"))
		check_near(pixels, 86.0, 86.0 * 0.12, "Rock Golem cel %d keeps its gameplay size" % frame)
	for kind: String in ProductionArt.BOSS_IDS:
		for frame in 8:
			var texture := ProductionArt.boss_frame(kind, frame)
			var pixels := float(Boss.DATA[kind]["h"]) * float(texture.get_meta("ink_height")) / float(texture.get_meta("body_height"))
			check_gt(pixels, largest_regular, "%s cel %d is taller than every regular enemy" % [kind, frame])
