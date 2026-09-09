extends Node2D

var time_left = 60

var story_index = 0

var story_list = [
	"Kshhhhh. Got-kshhhhhh-hing!",
	"Soldie-kshh. Kshhhh-ear me!",
	"You're sur-kshh-nded! Choppe-kshhhhhh-way!",
	"Survive unt-kshh-e get there!"
]

func _ready():
	%StoryLabel.text = story_list[0]
	%StoryTimer.start()
	
func start_game():
	%Countdown.text = "Survive: " + str(time_left)
	%WinTimer.start()
	%Timer.start()

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

func _on_story_timer_timeout() -> void:
	story_index += 1
	if story_index < story_list.size():
		%StoryLabel.text = story_list[story_index]
		%StoryTimer.start()
	else:
		%StoryLabel.visible = false
		start_game()
