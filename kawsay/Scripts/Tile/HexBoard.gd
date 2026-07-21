class_name HexBoard
extends BoardBase

var _cells: Dictionary = {}
var _valid_coords: Dictionary = {}
var _neighbor_map: Dictionary = {}  # coord -> Array de 6 vecinos (o INVALID)
var win_length: int = 4

const INVALID := Vector2i(-99999, -99999)

func _init(valid_coords: Array[Vector2i], neighbor_map: Dictionary, required_to_win: int = 4) -> void:
	for c in valid_coords:
		_valid_coords[c] = true
	_neighbor_map = neighbor_map
	win_length = required_to_win

func reset() -> void:
	_cells.clear()

func is_valid_empty_cell(coord: Vector2i) -> bool:
	return _valid_coords.has(coord) and not _cells.has(coord)

func can_place_at(coord: Vector2i) -> bool:
	if not is_valid_empty_cell(coord):
		return false
	if _cells.is_empty():
		return true
	return _has_occupied_neighbor(coord)

func _has_occupied_neighbor(coord: Vector2i) -> bool:
	var neighbors: Array = _neighbor_map.get(coord, [])
	for n in neighbors:
		if n != INVALID and _cells.has(n):
			return true
	return false

func place_piece(coord: Vector2i, player_id: int) -> bool:
	if not can_place_at(coord):
		return false
	_cells[coord] = player_id
	return true

func undo_piece(coord: Vector2i) -> void:
	_cells.erase(coord)

func get_piece_at(coord: Vector2i) -> int:
	return _cells.get(coord, -1)

func check_winner_at(coord: Vector2i, player_id: int) -> bool:
	# Las 3 direcciones opuestas por pares: índices [0..5] del HEX_DIRECTIONS
	var axes: Array = [[0, 3], [1, 4], [2, 5]]
	for axis in axes:
		var count := 1
		for dir_index in axis:
			var current: Vector2i = coord
			while true:
				var neighbors: Array = _neighbor_map.get(current, [])
				if neighbors.is_empty():
					break
				var next: Vector2i = neighbors[dir_index]
				if next == INVALID or get_piece_at(next) != player_id:
					break
				count += 1
				current = next
		if count >= win_length:
			return true
	return false
