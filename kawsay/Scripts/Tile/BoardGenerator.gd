# board_generator.gd
class_name BoardGenerator
extends RefCounted

## Genera una forma hexagonal "romboidal" (paralelogramo axial) — la más simple.
static func generate_rhombus(width: int, height: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for q in width:
		for r in height:
			coords.append(Vector2i(q, r))
	return coords

## Genera una forma hexagonal "radial" (hexágono perfecto centrado en 0,0).
static func generate_hexagon_radius(radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1: int = max(-radius, -q - radius)
		var r2: int = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			coords.append(Vector2i(q, r))
	return coords

## Genera una forma aleatoria: parte de una base y le "muerde" celdas al azar
## para variar el contorno entre partidas, sin dejar el tablero fragmentado.
static func generate_random(base_width: int, base_height: int, bite_chance: float = 0.15, seed_value: int = -1) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	var coords: Array[Vector2i] = generate_rhombus(base_width, base_height)
	var result: Array[Vector2i] = []
	for c in coords:
		# Nunca muerdas el borde exterior completo; protege bordes para evitar islas.
		var is_edge: bool = c.x == 0 or c.y == 0 or c.x == base_width - 1 or c.y == base_height - 1
		if is_edge or rng.randf() > bite_chance:
			result.append(c)
	return result
