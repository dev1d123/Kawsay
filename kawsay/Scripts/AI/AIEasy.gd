class_name AIEasy
extends AIStrategy

func choose_move(valid_coords: Array[Vector2i]) -> Vector2i:
	var playable: Array[Vector2i] = _get_playable_cells(valid_coords)
	return playable[randi() % playable.size()]
