#!/usr/bin/env python3
"""Writes game/data/foods/*.tres (the twelve attack power-ups) from the table
below. The .tres files are the game's data and can be edited by hand or in
the Godot inspector; this script only recreates the full set in one go."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOODS = os.path.join(ROOT, "game", "data", "foods")


def col(hexs):
    hexs = hexs.lstrip("#")
    r, g, b = (int(hexs[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return "Color(%.4f, %.4f, %.4f, 1)" % (r, g, b)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


# id, name, attack, description, color, accent, damage, cooldown, duration, element, world, adjective, noun, honk
ROWS = [
    ("FIRE_PEPPER", "Fire Pepper", "Fire Shot", "Spits a fireball that flies straight ahead. Melts ice and lights torches.", "#F0452E", "#FFB81E", 1, 0.34, 0.2, "fire", 1, "Spicy", "Sizzle", "honk_fire"),
    ("BUBBLEBERRY", "Bubbleberry", "Bubble Trap", "Blows bubbles that catch creatures and float them away.", "#B58CF5", "#E9DBFF", 1, 0.45, 0.2, "bubble", 1, "Bubbly", "Fizz", "honk_bubble"),
    ("WATERMELON", "Watermelon", "Multi Shot", "Three melon slices fan out at once. Great against a crowd.", "#3FAE4A", "#F25A6E", 1, 0.5, 0.2, "melon", 2, "Juicy", "Rumble", "honk_melon"),
    ("HONEYCOMB", "Honeycomb", "Honey Shot", "A gooey glob of honey. Sticks creatures in place so they cannot move.", "#F5A623", "#FFE08A", 1, 0.45, 0.2, "honey", 2, "Sticky", "Goo", "honk_sticky"),
    ("POPCORN", "Popcorn", "Pop Shot", "Pops a burst of kernels up and out in an arc. Hits things above too.", "#FFD84A", "#FFF6D0", 1, 0.5, 0.2, "pop", 3, "Poppin'", "Pop", "honk_pop"),
    ("NOODLE", "Noodle", "Noodle Whip", "A long noodle whip. Reaches far and snaps through everything it touches.", "#F2C879", "#E8743B", 1, 0.4, 0.25, "whip", 3, "Noodly", "Twirl", "honk_noodle"),
    ("FROSTBERRY", "Frostberry", "Freeze Shot", "Icy shards freeze creatures solid. Frozen ones make handy steps, and water turns to ice.", "#59B6F0", "#E8FBFF", 1, 0.4, 0.2, "ice", 4, "Frosty", "Chill", "honk_ice"),
    ("COCOA_SHIELD", "Cocoa Shield", "Shield Guard", "A warm cocoa bubble. Nothing hurts Tato inside it, and shots bounce back.", "#8A5A3C", "#FFD9A8", 1, 2.4, 2.2, "shield", 4, "Cozy", "Guard", "honk_puff"),
    ("GARLIC_DASH", "Garlic Dash", "Dash Attack", "Zoom! A speedy dash that bowls through creatures and crates.", "#F3EDF7", "#C9B6FF", 2, 0.75, 0.3, "dash", 5, "Zippy", "Zoom", "honk_zing"),
    ("THUNDER_CORN", "Thunder Corn", "Lightning Shot", "A crackling bolt that jumps from creature to creature.", "#FFE34D", "#7A4FCF", 1, 0.55, 0.2, "shock", 5, "Thundery", "Zap", "honk_boom"),
    ("LEMON_BEAM", "Lemon Beam", "Laser Beam", "A bright beam that goes through everything in a line.", "#FFE94A", "#FFF7B0", 1, 0.6, 0.25, "light", 6, "Zesty", "Zing", "honk_zing"),
    ("TOMATO_BOMB", "Tomato Bomb", "Bomb Blast", "Lobs a tomato that goes SPLAT in a big blast. Breaks cracked walls.", "#E0392E", "#FF9A1F", 3, 0.8, 0.2, "blast", 6, "Saucy", "Splat", "honk_boom"),
]


def write_food(row):
    (fid, name, attack, desc, color, accent, dmg, cd, dur, element, world, adj, noun, honk) = row
    low = fid.lower()
    text = """[gd_resource type="Resource" script_class="FoodDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/food/food_definition.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"%s"
display_name = "%s"
ability_name = "%s"
description = "%s"
color = %s
accent = %s
icon_path = "res://assets/sprites/powers/%s.png"
demo_path = "res://assets/sprites/cards/demo_%s.png"
ability_script = "res://scripts/food/abilities/%s.gd"
damage = %d
cooldown = %.2f
duration = %.2f
element = &"%s"
unlock_world = %d
blend_adjective = "%s"
blend_noun = "%s"
honk_sound = "%s"
tags = PackedStringArray("%s")
""" % (fid, esc(name), esc(attack), esc(desc), col(color), col(accent), low, low, low, dmg, cd, dur, element, world, esc(adj), esc(noun), honk, element)
    with open(os.path.join(FOODS, low + ".tres"), "w") as f:
        f.write(text)


def main():
    os.makedirs(FOODS, exist_ok=True)
    for r in ROWS:
        write_food(r)
    print("wrote %d power-ups" % len(ROWS))


if __name__ == "__main__":
    main()
