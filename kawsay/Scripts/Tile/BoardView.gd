# board_view.gd
extends Node2D

@export var tile_map_layer: TileMapLayer
@export var column_count: int = 7
@export var column_height: int = 6

const PLAYER_COLORS := {
	1: Color.RED,
	2: Color.YELLOW,
}
const PIECE_RADIUS := 20.0

var game: GameManager
var _pieces_container: Node2D

# true = la "columna" de juego corresponde a cell.x (igual que antes)
# false = corresponde a cell.y (probablemente el caso con offset horizontal)
@export var column_is_x_axis: bool = true

func _ready() -> void:
	var valid_coords: Array[Vector2i] = []
	for cell in tile_map_layer.get_used_cells():
		valid_coords.append(cell)  # usamos cell.x/y directo como coord axial (q,r)

	var hex_board := HexBoard.new(valid_coords)
	game = GameManager.new(hex_board)

	game.piece_placed.connect(_on_piece_placed)
	game.turn_changed.connect(_on_turn_changed)
	game.game_won.connect(_on_game_won)
	game.invalid_move.connect(_on_invalid_move)

	_pieces_container = Node2D.new()
	add_child(_pieces_container)


func _unhandled_input(event: InputEvent) -> void:
	if game.game_over:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var local_pos: Vector2 = tile_map_layer.to_local(event.global_position)
		var cell: Vector2i = tile_map_layer.local_to_map(local_pos)
		game.play_at(cell)

func _on_piece_placed(coord: Vector2i, player_id: int) -> void:
	var world_pos: Vector2 = tile_map_layer.map_to_local(coord)
	_spawn_piece(world_pos, player_id)

func _on_invalid_move(coord: Vector2i) -> void:
	print("Movimiento inválido en ", coord, " (no adyacente o ya ocupado)")
	
func _spawn_piece(pos: Vector2, player_id: int) -> void:
	var piece := Polygon2D.new()
	piece.polygon = _make_circle_points(PIECE_RADIUS)
	piece.color = PLAYER_COLORS.get(player_id, Color.WHITE)
	piece.position = pos
	_pieces_container.add_child(piece)

func _make_circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var angle: float = i * TAU / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _on_turn_changed(player_id: int) -> void:
	print("Turno de jugador ", player_id)

func _on_game_won(player_id: int) -> void:
	print("¡GANÓ EL JUGADOR ", player_id, "!")

func _on_game_drawn() -> void:
	print("Empate")
