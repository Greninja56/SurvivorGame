extends Control

const GAME_SCENE := "res://survivors_game.tscn"

var gold_label: Label
var rows := {}  


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	center.add_child(box)

	box.add_child(_make_label("SHOP", 96))
	gold_label = _make_label("", 56)
	box.add_child(gold_label)

	for id in GameState.UPGRADES:
		box.add_child(_make_row(id))

	var start := Button.new()
	start.text = "Start Run"
	start.add_theme_font_size_override("font_size", 56)
	start.custom_minimum_size = Vector2(500, 130)
	start.pressed.connect(_on_start_pressed)
	box.add_child(start)


func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_row(id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)

	var info := _make_label("", 44)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.custom_minimum_size = Vector2(900, 0)
	row.add_child(info)

	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 44)
	btn.custom_minimum_size = Vector2(380, 110)
	btn.pressed.connect(_on_buy_pressed.bind(id))
	row.add_child(btn)

	rows[id] = {"info": info, "button": btn}
	return row


func _refresh() -> void:
	gold_label.text = "Gold: %d" % GameState.banked_gold
	for id in rows:
		var up = GameState.UPGRADES[id]
		var level: int = GameState.get_level(id)
		var info: Label = rows[id]["info"]
		var btn: Button = rows[id]["button"]

		info.text = "%s  (Lv %d/%d)\n%s" % [up["name"], level, up["max_level"], GameState.describe(id)]

		if GameState.is_maxed(id):
			btn.text = "MAXED"
			btn.disabled = true
		else:
			var cost: int = GameState.get_cost(id)
			btn.text = "Buy: %d gold" % cost
			btn.disabled = not GameState.can_afford(cost)


func _on_buy_pressed(id: String) -> void:
	GameState.buy_upgrade(id)
	_refresh()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
