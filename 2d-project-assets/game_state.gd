extends Node
## Autoload singleton. Register in Project Settings > Globals (Autoload) as "GameState".
## Owns all persistent data. Later: add upgrade levels / unlocks to the save dict.


signal run_gold_changed(amount: int)
signal banked_gold_changed(amount: int)

const SAVE_PATH := "user://savegame.json"
const DEATH_KEEP_PERCENT := 0.25  # fraction of run gold kept on death (0.0 = lose everything)

var banked_gold: int = 0  # persistent, spent in the shop
var run_gold: int = 0     # collected this run, at risk until you extract


func _ready() -> void:
	print("GameState loaded")
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


## Returns true if the purchase went through.
func spend_gold(cost: int) -> bool:
	if not can_afford(cost):
		return false
	banked_gold -= cost
	save_game()
	banked_gold_changed.emit(banked_gold)
	return true


# --- Save / load -----------------------------------------------------------

func save_game() -> void:
	var data := {
		"banked_gold": banked_gold,
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
	banked_gold_changed.emit(banked_gold)
