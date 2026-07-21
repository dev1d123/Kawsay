class_name LevelConfig
extends Resource

enum GenerationMode { MANUAL, RHOMBUS, HEXAGON, RANDOM }

@export var level_name: String = "Nivel 1"
@export var generation_mode: GenerationMode = GenerationMode.RANDOM
@export var win_length: int = 4

# MANUAL: pintas manualmente esta lista en el Inspector (click derecho -> Add Element)
@export var manual_coords: Array[Vector2i] = []

# RHOMBUS / RANDOM
@export var width: int = 7
@export var height: int = 6

# HEXAGON
@export var radius: int = 4

# RANDOM
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
