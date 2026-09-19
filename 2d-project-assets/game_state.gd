extends Node
## Autoload singleton. Register in Project Settings > Globals (Autoload) as "GameState".
## Owns all persistent data: banked gold and purchased upgrade levels.

signal run_gold_changed(amount: int)
signal banked_gold_changed(amount: int)

const SAVE_PATH := "user://savegame.json"
const DEATH_KEEP_PERCENT := 0.25  # fraction of run gold kept on death (0.0 = lose everything)
const BASE_HEALTH := 100.0

# Cost of level N = base_cost * growth^N. Tune these to how much gold a run earns.
const UPGRADES := {
	"health": {
		"name": "Max Health",
		"base_cost": 15,
		"growth": 1.5,
		"max_level": 100,
		"per_level": 25.0,   # +25 max HP per level
	},
	"fire_rate": {
		"name": "Fire Rate",
		"base_cost": 20,
		"growth": 1.5,
		"max_level": 100,
		"per_level": 0.15,   # +15% fire rate per level
	},
}

var banked_gold: int = 0  # persistent, spent in the shop
var run_gold: int = 0     # collected this run, at risk until you extract
var upgrade_levels := {"health": 0, "fire_rate": 0}


func _ready() -> void:
	load_game()


# --- Run lifecycle ---------------------------------------------------------

func start_run() -> void:
	run_gold = 0
	run_gold_changed.emit(run_gold)


func add_gold(amount: int) -> void:
	run_gold += amount
	run_gold_changed.emit(run_gold)


## Player reached the extraction point. Returns gold banked (for a results screen).
func extract() -> int:
	var banked := run_gold
	banked_gold += banked
	run_gold = 0
	save_game()
	banked_gold_changed.emit(banked_gold)
	run_gold_changed.emit(run_gold)
	return banked


## Player died. Keeps only a fraction. Returns {"kept": int, "lost": int}.
func die() -> Dictionary:
	var kept := int(run_gold * DEATH_KEEP_PERCENT)
	var lost := run_gold - kept
	banked_gold += kept
	run_gold = 0
	save_game()
	banked_gold_changed.emit(banked_gold)
	run_gold_changed.emit(run_gold)
	return {"kept": kept, "lost": lost}


# --- Shop (sink) -----------------------------------------------------------

func can_afford(cost: int) -> bool:
	return banked_gold >= cost


func get_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))


func is_maxed(id: String) -> bool:
	return get_level(id) >= int(UPGRADES[id]["max_level"])


func get_cost(id: String) -> int:
	var up = UPGRADES[id]
	return int(round(up["base_cost"] * pow(up["growth"], get_level(id))))


## Returns true if the purchase went through.
func buy_upgrade(id: String) -> bool:
	if is_maxed(id):
		return false
	var cost := get_cost(id)
	if not can_afford(cost):
		return false
	banked_gold -= cost
	upgrade_levels[id] = get_level(id) + 1
	save_game()
	banked_gold_changed.emit(banked_gold)
	return true


## Short text for the shop UI showing the current bonus.
func describe(id: String) -> String:
	var lvl := get_level(id)
	match id:
		"health":
			return "Max HP: %d" % int(get_max_health())
		"fire_rate":
			return "Fire rate: +%d%%" % int(lvl * UPGRADES[id]["per_level"] * 100)
	return ""


# --- Upgrade effects (read these from gameplay scripts) ---------------------

func get_max_health() -> float:
	return BASE_HEALTH + get_level("health") * UPGRADES["health"]["per_level"]


## 1.0 = normal. 1.3 = shoots 30% faster.
func get_fire_rate_multiplier() -> float:
	return 1.0 + get_level("fire_rate") * UPGRADES["fire_rate"]["per_level"]


# --- Save / load -----------------------------------------------------------

func save_game() -> void:
	var data := {
		"banked_gold": banked_gold,
		"upgrades": upgrade_levels,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return  # first launch, keep defaults
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return  # corrupted file, keep defaults
	banked_gold = int(parsed.get("banked_gold", 0))
	var saved_levels = parsed.get("upgrades", {})
	if typeof(saved_levels) == TYPE_DICTIONARY:
		for id in upgrade_levels:
			upgrade_levels[id] = int(saved_levels.get(id, 0))
	banked_gold_changed.emit(banked_gold)
