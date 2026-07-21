class_name AIFactory

static func create(difficulty: AIStrategy.Difficulty, board: BoardBase, ai_id: int, human_id: int, win_length: int) -> AIStrategy:
	match difficulty:
		AIStrategy.Difficulty.EASY:
			return AIEasy.new(board, ai_id, human_id, win_length)
		AIStrategy.Difficulty.MEDIUM:
			push_warning("AIMedium aún no implementada, usando EASY")
			return AIEasy.new(board, ai_id, human_id, win_length)
		AIStrategy.Difficulty.HARD:
			push_warning("AIHard aún no implementada, usando EASY")
			return AIEasy.new(board, ai_id, human_id, win_length)
		_:
			return AIEasy.new(board, ai_id, human_id, win_length)
