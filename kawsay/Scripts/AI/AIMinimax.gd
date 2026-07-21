
class_name AIMinimax
extends AIStrategy

var search_depth: int
var blunder_chance: float  # probabilidad de "no jugar el mejor movimiento" (baja dificultad = más errores)

func _init(target_board: HexBoard, ai_player_id: int, human_player_id: int, target_win_length: int, depth: int, blunder: float) -> void:
	super._init(target_board, ai_player_id, human_player_id, target_win_length)
	search_depth = depth
	blunder_chance = blunder

func choose_move(valid_coords: Array[Vector2i]) -> Vector2i:
	var playable: Array[Vector2i] = _get_playable_cells(valid_coords)
	if playable.is_empty():
		return Vector2i.ZERO

	# 1) ¿Puedo ganar ya? Chequeo directo, sin gastar profundidad de búsqueda en eso.
	for c in playable:
		board.place_piece(c, player_id)
		var wins: bool = board.check_winner_at(c, player_id)
		board.undo_piece(c)
		if wins:
			return c

	# 2) ¿El oponente gana en su próximo turno? Bloquéalo.
	for c in playable:
		board.place_piece(c, opponent_id)
		var opp_wins: bool = board.check_winner_at(c, opponent_id)
		board.undo_piece(c)
		if opp_wins:
			return c

	# 3) Reduce candidatos a los más prometedores antes de la búsqueda profunda (rendimiento).
	var candidates: Array[Vector2i] = _top_candidates(playable, 8)

	# 4) Búsqueda minimax con poda alfa-beta.
	var best_score: int = -INF
	var best_move: Vector2i = candidates[0]

	for c in candidates:
		board.place_piece(c, player_id)
		var score: int = _minimax(search_depth - 1, -INF, INF, false)
		board.undo_piece(c)
		if score > best_score:
			best_score = score
			best_move = c

	# 5) Simula "errores humanos" en dificultades bajas.
	if randf() < blunder_chance:
		return candidates[randi() % candidates.size()]

	return best_move

func _top_candidates(playable: Array[Vector2i], max_count: int) -> Array[Vector2i]:
	var scored: Array = []
	for c in playable:
		var s: int = board.evaluate_placement(c, player_id) + board.evaluate_placement(c, opponent_id)
		scored.append({"coord": c, "score": s})
	scored.sort_custom(func(a, b): return a.score > b.score)

	var result: Array[Vector2i] = []
	for i in min(max_count, scored.size()):
		result.append(scored[i].coord)
	return result

func _minimax(depth: int, alpha: int, beta: int, maximizing: bool) -> int:
	if depth <= 0:
		return _evaluate_board()

	var current_player: int = player_id if maximizing else opponent_id
	var candidates: Array[Vector2i] = _top_candidates(_get_playable_cells(board._valid_coords.keys()), 6)

	if candidates.is_empty():
		return _evaluate_board()

	if maximizing:
		var max_eval: int = -INF
		for c in candidates:
			board.place_piece(c, current_player)
			if board.check_winner_at(c, current_player):
				board.undo_piece(c)
				return 1000000 - (search_depth - depth)
			var eval: int = _minimax(depth - 1, alpha, beta, false)
			board.undo_piece(c)
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha:
				break
		return max_eval
	else:
		var min_eval: int = INF
		for c in candidates:
			board.place_piece(c, current_player)
			if board.check_winner_at(c, current_player):
				board.undo_piece(c)
				return -1000000 + (search_depth - depth)
			var eval: int = _minimax(depth - 1, alpha, beta, true)
			board.undo_piece(c)
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha:
				break
		return min_eval

func _evaluate_board() -> int:
	var score: int = 0
	for coord in board._cells.keys():
		var occupant: int = board.get_piece_at(coord)
		var value: int = board.evaluate_placement(coord, occupant)
		score += value if occupant == player_id else -value
	return score
