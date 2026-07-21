class_name GameManager
extends RefCounted

signal piece_placed(coord: Vector2i, player_id: int)
signal turn_changed(player_id: int)
signal game_won(player_id: int)
signal invalid_move(coord: Vector2i)

var board: BoardBase
var current_player: int = 1
var game_over: bool = false

func _init(new_board: BoardBase) -> void:
	board = new_board

func play_at(coord: Vector2i) -> bool:
	if game_over:
		return false
	if not board.can_place_at(coord):
		invalid_move.emit(coord)
		return false

	board.place_piece(coord, current_player)
	piece_placed.emit(coord, current_player)

	if board.check_winner_at(coord, current_player):
		game_over = true
		game_won.emit(current_player)
		return true

	current_player = 2 if current_player == 1 else 1
	turn_changed.emit(current_player)
	return true

func reset() -> void:
	board.reset()
	current_player = 1
	game_over = false
