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
	
func _get_all_lines(player_id: int) -> Array[int]:
	var axes: Array = [[0, 3], [1, 4], [2, 5]]  # índices de HEX_DIRECTIONS
	var visited_starts: Dictionary = {}  # evita contar la misma línea 2 veces
	var lengths: Array[int] = []

	for coord in _cells.keys():
		if get_piece_at(coord) != player_id:
			continue
		for axis_index in axes.size():
			var axis = axes[axis_index]
			var back_dir: int = axis[1]

			# Solo empieza a contar desde el "inicio" de la línea (si el vecino de atrás
			# no es del mismo jugador, esta celda es el extremo inicial de la corrida).
			var neighbors_back: Array = _neighbor_map.get(coord, [])
			if not neighbors_back.is_empty():
				var behind: Vector2i = neighbors_back[back_dir]
				if behind != INVALID and get_piece_at(behind) == player_id:
					continue  # no es el inicio, se contará desde el extremo real

			var key: String = str(coord) + "_" + str(axis_index)
			if visited_starts.has(key):
				continue
			visited_starts[key] = true

			var count := 1
			var current: Vector2i = coord
			var forward_dir: int = axis[0]
			while true:
				var neighbors: Array = _neighbor_map.get(current, [])
				if neighbors.is_empty():
					break
				var next: Vector2i = neighbors[forward_dir]
				if next == INVALID or get_piece_at(next) != player_id:
					break
				count += 1
				current = next

			lengths.append(count)

	return lengths

## Revisa si player_id ya cumplió TODAS las condiciones de victoria del nivel.
func check_win_conditions(player_id: int, conditions: Array[WinCondition]) -> bool:
	if conditions.is_empty():
		return false

	var lines: Array[int] = _get_all_lines(player_id)
	lines.sort()
	lines.reverse()  # de mayor a menor, para asignar las líneas más largas primero

	# Copia de conteos requeridos, para ir descontando según asignamos líneas.
	var remaining: Array[int] = []
	for wc in conditions:
		remaining.append(wc.required_count)

	# Asigna cada línea encontrada a la condición más exigente que aún necesite cumplirse.
	for line_length in lines:
		for i in conditions.size():
			if remaining[i] > 0 and line_length >= conditions[i].required_length:
				remaining[i] -= 1
				break  # esta línea ya se usó, pasa a la siguiente

	for r in remaining:
		if r > 0:
			return false
	return true
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
	
func evaluate_placement(coord: Vector2i, for_player: int) -> int:
	var axes: Array = [[0, 3], [1, 4], [2, 5]]
	var total_score: int = 0

	for axis in axes:
		var count := 1
		var open_ends := 0

		for dir_index in axis:
			var current: Vector2i = coord
			while true:
				var neighbors: Array = _neighbor_map.get(current, [])
				if neighbors.is_empty():
					break
				var next: Vector2i = neighbors[dir_index]
				if next == INVALID:
					break
				var occupant: int = get_piece_at(next)
				if occupant == for_player:
					count += 1
					current = next
				elif occupant == -1:
					open_ends += 1
					break
				else:
					break

		# Si esta línea ya no puede llegar a win_length (ni con los espacios abiertos), no vale nada.
		if count + open_ends < win_length:
			continue

		# Puntaje exponencial: 3 en línea vale mucho más que 2, etc.
		total_score += int(pow(count, 3))
		if count >= win_length:
			total_score += 100000  # jugada ganadora inmediata

	return total_score
func has_valid_moves() -> bool:
	for coord in _valid_coords.keys():
		if can_place_at(coord):
			return true
	return false
