extends Node2D

@export var extraction_scene: PackedScene
@export var player_path: NodePath
@export var min_radius: float = 400.0
@export var max_radius: float = 900.0
@export var max_placement_attempts: int = 20
@export_flags_2d_physics var obstacle_collision_mask: int = 0xFFFFFFFF

signal extraction_point_spawned(extraction_point: Node2D)

var _player: Node2D
var _current_extraction: Node2D


func get_current_extraction_point() -> Node2D:
	if is_instance_valid(_current_extraction):
		return _current_extraction
	return null


func _ready() -> void:
	_find_player()


func _find_player() -> void:
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path)
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]

func spawn_extraction_point() -> void:
	if not _player:
		_find_player()
	if not _player:
		push_warning("ExtractionSpawner: no player found, can't place extraction point relative to it.")
		return
	if not extraction_scene:
		push_warning("ExtractionSpawner: no extraction_scene assigned.")
		return

	# Remove any previous extraction point before placing a new one.
	if is_instance_valid(_current_extraction):
		_current_extraction.queue_free()

	var chosen_pos := _pick_position()

	_current_extraction = extraction_scene.instantiate()
	add_child(_current_extraction)
	_current_extraction.global_position = chosen_pos

	_current_extraction.player_extracted.connect(_on_player_extracted)
	extraction_point_spawned.emit(_current_extraction)


func _on_player_extracted(_player: Node2D) -> void:
	%Victory.visible = true
	get_tree().paused = true


func _pick_position() -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var best_pos := _player.global_position
	var attempts : int = max(max_placement_attempts, 1)

	for i in range(attempts):
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(min_radius, max_radius)
		var candidate := _player.global_position + Vector2(cos(angle), sin(angle)) * dist

		if max_placement_attempts <= 0:
			return candidate

		if _is_clear(candidate):
			return candidate

		best_pos = candidate # fall back to last tried point if all attempts fail

	push_warning("ExtractionSpawner: couldn't find a fully clear spot after %d attempts, using last try." % attempts)
	return best_pos


func _is_clear(point: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = obstacle_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := space_state.intersect_point(query, 1)
	return result.is_empty()
