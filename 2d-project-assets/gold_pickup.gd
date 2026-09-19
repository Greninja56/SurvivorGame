extends Area2D
## Attach to the root Area2D of gold_pickup.tscn.
## The player must be in the "player" group and on a layer this Area2D's mask detects.

@export var value: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.add_gold(value)
		queue_free()
