extends Node2D

var time_left = 30  
var story_index = 0
var run_over = false 
var elapsed_time = 0.0
var difficulty_ramp_rate = 0.01  

var story_list = [
	"Kshhhhh. Got-kshhhhhh-hing!",
	"Soldie-kshh. Kshhhh-ear me!",
	"You're sur-kshh-nded! Choppe-kshhhhhh-way!",
	"Survive unt-kshh-e get there!"
]

func _ready():
	GameState.start_run()
	GameState.run_gold_changed.connect(_on_run_gold_changed)
	%GoldLabel.text = "Gold: 0"
	%RestartButton.pressed.connect(_on_restart_pressed)
	%StoryLabel.text = story_list[0]
	%StoryTimer.start()

func _process(delta: float) -> void:
	if not run_over:
		elapsed_time += delta

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

	var difficulty = 1.0 + elapsed_time * difficulty_ramp_rate
	new_mob.apply_difficulty(difficulty)

	add_child(new_mob)

func _on_timer_timeout() -> void:
	spawn_mob()
	
	%Timer.wait_time = max(0.3, %Timer.wait_time - 0.02)

func _on_run_gold_changed(amount: int) -> void:
	%GoldLabel.text = "Gold: %d" % amount

func _on_player_health_depleted() -> void:
	if run_over:
		return
	var result = GameState.die()
	show_results(
		"YOU DIED",
		"Kept: %d   Lost: %d" % [result.kept, result.lost]
	)

func on_extraction_reached() -> void:
	if run_over:
		return
	var banked = GameState.extract()
	show_results(
		"EXTRACTED!",
		"Banked: %d" % banked
	)

func show_results(title: String, details: String) -> void:
	run_over = true
	%TitleLabel.text = title
	%ResultLabel.text = details + "\nTotal banked: %d" % GameState.banked_gold
	%GameOver.visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://shop.tscn")

func _on_win_timer_timeout() -> void:
	time_left -= 1

	if time_left <= 0:
		time_left = 0
		%Countdown.text = "Get to the extraction point!"
		%WinTimer.stop()
		%ExtractionSpawner.spawn_extraction_point()
	else:
		%Countdown.text = "Survive: " + str(time_left)

func _on_story_timer_timeout() -> void:
	story_index += 1

	if story_index < story_list.size():
		%StoryLabel.text = story_list[story_index]
		%StoryTimer.start()
	else:
		%StoryLabel.visible = false
		%StoryTimer.stop()
		start_game()
