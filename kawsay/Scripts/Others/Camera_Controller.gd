# camera_controller.gd
extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.6
@export var max_zoom: float = 2.5
@export var board_offset_units: float = 2.0  # "2 unidades" de margen fuera del mapa

var _dragging: bool = false
var _drag_start_mouse: Vector2
var _drag_start_cam_pos: Vector2
var _pan_limit: Vector2 = Vector2.ZERO

## Llamar desde board_view.gd una vez que el tablero está centrado y generado.
func setup_limits(board_coords: Array[Vector2i], tile_map_layer: TileMapLayer, hex_size: float) -> void:
	if board_coords.is_empty():
		return
	var min_pos: Vector2 = tile_map_layer.to_global(tile_map_layer.map_to_local(board_coords[0]))
	var max_pos: Vector2 = min_pos
	for coord in board_coords:
		var pos: Vector2 = tile_map_layer.to_global(tile_map_layer.map_to_local(coord))
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)

	var margin: float = hex_size * board_offset_units
	var half_size: Vector2 = (max_pos - min_pos) / 2.0 + Vector2(margin, margin)
	_pan_limit = half_size
	position = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
			if event.pressed:
				_drag_start_mouse = event.global_position
				_drag_start_cam_pos = position

	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = (event.global_position - _drag_start_mouse) / zoom
		pan_by(_drag_start_cam_pos - delta - position)

## Función pública reusable: botones UI y joystick la llaman también.
func pan_by(delta: Vector2) -> void:
	var new_pos: Vector2 = position + delta
	position = Vector2(
		clamp(new_pos.x, -_pan_limit.x, _pan_limit.x),
		clamp(new_pos.y, -_pan_limit.y, _pan_limit.y)
	)

func _apply_zoom(amount: float) -> void:
	var new_zoom: float = clamp(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func zoom_by(amount: float) -> void:
	_apply_zoom(amount)
