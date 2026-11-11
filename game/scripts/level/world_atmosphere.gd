class_name WorldAtmosphere
extends Node2D
## Reproducible, world-specific decorative life on real terrain surfaces.
## Draws only near the camera; no collisions, no obstructive props, no asset-cutout sprites.
## Reduced Motion freezes all swaying, floats and sparkle cycles.

var level: Level
var details: Array[Dictionary] = []
var time := 0.0
var ambient_motes: Array[Dictionary] = []
var grass_surface_rows: Array[Vector2] = []
var grass_fringe_tex: Texture2D
var _palette: Array[Color] = [Color("b5e26c"), Color("fff4b3"), Color("f5a5c6")]
var _theme := "grassland"

func setup(lv: Level) -> void:
    level = lv
    _theme = lv.theme
    name = "LivingScenery"
    z_index = 0 # Decoration stays behind the player and all enemies.
    if Game.headless_test or DisplayServer.get_name() == "headless":
        set_process(false)
        return
    match _theme:
        "orchard": _palette = [Color("74b74b"), Color("ffe4a0"), Color("f39f97")]
        "candy": _palette = [Color("f8a3e2"), Color("fff1a8"), Color("a68bf5")]
        "icy": _palette = [Color("8ad8f5"), Color("ffffff"), Color("9db4fb")]
        "windy": _palette = [Color("85d8bc"), Color("fce79e"), Color("f5b3c1")]
        "castle": _palette = [Color("b5a0ed"), Color("f8de95"), Color("8fd2b2")]
        "nest": _palette = [Color("86d8b9"), Color("f8e8ae"), Color("edb5bf")]
    var rng := RandomNumberGenerator.new()
    rng.seed = 2317 + lv.level_id.hash()
    # Subtle world-space particles are not UI stickers. They are deterministic,
    # depth-sorted and move independently of gameplay, then stop with Reduced Motion.
    for i in 90:
        ambient_motes.append({
            "x": rng.randf_range(0.0, lv.data.pixel_size().x),
            "y": rng.randf_range(0.0, lv.data.pixel_size().y),
            "phase": rng.randf_range(0.0, TAU),
            "size": rng.randf_range(0.65, 1.5),
            "speed": rng.randf_range(0.2, 0.85),
            "layer": rng.randi_range(0, 2),
        })
    var map := lv.data
    if _theme == "grassland":
        grass_fringe_tex = load("res://assets/sprites/bg/grassland_grass_fringe.png") as Texture2D
    for x in range(1, map.width - 1):
        for y in range(1, map.height):
            if not map.is_full_block(x, y) or map.cell(x, y - 1) != LevelData.AIR:
                continue
            if _theme == "grassland" and x % 4 == 0:
                grass_surface_rows.append(Vector2(x * 64.0, y * 64.0))
            if rng.randf() > 0.62:
                continue
            var t := rng.randi_range(0, 5)
            var at := Vector2((x + rng.randf_range(0.24, 0.76)) * 64.0, y * 64.0)
            details.append({"pos": at, "kind": t, "phase": rng.randf_range(0.0, TAU), "size": rng.randf_range(0.8, 1.4), "palette": rng.randi_range(0, 2)})

func _process(delta: float) -> void:
    if level == null or level.player == null:
        return
    if not Settings.flag("reduced_motion"):
        time += delta
    if Engine.get_process_frames() % 4 == 0:
        queue_redraw()

func _draw() -> void:
    if level == null or level.player == null:
        return
    var near_x := level.player.global_position.x
    _draw_ambient_life(near_x)
    if grass_fringe_tex != null:
        for loc in grass_surface_rows:
            if absf(loc.x - near_x) < 960.0:
                draw_texture(grass_fringe_tex, loc + Vector2(0, -14))
    for d in details:
        var p: Vector2 = d["pos"]
        if absf(p.x - near_x) > 850.0:
            continue
        var scale_val: float = d["size"]
        var phase: float = d["phase"]
        var sway := sin(time * 1.6 + phase) * 2.5
        var color: Color = _palette[d["palette"]]
        match int(d["kind"]):
            0: _grass(p, scale_val, sway, color)
            1: _flower(p, scale_val, sway, color)
            2: _theme_feature(p, scale_val, sway, color, phase)
            3: _sparkle(p, scale_val, sway, color, phase)
            4: _bush(p, scale_val, sway, color)
            5: _theme_feature(p, scale_val * 0.7, sway, color, phase + 1.8)

func _grass(p: Vector2, s: float, sway: float, tint: Color) -> void:
    var stem := Color("368653") if _theme != "icy" else Color("a1d5e8")
    for j in 5:
        var sx := (float(j) - 2.0) * 3.5 * s
        var height := (12.0 + float(j % 3) * 6.0) * s
        draw_line(p + Vector2(sx, 0), p + Vector2(sx * 1.65 + sway, -height), stem.lerp(tint, 0.35), 2.7 * s, true)
    draw_arc(p + Vector2(0, -1), 11 * s, 0.25, PI - 0.25, 10, Color("254d3b", 0.36), 1.2, true)

func _flower(p: Vector2, s: float, sway: float, tint: Color) -> void:
    var center := p + Vector2(sway, -19.0 * s)
    var stem := Color("519451") if _theme != "icy" else Color("79b6da")
    draw_line(p, center, Color("254c40", 0.6), 4.0 * s, true)
    draw_line(p, center, stem, 2.6 * s, true)
    for k in 2:
        var leaf := p + Vector2(-7 if k == 0 else 7, -8 if k == 0 else -13)
        draw_circle(leaf + Vector2(sway * 0.4, 0), 4 * s, stem)
    for a in 6:
        var q := center + Vector2.from_angle(float(a) * TAU / 6.0) * (6.0 * s)
        draw_circle(q + Vector2(0, 1.2 * s), 5.6 * s, Color("3a2651", 0.35))
        draw_circle(q, 5.3 * s, tint)
        draw_circle(q + Vector2(-1.3 * s, -1.6 * s), 1.7 * s, Color(1, 1, 1, 0.5))
    draw_circle(center, 5.0 * s, Color("ffcc55"))
    draw_circle(center + Vector2(-1.2, -1.2) * s, 1.6 * s, Color("fff7c9"))

func _bush(p: Vector2, s: float, sway: float, tint: Color) -> void:
    if _theme == "icy":
        _snowdrift(p, s, tint)
        return
    var deep := Color("345b4d") if _theme != "candy" else Color("a34a9b")
    for j in 5:
        var ox := (float(j) - 2.0) * 7.0 * s
        var oy := -8.0 * s - absf(2.0 - float(j)) * 2.0 * s
        draw_circle(p + Vector2(ox, oy + 3 * s), (10.0 + (j % 2) * 3) * s, deep)
        draw_circle(p + Vector2(ox + sway * 0.3, oy), (9.0 + (j % 2) * 3) * s, Color("448e60").lerp(tint, 0.44))
        draw_circle(p + Vector2(ox - 3 * s, oy - 3 * s), 3.5 * s, Color(1, 1, 1, 0.22))
    if _theme == "orchard":
        draw_circle(p + Vector2(-8 * s, -18 * s), 4.5 * s, Color("eb4a51"))
        draw_circle(p + Vector2(9 * s, -15 * s), 4.5 * s, Color("e85943"))

func _theme_feature(p: Vector2, s: float, sway: float, tint: Color, phase: float) -> void:
    match _theme:
        "candy":
            # Individually striped sugar drops, grounded in the level rather than UI stickers.
            var top := p + Vector2(sway, -26 * s)
            draw_line(p, top, Color("62375d"), 5 * s, true)
            draw_line(p, top, Color("fff8e8"), 3 * s, true)
            draw_circle(top + Vector2(0, 1.2 * s), 12 * s, Color("633d75"))
            draw_circle(top, 10.5 * s, tint)
            for k in 5:
                var a := float(k) * TAU / 5.0 + phase
                draw_line(top, top + Vector2.from_angle(a) * 9.5 * s, Color("fff7e8"), 2.0 * s, true)
            draw_circle(top, 3.5 * s, Color("fff2bd"))
        "icy":
            var tip := p + Vector2(sway, -32 * s)
            var verts := PackedVector2Array([p + Vector2(-12 * s, 0), p + Vector2(-5 * s, -22 * s), tip, p + Vector2(10 * s, -9 * s), p + Vector2(12 * s, 0)])
            draw_colored_polygon(verts, Color("4277b1"))
            var face := PackedVector2Array([p + Vector2(-5 * s, -2 * s), p + Vector2(-3 * s, -19 * s), tip, p + Vector2(3 * s, -2 * s)])
            draw_colored_polygon(face, Color("8ad8f2"))
            draw_line(p + Vector2(-3 * s, -18 * s), tip, Color("f4ffff"), 2 * s, true)
        "windy":
            var middle := p + Vector2(0, -25 * s)
            draw_line(p, middle, Color("38645d"), 3 * s, true)
            draw_circle(middle, 3.7 * s, Color("efb848"))
            for i in 4:
                var a := float(i) * PI / 2.0 + time * 1.5 + phase
                var v := Vector2.from_angle(a)
                var wing := PackedVector2Array([middle, middle + v * 15 * s + v.orthogonal() * 4 * s, middle + v * 18 * s - v.orthogonal() * 4 * s])
                draw_colored_polygon(wing, tint)
        "castle":
            # Small flag among grasses, with gold edge and darker pole.
            draw_line(p, p + Vector2(0, -32 * s), Color("423458"), 4 * s, true)
            draw_line(p, p + Vector2(0, -32 * s), Color("f3d179"), 2 * s, true)
            var flag := PackedVector2Array([p + Vector2(1, -30) * s, p + Vector2(22 + sway, -24) * s, p + Vector2(1, -17) * s])
            draw_colored_polygon(flag, tint)
            draw_circle(p + Vector2(0, -34 * s), 3 * s, Color("ffde80"))
        "orchard":
            draw_line(p, p + Vector2(sway, -17 * s), Color("5b873d"), 3.2 * s, true)
            draw_circle(p + Vector2(sway, -18 * s), 9.2 * s, Color("9b233c"))
            draw_circle(p + Vector2(sway - 1.0 * s, -20 * s), 8.0 * s, Color("f35a52"))
            draw_circle(p + Vector2(sway - 3.5 * s, -23 * s), 2.4 * s, Color(1, 1, 1, 0.55))
            draw_circle(p + Vector2(sway + 6 * s, -29 * s), 5 * s, Color("65b44d"))
        _:
            _flower(p, s * 0.82, sway, tint)

func _snowdrift(p: Vector2, s: float, tint: Color) -> void:
    draw_circle(p + Vector2(-10 * s, -4 * s), 11 * s, Color("7fafd4"))
    draw_circle(p + Vector2(7 * s, -5 * s), 12 * s, Color("8cbce0"))
    draw_circle(p + Vector2(-11 * s, -7 * s), 10 * s, tint)
    draw_circle(p + Vector2(7 * s, -8 * s), 11 * s, Color("e9f9ff"))

func _sparkle(p: Vector2, s: float, sway: float, tint: Color, phase: float) -> void:
    var alpha := 0.45 + 0.25 * sin(time * 2.5 + phase)
    var q := p + Vector2(sway, -16.0 * s - 3 * sin(time * 1.3 + phase))
    draw_circle(q, 2.7 * s, Color(tint.r, tint.g, tint.b, alpha))
    draw_line(q + Vector2(-6, 0) * s, q + Vector2(6, 0) * s, Color(1, 1, 1, alpha), 1.3 * s, true)
    draw_line(q + Vector2(0, -6) * s, q + Vector2(0, 6) * s, Color(1, 1, 1, alpha), 1.3 * s, true)


# Airborne foliage, icy snow, carnival glitter and glowing courtyard motes.
# Lives in world coordinates and is culled outside the camera's neighborhood.
func _draw_ambient_life(near_x: float) -> void:
    var motion := 0.0 if Settings.flag("reduced_motion") else time
    for mote in ambient_motes:
        var x: float = mote["x"]
        var y: float = mote["y"]
        var ph: float = mote["phase"]
        var size_factor: float = mote["size"]
        var speed_factor: float = mote["speed"]
        var layer_index: int = mote["layer"]
        var drift := motion * (14.0 + float(layer_index) * 10.0) * speed_factor
        var dx := fposmod(x + drift + sin(motion * 0.6 + ph) * 8.0, maxf(level.data.pixel_size().x, 1.0))
        if absf(dx - near_x) > 760.0:
            continue
        var dy := y + sin(motion * (0.7 + speed_factor) + ph) * (6.0 + 7.0 * size_factor)
        var pos := Vector2(dx, dy)
        var opacity := 0.28 + 0.14 * float(layer_index)
        match _theme:
            "icy":
                var snow_color := Color(0.94, 0.98, 1.0, opacity + 0.1)
                draw_circle(pos, 2.2 * size_factor, snow_color)
                draw_line(pos + Vector2(-3, 0) * size_factor, pos + Vector2(3, 0) * size_factor, snow_color, 0.7, true)
            "candy":
                var pastel := _palette[layer_index]
                var tint := Color(pastel.r, pastel.g, pastel.b, opacity)
                draw_circle(pos, 2.7 * size_factor, tint)
                draw_circle(pos + Vector2(-0.6, -0.9) * size_factor, 1.0 * size_factor, Color(1, 1, 1, opacity))
            "castle":
                var glow := 0.6 + 0.4 * sin(motion * 2.0 + ph)
                draw_circle(pos, 4.0 * size_factor, Color(1, 0.75, 0.35, opacity * glow * 0.42))
                draw_circle(pos, 1.7 * size_factor, Color(1, 0.93, 0.66, opacity * glow))
            _:
                # Leaves have a pointed, irregular silhouette instead of round dots.
                var leaf_color := Color("bde770") if _theme == "grassland" else Color("f8b66d") if _theme == "orchard" else Color("d4e7a3")
                if _theme == "windy":
                    leaf_color = Color("d4fa94")
                leaf_color.a = opacity
                var wobble := sin(motion * 2.2 + ph) * 3.5 * size_factor
                var v := PackedVector2Array([
                    pos + Vector2(-5, 0) * size_factor,
                    pos + Vector2(wobble, -2.6) * size_factor,
                    pos + Vector2(5, 0) * size_factor,
                    pos + Vector2(wobble, 2.4) * size_factor,
                ])
                draw_colored_polygon(v, leaf_color)
                draw_line(v[0], v[2], Color(1, 1, 1, opacity * 0.45), 0.7, true)
