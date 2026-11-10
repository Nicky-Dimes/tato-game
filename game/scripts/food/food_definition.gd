class_name FoodDefinition
extends Resource
## One attack power-up (a magical food). Tato holds one at a time: picking up
## a new one replaces the old one. Everything about a power is data here,
## plus one small attack script.

@export var id: StringName = &""
@export var display_name: String = ""
## Name of the attack ("Fire Shot", "Bubble Trap" ...).
@export var ability_name: String = ""
@export_multiline var description: String = ""
@export var color: Color = Color.WHITE
@export var accent: Color = Color.WHITE
## Icon cut from the Item & Power-Up board (also the pickup picture).
@export var icon_path: String = ""
## "Action demo" strip from the same board, shown in the notebook.
@export var demo_path: String = ""
## Script path of the AbilityStrategy that performs the attack.
@export var ability_script: String = ""
@export var damage: int = 1
## Seconds between attacks.
@export var cooldown: float = 0.4
## Seconds a held / lasting attack stays out (shield, dash ...).
@export var duration: float = 0.3
## What kind of hit it is: fire, ice, bubble, honey, melon, pop, whip, shock, blast, dash, light, shield.
@export var element: StringName = &"plain"
@export var unlock_world: int = 1
## Words used to name the Flavor Burst when this power meets another.
@export var blend_adjective: String = ""
@export var blend_noun: String = ""
@export var honk_sound: String = "honk"
## Kept so older tools can read the list of world tags a power sends.
@export var tags: PackedStringArray = PackedStringArray()
@export var charge_cost: float = 0.0
