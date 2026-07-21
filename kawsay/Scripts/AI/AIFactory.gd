# ai_factory.gd
class_name AIFactory

static func create(difficulty: AIStrategy.Difficulty, board: HexBoard, ai_id: int, human_id: int, win_length: int) -> AIStrategy:
	match difficulty:
		AIStrategy.Difficulty.EASY:
			return AIMinimax.new(board, ai_id, human_id, win_length, 1, 0.5)
		AIStrategy.Difficulty.MEDIUM:
			return AIMinimax.new(board, ai_id, human_id, win_length, 2, 0.3)
		AIStrategy.Difficulty.HARD:
			return AIMinimax.new(board, ai_id, human_id, win_length, 3, 0.15)
		AIStrategy.Difficulty.VERY_HARD:
			return AIMinimax.new(board, ai_id, human_id, win_length, 4, 0.05)
		AIStrategy.Difficulty.ULTRA_HARD:
			return AIMinimax.new(board, ai_id, human_id, win_length, 5, 0.0)
		AIStrategy.Difficulty.NIGHTMARE:
			return AIMinimax.new(board, ai_id, human_id, win_length, 6, 0.0)
		AIStrategy.Difficulty.IMPOSSIBLE:
			return AIMinimax.new(board, ai_id, human_id, win_length, 7, 0.0)
		_:
			return AIMinimax.new(board, ai_id, human_id, win_length, 2, 0.3)
