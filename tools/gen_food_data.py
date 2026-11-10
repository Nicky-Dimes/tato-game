#!/usr/bin/env python3
"""Writes game/data/foods/*.tres and game/data/recipes/*.tres from the tables below.

The .tres files are the game's source of truth and can be edited by hand or in
the Godot inspector; this script only exists to (re)create the full set in one go.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOODS = os.path.join(ROOT, "game", "data", "foods")
RECIPES = os.path.join(ROOT, "game", "data", "recipes")


def col(hexs):
    hexs = hexs.lstrip("#")
    r, g, b = (int(hexs[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return "Color(%.4f, %.4f, %.4f, 1)" % (r, g, b)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


# id, name, ability, description, risk, color, accent, shape, cost, duration, cooldown, tags, world, adjective, noun, honk
FOOD_ROWS = [
    ("PEPPER", "Spicy Pepper", "Fire Honk", "A warm, crackly honk. Melts wax and ice, lights braziers and spins pinwheels.",
     "Too hot for ice bridges, and it wakes sleepy pollen.", "#F0452E", "#FFB81E", "flame", 14, 0.4, 0.45, ["heat", "honk"], 1, "Spicy", "Sizzle", "honk_fire"),
    ("BUBBLE", "Bubbleberry", "Bubble Float", "Tato puffs into a bubble and drifts up. Rides warm air even higher.",
     "Brambles pop the bubble.", "#58B8F5", "#C9B6FF", "ring", 18, 5.0, 0.6, ["bubble"], 1, "Bubbly", "Fizz", "honk_bubble"),
    ("HONEY", "Honeycomb", "Sticky Waddle", "Sticky feet! Waddle up walls and across ceilings.",
     "Water rinses the stickiness away.", "#F5A623", "#FFE08A", "hexagon", 18, 8.0, 0.5, ["sticky"], 2, "Sticky", "Goo", "honk_sticky"),
    ("MELON", "Watermelon", "Melon Roll", "Curl into a heavy melon ball. Smash crates, squash big buttons, zoom down slopes.",
     "Too round to fit through small gaps.", "#3FAE4A", "#F25A6E", "ball", 18, 8.0, 0.5, ["weight", "impact"], 2, "Juicy", "Rumble", "honk_melon"),
    ("FROST", "Frostberry", "Ice Slide", "A frosty honk that freezes water into ice, then a speedy belly slide.",
     "Heat melts ice again.", "#59D6E6", "#E8FBFF", "snowflake", 14, 0.4, 0.5, ["cold", "honk"], 3, "Frosty", "Chill", "honk_ice"),
    ("POPCORN", "Popcorn", "Pop Bounce", "Boing! Every landing pops Tato higher. Pops sealed pods too.",
     "Gusts push a bouncing goose around.", "#FFD84A", "#FFF6D0", "burst", 18, 7.0, 0.5, ["pop", "impact"], 3, "Poppin'", "Pop", "honk_pop"),
    ("NOODLE", "Stretchy Noodles", "Noodle Neck", "Streeetch! Reach far handles, levers and treats through small openings.",
     "Tato stands still for a moment while stretching.", "#F2C879", "#E8743B", "spiral", 10, 0.6, 0.35, ["reach"], 4, "Noodly", "Twirl", "honk_noodle"),
    ("CITRUS", "Zesty Citrus", "Flash Zing", "A bright zing of light. Wakes mirrors, lamps and hidden ink.",
     "Needs a clear line of sight.", "#FF9A1F", "#FFF27A", "sun", 14, 0.5, 0.55, ["light", "honk"], 4, "Zesty", "Zing", "honk_zing"),
    ("MINT", "Moonmint", "Quiet Honk", "Shhh. Soft feet and a hush-honk that calms jumpy creatures.",
     "Only lasts a little while.", "#3CCFB4", "#D4FFF4", "moon", 14, 8.0, 0.5, ["quiet"], 5, "Minty", "Hush", "honk_quiet"),
    ("JAM", "Starberry Jam", "Jam Trail", "Paint sketched outlines with jam to make them real for a while.",
     "Rain washes jam away.", "#E0389A", "#FFC2E4", "star", 18, 7.0, 0.5, ["paint"], 5, "Jammy", "Smear", "honk_jam"),
    ("TRUFFLE", "Thunder Truffle", "Drumbeat Honk", "Hold to charge a deep BOOM that shakes heavy bells and big machines.",
     "Takes a moment to charge.", "#7A4FCF", "#FFE34D", "drum", 22, 0.9, 0.8, ["resonance", "honk"], 6, "Thundery", "Boom", "honk_boom"),
    ("PASTRY", "Cloud Puff Pastry", "Feathercloud", "Puff out a soft little cloud to stand on.",
     "Clouds melt away in wind.", "#FFF1DC", "#F7B7C8", "cloud", 14, 5.0, 0.45, ["cloud"], 6, "Fluffy", "Puff", "honk_puff"),
]

# id, a, b, name, description, color, accent, cost, duration, cooldown, tags
RECIPE_ROWS = [
    ("STEAM_LIFT", "PEPPER", "BUBBLE", "Steam Lift", "A hot bubble that whooshes Tato (and light things) straight up.", "#FF8A5C", "#BFE9FF", 32, 2.6, 0.8, ["heat", "bubble", "lift"]),
    ("CARAMEL_COAT", "PEPPER", "HONEY", "Caramel Coat", "Squirt a stream of honey and bake it into a crunchy bridge.", "#C8742A", "#FFD27A", 32, 8.0, 0.8, ["heat", "sticky", "bridge"]),
    ("TAFFY_BALLOON", "BUBBLE", "HONEY", "Taffy Balloon", "A stretchy taffy line that tugs hanging platforms closer.", "#FF9EC4", "#FFE08A", 30, 5.0, 0.8, ["bubble", "sticky", "pull"]),
    ("STICKY_BOWLING", "HONEY", "MELON", "Sticky Bowling", "A sticky melon ball that rolls up walls and around loops.", "#9BC53D", "#F5A623", 36, 8.0, 0.8, ["weight", "impact", "sticky"]),
    ("SNOWBALL_EXPRESS", "FROST", "MELON", "Snowball Express", "A giant chilly snowball that freezes water and stops belts.", "#BFEFFF", "#3FAE4A", 36, 8.0, 0.8, ["weight", "impact", "cold"]),
    ("FROST_POP", "FROST", "POPCORN", "Frost Pop", "Rapid bounces that freeze puddles wherever Tato lands.", "#A5F0FF", "#FFD84A", 32, 7.0, 0.8, ["pop", "cold"]),
    ("BUBBLE_POP_JET", "BUBBLE", "POPCORN", "Bubble Pop Jet", "Pop-pop-pop! Several bursts of lift in mid-air.", "#8AD4FF", "#FFE98A", 32, 6.0, 0.8, ["pop", "bubble", "lift"]),
    ("TETHER_NOODLE", "HONEY", "NOODLE", "Tether Noodle", "Stick a noodle to a swing ring and swoosh across.", "#F2C879", "#F5A623", 28, 6.0, 0.6, ["reach", "sticky", "swing"]),
    ("PRISM_CHILL", "CITRUS", "FROST", "Prism Chill", "Freeze a sparkling prism that bends light beams.", "#BFF5FF", "#FFF27A", 32, 12.0, 0.8, ["cold", "light", "prism"]),
    ("QUIET_INK", "JAM", "MINT", "Quiet Ink", "Paint secret moonlit paths while staying hush-quiet and unseen.", "#7C5AD9", "#3CCFB4", 32, 8.0, 0.8, ["quiet", "paint", "stealth"]),
    ("THUNDERCLOUD", "PASTRY", "TRUFFLE", "Thundercloud", "Ride a rumbling cloud whose booms wake giant bells.", "#8E7BD6", "#FFF1DC", 38, 8.0, 1.0, ["cloud", "resonance"]),
    ("SUNBEAM_STEPS", "CITRUS", "PASTRY", "Sunbeam Steps", "Sunlight makes hidden cloud steps solid for a moment.", "#FFE27A", "#FFF7E8", 32, 7.0, 0.8, ["light", "cloud", "reveal"]),
]


def tags(arr):
    return "PackedStringArray(%s)" % ", ".join('"%s"' % t for t in arr)


def write_food(row):
    (fid, name, ability, desc, risk, color, accent, shape, cost, dur, cd, tg, world, adj, noun, honk) = row
    low = fid.lower()
    text = """[gd_resource type="Resource" script_class="FoodDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/food/food_definition.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"%s"
display_name = "%s"
ability_name = "%s"
description = "%s"
risk = "%s"
color = %s
accent = %s
icon_path = "res://assets/sprites/foods/%s.svg"
shape_hint = "%s"
ability_script = "res://scripts/food/abilities/%s.gd"
charge_cost = %.1f
duration = %.2f
cooldown = %.2f
tags = %s
unlock_world = %d
blend_adjective = "%s"
blend_noun = "%s"
honk_sound = "%s"
""" % (fid, esc(name), esc(ability), esc(desc), esc(risk), col(color), col(accent), low, shape, low,
       cost, dur, cd, tags(tg), world, esc(adj), esc(noun), honk)
    with open(os.path.join(FOODS, low + ".tres"), "w") as f:
        f.write(text)


def write_recipe(row):
    (rid, a, b, name, desc, color, accent, cost, dur, cd, tg) = row
    a, b = sorted([a, b])
    low = rid.lower()
    text = """[gd_resource type="Resource" script_class="RecipeDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/food/recipe_definition.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"%s"
food_a = &"%s"
food_b = &"%s"
display_name = "%s"
description = "%s"
color = %s
accent = %s
ability_script = "res://scripts/food/abilities/%s.gd"
charge_cost = %.1f
duration = %.2f
cooldown = %.2f
tags = %s
named = true
icon_path = "res://assets/sprites/recipes/%s.svg"
""" % (rid, a, b, esc(name), esc(desc), col(color), col(accent), low, cost, dur, cd, tags(tg), low)
    with open(os.path.join(RECIPES, low + ".tres"), "w") as f:
        f.write(text)


def main():
    os.makedirs(FOODS, exist_ok=True)
    os.makedirs(RECIPES, exist_ok=True)
    for r in FOOD_ROWS:
        write_food(r)
    for r in RECIPE_ROWS:
        write_recipe(r)
    print("wrote %d foods, %d recipes" % (len(FOOD_ROWS), len(RECIPE_ROWS)))


if __name__ == "__main__":
    main()
