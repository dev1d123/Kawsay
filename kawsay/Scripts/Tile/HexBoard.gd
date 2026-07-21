class_name HexBoard
extends BoardBase

var _cells: Dictionary = {}
var _valid_coords: Dictionary = {}
var win_length: int = 4

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, -1), Vector2i(-1, 1),
]

func _init(valid_coords: Array[Vector2i] = [], required_to_win: int = 4) -> void:
	set_valid_coords(valid_coords)
	win_length = required_to_win

## Define qué coordenadas existen en el tablero (llamar antes de jugar).
func set_valid_coords(coords: Array[Vector2i]) -> void:
	_valid_coords.clear()
	for c in coords:
		_valid_coords[c] = true

func reset() -> void:
	_cells.clear()

func is_valid_empty_cell(coord: Vector2i) -> bool:
	return _valid_coords.has(coord) and not _cells.has(coord)

func can_place_at(coord: Vector2i) -> bool:
	if not is_valid_empty_cell(coord):
		return false
	if _cells.is_empty():
		return true  # primer movimiento del juego: cualquier celda vale
	return _has_occupied_neighbor(coord)

func _has_occupied_neighbor(coord: Vector2i) -> bool:
	for offset in NEIGHBOR_OFFSETS:
		if _cells.has(coord + offset):
			return true
	return false

func place_piece(coord: Vector2i, player_id: int) -> bool:
	if not can_place_at(coord):
		return false
	_cells[coord] = player_id
	return true

func get_piece_at(coord: Vector2i) -> int:
	return _cells.get(coord, -1)
func check_winner_at(coord: Vector2i, player_id: int) -> bool:
	const AXES: Array = [
		[Vector2i(1, 0), Vector2i(-1, 0)],
		[Vector2i(0, 1), Vector2i(0, -1)],
		[Vector2i(1, -1), Vector2i(-1, 1)],
	]
	for axis in AXES:
		var count := 1
		for direction in axis:
			var current: Vector2i = coord + direction
			while get_piece_at(current) == player_id:
				count += 1
				current += direction
		if count >= win_length:
			return true
	return false
