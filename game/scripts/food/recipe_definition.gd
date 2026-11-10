class_name RecipeDefinition
extends Resource
## A fusion of two foods. food_a/food_b are stored in canonical (sorted) order
## so A+B and B+A always resolve to the same recipe.

@export var id: StringName = &""
@export var food_a: StringName = &""
@export var food_b: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var color: Color = Color.WHITE
@export var accent: Color = Color.WHITE
@export var ability_script: String = ""
@export var charge_cost: float = 35.0
@export var duration: float = 4.0
@export var cooldown: float = 0.8
@export var tags: PackedStringArray = PackedStringArray()
## True for the twelve signature recipes; false for generated "experiments".
@export var named: bool = true
@export var icon_path: String = ""


static func canonical_pair(a: StringName, b: StringName) -> String:
	var names: Array[String] = [String(a), String(b)]
	names.sort()
	return names[0] + "|" + names[1]


func pair_key() -> String:
	return canonical_pair(food_a, food_b)
