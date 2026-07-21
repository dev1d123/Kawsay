# ai_strategy.gd
class_name AIStrategy
extends RefCounted

enum Difficulty { EASY, MEDIUM, HARD, VERY_HARD, ULTRA_HARD, NIGHTMARE, IMPOSSIBLE }

var board: HexBoard
var player_id: int
var opponent_id: int
var win_length: int

func _init(target_board: HexBoard, ai_player_id: int, human_player_id: int, target_win_length: int) -> void:
	board = target_board
	player_id = ai_player_id
	opponent_id = human_player_id
	win_length = target_win_length

func choose_move(valid_coords: Array[Vector2i]) -> Vector2i:
	push_error("choose_move() no implementado")
	return Vector2i.ZERO

func _get_playable_cells(valid_coords: Array[Vector2i]) -> Array[Vector2i]:
	var playable: Array[Vector2i] = []
	for c in valid_coords:
		if board.can_place_at(c):
			playable.append(c)
	return playable
