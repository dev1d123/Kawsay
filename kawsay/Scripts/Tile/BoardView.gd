# board_view.gd
extends Node2D

@export var tile_map_layer: TileMapLayer
@export var level_config: LevelConfig
@export var camera: Camera2D  
const HEX_SIZE := 71.0
const SOURCE_ID := 0
@export var empty_atlas_coord: Vector2i = Vector2i(0, 0)
@export var player1_atlas_coord: Vector2i = Vector2i(1, 0)  # IA / lava / rojo
@export var player2_atlas_coord: Vector2i = Vector2i(2, 0)  # Tú / restaurado / amarillo
const AI_PLAYER_ID := 1
const HUMAN_PLAYER_ID := 2
const AI_MOVE_DELAY := 0.5
var game: GameManager
var _board_coords: Array[Vector2i]  # <-- se genera UNA vez y se guarda
var ai: AIStrategy
const HEX_DIRECTIONS := [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
]
const INVALID_NEIGHBOR := Vector2i(-99999, -99999)

func _build_neighbor_map(coords: Array[Vector2i]) -> Dictionary:
	var valid_set: Dictionary = {}
	for c in coords:
		valid_set[c] = true

	var map: Dictionary = {}
	for c in coords:
		var neighbors: Array = []
		for dir in HEX_DIRECTIONS:
			var n: Vector2i = tile_map_layer.get_neighbor_cell(c, dir)
			neighbors.append(n if valid_set.has(n) else INVALID_NEIGHBOR)
		map[c] = neighbors
	return map
	
func _setup_game(coords: Array[Vector2i]) -> void:
	var neighbor_map: Dictionary = _build_neighbor_map(coords)
	var hex_board := HexBoard.new(coords, neighbor_map, level_config.win_length)
	game = GameManager.new(hex_board)

	ai = AIFactory.create(level_config.ai_difficulty, hex_board, AI_PLAYER_ID, HUMAN_PLAYER_ID, level_config.win_length)

	game.piece_placed.connect(_on_piece_placed)
	game.turn_changed.connect(_on_turn_changed)
	game.game_won.connect(_on_game_won)
	game.invalid_move.connect(_on_invalid_move)
	_maybe_trigger_ai_turn()
	
func _ready() -> void:
	_board_coords = level_config.generate_coords()  # única fuente de verdad
	_center_board(_board_coords) 
	_draw_board(_board_coords)
	_setup_game(_board_coords)
	camera.setup_limits(_board_coords, tile_map_layer, HEX_SIZE)
	
func _draw_board(coords: Array[Vector2i]) -> void:
	tile_map_layer.clear()
	for coord in coords:
		tile_map_layer.set_cell(coord, SOURCE_ID, empty_atlas_coord)

func _unhandled_input(event: InputEvent) -> void:
	if game.game_over:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var world_pos: Vector2 = get_global_mouse_position()
		var local_pos: Vector2 = tile_map_layer.to_local(world_pos)
		var cell: Vector2i = tile_map_layer.local_to_map(local_pos)
		game.play_at(cell)
		
func _on_piece_placed(coord: Vector2i, player_id: int) -> void:
	var atlas_coord: Vector2i = player1_atlas_coord if player_id == 1 else player2_atlas_coord
	tile_map_layer.set_cell(coord, SOURCE_ID, atlas_coord)

func _on_turn_changed(player_id: int) -> void:
	print("Turno de jugador ", player_id)
	_maybe_trigger_ai_turn()

func _maybe_trigger_ai_turn() -> void:
	if game.game_over:
		return
	if game.current_player != AI_PLAYER_ID:
		return
	await get_tree().create_timer(AI_MOVE_DELAY).timeout
	var move: Vector2i = ai.choose_move(_board_coords)
	game.play_at(move)

# agregar en board_view.gd

func _center_board(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return

	# Calcula el centro en espacio de mundo usando las posiciones reales de las celdas.
	var min_pos: Vector2 = tile_map_layer.map_to_local(coords[0])
	var max_pos: Vector2 = min_pos

	for coord in coords:
		var pos: Vector2 = tile_map_layer.map_to_local(coord)
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)

	var board_center: Vector2 = (min_pos + max_pos) / 2.0
	# Desplaza el TileMapLayer para que ese centro caiga en (0,0) del mundo.
	tile_map_layer.position = -board_center
	
func _on_game_won(player_id: int) -> void:
	print("¡GANÓ EL JUGADOR ", player_id, "!")

func _on_invalid_move(coord: Vector2i) -> void:
	print("Movimiento inválido en ", coord)
