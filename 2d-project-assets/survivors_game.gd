extends Node2D

var time_left = 120

func _ready():
	%Countdown.text = "Survive: " + str(time_left)
	%WinTimer.start()

func spawn_mob():
	var new_mob = preload("res://mob.tscn").instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	var random_size = randf_range(0.5, 1.5)
	new_mob.scale = Vector2(random_size, random_size)
	add_child(new_mob)
	

func _on_timer_timeout() -> void:
	spawn_mob()

func _on_player_health_depleted() -> void:
	%GameOver.visible = true
	get_tree().paused = true


func _on_win_timer_timeout() -> void:
	time_left -= 1
	%Countdown.text = "Survive: " + str(time_left)
	if time_left <= 0:
		%Victory.visible = true
		get_tree().paused = true
