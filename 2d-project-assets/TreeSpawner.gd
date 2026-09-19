extends Node2D

@export var tree_scenes: Array[PackedScene] = []
@export var player_path: NodePath
@export var chunk_size: int = 512
@export var view_distance_chunks: int = 2
@export var trees_per_chunk: int = 6
@export var min_tree_spacing: float = 48.0
@export var world_seed: int = 12345
@export var update_interval: float = 0.25

var _player: Node2D
var _loaded_chunks: Dictionary = {} 
var _timer: float = 0.0


func _ready() -> void:
	_find_player()
	if _player:
		_update_chunks()


func _process(delta: float) -> void:
	if not _player:
		_find_player()
		return

	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_update_chunks()


func _find_player() -> void:
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path)
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]


func _update_chunks() -> void:
	var player_chunk := _world_to_chunk(_player.global_position)

	for x in range(player_chunk.x - view_distance_chunks, player_chunk.x + view_distance_chunks + 1):
		for y in range(player_chunk.y - view_distance_chunks, player_chunk.y + view_distance_chunks + 1):
			var coord := Vector2i(x, y)
			if not _loaded_chunks.has(coord):
				_spawn_chunk(coord)

	var to_remove: Array[Vector2i] = []
	for coord in _loaded_chunks.keys():
		var dist_x = abs(coord.x - player_chunk.x)
		var dist_y = abs(coord.y - player_chunk.y)
		if dist_x > view_distance_chunks or dist_y > view_distance_chunks:
			to_remove.append(coord)

	for coord in to_remove:
		_loaded_chunks[coord].queue_free()
		_loaded_chunks.erase(coord)


func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / chunk_size), floori(world_pos.y / chunk_size))


func _spawn_chunk(coord: Vector2i) -> void:
	if tree_scenes.is_empty():
		push_warning("TreeSpawner: no tree_scenes assigned, nothing to spawn.")
		return

	var chunk_node := Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [coord.x, coord.y]
	add_child(chunk_node)
	_loaded_chunks[coord] = chunk_node

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(world_seed, "_", coord.x, "_", coord.y))

	var chunk_origin := Vector2(coord.x * chunk_size, coord.y * chunk_size)
	var placed_positions: Array[Vector2] = []

	var attempts := 0
	var max_attempts := trees_per_chunk * 8
	while placed_positions.size() < trees_per_chunk and attempts < max_attempts:
		attempts += 1
		var candidate := chunk_origin + Vector2(
			rng.randf_range(0, chunk_size),
			rng.randf_range(0, chunk_size)
		)

		var too_close := false
		for p in placed_positions:
			if p.distance_to(candidate) < min_tree_spacing:
				too_close = true
				break

		if too_close:
			continue

		placed_positions.append(candidate)

		var scene: PackedScene = tree_scenes[rng.randi_range(0, tree_scenes.size() - 1)]
		var tree := scene.instantiate()
		chunk_node.add_child(tree)
		tree.global_position = candidate

		if tree is Node2D:
			tree.rotation = rng.randf_range(-0.05, 0.05)
			var s := rng.randf_range(0.9, 1.15)
			tree.scale = Vector2(s, s)
