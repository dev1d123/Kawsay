class_name LevelConfig
extends Resource

enum GenerationMode { MANUAL, RHOMBUS, HEXAGON, RANDOM }

@export var level_name: String = "Nivel 1"
@export var generation_mode: GenerationMode = GenerationMode.RANDOM
@export var win_conditions: Array[WinCondition] = []   # <-- reemplaza win_length
@export var ai_difficulty: AIStrategy.Difficulty = AIStrategy.Difficulty.EASY
@export var manual_coords: Array[Vector2i] = []
@export var powerup_count: int = 3
@export var width: int = 7
@export var height: int = 6
@export var radius: int = 4
@export var random_bite_chance: float = 0.15
@export var random_seed: int = -1

func generate_coords() -> Array[Vector2i]:
	match generation_mode:
		GenerationMode.MANUAL:
			return manual_coords
		GenerationMode.RHOMBUS:
			return BoardGenerator.generate_rhombus(width, height)
		GenerationMode.HEXAGON:
			return BoardGenerator.generate_hexagon_radius(radius)
		GenerationMode.RANDOM:
			return BoardGenerator.generate_random(width, height, random_bite_chance, random_seed)
		_:
			return []

## Devuelve el win_length más exigente, útil como fallback para la IA/heurística.
func get_max_required_length() -> int:
	var max_len: int = 4
	for wc in win_conditions:
		max_len = max(max_len, wc.required_length)
	return max_len
