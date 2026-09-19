extends Area2D

signal player_extracted(player: Node2D)

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true
	player_extracted.emit(body)
