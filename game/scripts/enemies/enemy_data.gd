class_name EnemyData
extends RefCounted
## Every creature from the Enemy & Boss Concept Bible as data. `arch` picks
## the behaviour script (walker / flyer / mole); the rest tunes it.
##   hp        hits to defeat          speed    px per second
##   h         height on screen (px)   faces    which way the drawing looks (1 right, -1 left)
##   stomp     can be jumped on        coins    dropped when defeated
##   immune    elements that do nothing      weak   elements that count double

const STATS := {
	# --- ground ---
	"mushroom_hopper": {"name": "Mushroom Hopper", "role": "Bouncing", "arch": "walker", "hp": 1, "speed": 70.0, "h": 80.0, "hop": 430.0, "stomp": true, "coins": 1},
	"slime_blob": {"name": "Slime Blob", "role": "Ground", "arch": "walker", "hp": 1, "speed": 42.0, "h": 62.0, "stomp": true, "coins": 1},
	"fire_slime": {"name": "Fire Slime", "role": "Special", "arch": "walker", "hp": 2, "speed": 50.0, "h": 62.0, "stomp": false, "coins": 2, "immune": ["fire"], "weak": ["ice"], "hot": true},
	"ice_slime": {"name": "Ice Slime", "role": "Special", "arch": "walker", "hp": 2, "speed": 50.0, "h": 62.0, "stomp": true, "coins": 2, "immune": ["ice"], "weak": ["fire"]},
	"shock_slime": {"name": "Shock Slime", "role": "Special", "arch": "walker", "hp": 2, "speed": 50.0, "h": 62.0, "stomp": false, "coins": 2, "immune": ["shock"], "zap": 2.6},
	"apple_chomper": {"name": "Apple Chomper", "role": "Ground", "arch": "walker", "hp": 2, "speed": 62.0, "h": 86.0, "stomp": true, "coins": 2, "lunge": 300.0},
	"hedgehog_roller": {"name": "Hedgehog Roller", "role": "Special", "arch": "walker", "hp": 2, "speed": 60.0, "h": 74.0, "faces": -1, "stomp": false, "coins": 2, "roll": 270.0},
	"turtle_tank": {"name": "Turtle Tank", "role": "Armored", "arch": "walker", "hp": 4, "speed": 40.0, "h": 78.0, "faces": -1, "stomp": true, "coins": 3, "shell": true},
	"crab_snipper": {"name": "Crab Snipper", "role": "Ground", "arch": "walker", "hp": 2, "speed": 120.0, "h": 70.0, "stomp": true, "coins": 2, "scuttle": true},
	"onion_knight": {"name": "Onion Knight", "role": "Armored", "arch": "walker", "hp": 2, "speed": 56.0, "h": 82.0, "faces": 1, "stomp": true, "coins": 2, "guard": true},
	"rock_golem": {"name": "Rock Golem", "role": "Armored", "arch": "walker", "hp": 5, "speed": 30.0, "h": 108.0, "stomp": true, "coins": 5, "heavy": true, "pound": 3.0},
	# --- ranged ---
	"carrot_archer": {"name": "Carrot Archer", "role": "Ranged", "arch": "walker", "hp": 1, "speed": 0.0, "h": 80.0, "faces": 1, "stomp": true, "coins": 2, "shot": "arrow", "every": 2.3, "range": 540.0},
	"pepper_goblin": {"name": "Pepper Goblin", "role": "Ranged", "arch": "walker", "hp": 2, "speed": 60.0, "h": 82.0, "faces": 1, "stomp": true, "coins": 2, "shot": "fire", "every": 2.5, "range": 360.0, "immune": ["fire"]},
	"ice_puffin": {"name": "Ice Puffin", "role": "Ranged", "arch": "walker", "hp": 2, "speed": 90.0, "h": 78.0, "faces": 1, "stomp": true, "coins": 2, "shot": "snow", "every": 2.7, "range": 460.0, "immune": ["ice"]},
	"candy_imp": {"name": "Candy Imp", "role": "Ranged", "arch": "walker", "hp": 2, "speed": 70.0, "h": 80.0, "stomp": true, "coins": 2, "shot": "candy", "every": 2.3, "range": 420.0, "hop": 380.0},
	"mole_digger": {"name": "Mole Digger", "role": "Sneaky", "arch": "mole", "hp": 2, "speed": 0.0, "h": 78.0, "stomp": true, "coins": 2, "shot": "rock", "every": 2.2, "range": 360.0},
	# --- flying ---
	"bee_buzzer": {"name": "Bee Buzzer", "role": "Flying", "arch": "flyer", "hp": 1, "speed": 95.0, "h": 68.0, "stomp": true, "coins": 1, "pattern": "patrol"},
	"crow_swooper": {"name": "Crow Swooper", "role": "Flying", "arch": "flyer", "hp": 1, "speed": 110.0, "h": 74.0, "faces": 1, "stomp": true, "coins": 2, "pattern": "swoop"},
	"ghost_poof": {"name": "Ghost Poof", "role": "Sneaky", "arch": "flyer", "hp": 1, "speed": 80.0, "h": 74.0, "stomp": false, "coins": 2, "pattern": "shy"},
	"pie_bat": {"name": "Pie Bat", "role": "Flying", "arch": "flyer", "hp": 1, "speed": 120.0, "h": 68.0, "stomp": true, "coins": 2, "pattern": "wave"},
	"balloon_jelly": {"name": "Balloon Jelly", "role": "Special", "arch": "flyer", "hp": 2, "speed": 40.0, "h": 90.0, "stomp": true, "coins": 2, "pattern": "bob"},
}

const SCRIPTS := {
	"walker": "res://scripts/enemies/walker.gd",
	"flyer": "res://scripts/enemies/flyer.gd",
	"mole": "res://scripts/enemies/mole.gd",
}


static func has(kind: String) -> bool:
	return STATS.has(kind)


static func stat(kind: String, key: String, fallback: Variant = null) -> Variant:
	return (STATS.get(kind, {}) as Dictionary).get(key, fallback)


static func script_for(kind: String) -> String:
	return str(SCRIPTS.get(str(stat(kind, "arch", "walker")), SCRIPTS["walker"]))


static func kinds() -> Array:
	return STATS.keys()
