extends CharacterBody2D

var health = 3
var base_speed = 400.0
var speed = base_speed
var gold_value = 1

@onready var player = get_node("/root/Game/Player")

func _ready():
	%Slime.play_walk()

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()

func apply_difficulty(difficulty: float) -> void:
	health = int(ceil(3 * difficulty))
	speed = base_speed * clamp(difficulty, 1.0, 2.5)  
	gold_value = int(ceil(1 * difficulty))

func take_damage():
	health -= 1
	%Slime.play_hurt()

	if health <= 0:
		var smoke = preload("res://smoke_explosion/smoke_explosion.tscn").instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position

		var gold = preload("res://gold_pickup.tscn").instantiate()
		gold.position = position
		gold.value = gold_value
		get_parent().add_child.call_deferred(gold)

		queue_free()
