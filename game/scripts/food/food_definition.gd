class_name FoodDefinition
extends Resource
## One magical ingredient. Everything the game needs to know about a food
## lives here, so adding a food is a data change plus one ability script.

@export var id: StringName = &""
@export var display_name: String = ""
@export var ability_name: String = ""
@export_multiline var description: String = ""
@export_multiline var risk: String = ""
## Main tint used by the HUD, VFX and Tato's feather glow.
@export var color: Color = Color.WHITE
@export var accent: Color = Color.WHITE
## Icon texture path (also the pickup sprite).
@export var icon_path: String = ""
## Colour-blind friendly silhouette word shown with the icon ("flame", "ring"...).
@export var shape_hint: String = ""
## Script path of the AbilityStrategy that implements the power.
@export var ability_script: String = ""
@export var charge_cost: float = 15.0
## Seconds the power stays active (toggle powers) or the pulse lasts.
@export var duration: float = 0.4
@export var cooldown: float = 0.5
## Interaction tags the power sends into the world (heat, cold, light ...).
@export var tags: PackedStringArray = PackedStringArray()
@export var unlock_world: int = 1
## Short adjective / noun used to name unlisted "experiment" blends.
@export var blend_adjective: String = ""
@export var blend_noun: String = ""
## Honk sound flavour.
@export var honk_sound: String = "honk"
