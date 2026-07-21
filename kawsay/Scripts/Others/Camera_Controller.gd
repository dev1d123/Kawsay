# camera_controller.gd
extends Camera2D

@export var zoom_speed: float = 0.08
@export var min_zoom: float = 0.15
@export var max_zoom: float = 3.0
@export var board_offset_units: float = 2.0  # Margen fuera del mapa en unidades hex

@export_group("Edge Panning")
@export var enable_edge_panning: bool = true
@export var edge_margin: float = 35.0  # Margen sensible desde el borde en píxeles
@export var edge_speed: float = 650.0   # Velocidad de desplazamiento

var _dragging: bool = false
var _drag_start_mouse: Vector2
var _drag_start_cam_pos: Vector2
var _pan_limit: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if not enable_edge_panning or _dragging or get_tree().paused:
		return
		
	var viewport: Viewport = get_viewport()
	if not viewport:
		return
		
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	var view_size: Vector2 = viewport.get_visible_rect().size
	
	# Verificar que el cursor esté dentro de la ventana de juego
	if mouse_pos.x < 0 or mouse_pos.y < 0 or mouse_pos.x > view_size.x or mouse_pos.y > view_size.y:
		return
		
	var pan_dir := Vector2.ZERO
	
	if mouse_pos.x <= edge_margin:
		pan_dir.x -= 1.0
	elif mouse_pos.x >= view_size.x - edge_margin:
		pan_dir.x += 1.0
		
	if mouse_pos.y <= edge_margin:
		pan_dir.y -= 1.0
	elif mouse_pos.y >= view_size.y - edge_margin:
		pan_dir.y += 1.0
		
	if pan_dir != Vector2.ZERO:
		var move_amount: float = (edge_speed * delta) / max(zoom.x, 0.01)
		pan_by(pan_dir.normalized() * move_amount)

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
	var board_size: Vector2 = max_pos - min_pos
	var half_size: Vector2 = board_size / 2.0 + Vector2(margin, margin)
	_pan_limit = half_size
	position = Vector2.ZERO

	# Auto-ajuste de zoom inicial segun el tamaño del tablero
	var view_size: Vector2 = get_viewport_rect().size
	if view_size.x > 0 and view_size.y > 0 and board_size.x > 0 and board_size.y > 0:
		var fit_x: float = view_size.x / (board_size.x + margin * 2.5)
		var fit_y: float = view_size.y / (board_size.y + margin * 2.5)
		var auto_zoom: float = min(fit_x, fit_y)
		
		# Permitir que min_zoom sea lo suficientemente pequeño para mapas gigantes
		min_zoom = min(min_zoom, auto_zoom * 0.7)
		var initial_zoom: float = clamp(auto_zoom, min_zoom, max_zoom)
		zoom = Vector2(initial_zoom, initial_zoom)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# Rueda arriba -> Acercar (Zoom IN)
			_apply_zoom(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# Rueda abajo -> Alejar (Zoom OUT)
			_apply_zoom(-zoom_speed)
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
