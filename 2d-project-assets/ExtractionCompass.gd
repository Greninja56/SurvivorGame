extends Control
@export var extraction_spawner_path: NodePath
@export var arrow_node_path: NodePath
@export var edge_margin: float = 48.0

var _extraction_spawner: Node
var _arrow: Control
var _target: Node2D


func _ready() -> void:
	if extraction_spawner_path != NodePath(""):
		_extraction_spawner = get_node_or_null(extraction_spawner_path)

	if arrow_node_path != NodePath(""):
		_arrow = get_node_or_null(arrow_node_path)
	else:
		_arrow = get_node_or_null("Arrow")

	if _extraction_spawner:
		if _extraction_spawner.has_signal("extraction_point_spawned"):
			_extraction_spawner.extraction_point_spawned.connect(_on_extraction_point_spawned)
		if _extraction_spawner.has_method("get_current_extraction_point"):
			_target = _extraction_spawner.get_current_extraction_point()

	visible = false


func _on_extraction_point_spawned(extraction_point: Node2D) -> void:
	_target = extraction_point
	visible = true


func _process(_delta: float) -> void:
	if not is_instance_valid(_target) or not _arrow:
		visible = false
		return

	var camera := get_viewport().get_camera_2d()
	if not camera:
		return

	var viewport_size := get_viewport_rect().size
	var screen_center := viewport_size / 2.0

	var target_screen_pos: Vector2 = get_viewport().canvas_transform * _target.global_position

	var on_screen_margin := 64.0
	var screen_rect := Rect2(Vector2.ZERO, viewport_size).grow(-on_screen_margin)
	if screen_rect.has_point(target_screen_pos):
		visible = false
		return

	visible = true

	var direction: Vector2 = (target_screen_pos - screen_center).normalized()

	var half_size := viewport_size / 2.0 - Vector2(edge_margin, edge_margin)
	var scale_x : float = INF if direction.x == 0 else abs(half_size.x / direction.x)
	var scale_y : float = INF if direction.y == 0 else abs(half_size.y / direction.y)
	var clamp_scale: float = min(scale_x, scale_y)

	var arrow_pos := screen_center + direction * clamp_scale
	_arrow.global_position = arrow_pos - _arrow.size / 2.0
	_arrow.rotation = direction.angle()
