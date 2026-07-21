# test_board_gen.gd
extends Node2D

@export_enum("Rhombus", "Hexagon", "Random") var mode: String = "Hexagon"
@export var width: int = 7
@export var height: int = 6
@export var radius: int = 4
@export var random_bite_chance: float = 0.15
@export var random_seed: int = -1

const HEX_SIZE := 30.0  # radio del hexágono en píxeles, ajusta a gusto

func _ready() -> void:
	_draw_board()

func _draw_board() -> void:
	var coords: Array[Vector2i] = []
	match mode:
		"Rhombus":
			coords = BoardGenerator.generate_rhombus(width, height)
		"Hexagon":
			coords = BoardGenerator.generate_hexagon_radius(radius)
		"Random":
			coords = BoardGenerator.generate_random(width, height, random_bite_chance, random_seed)

	print("Celdas generadas: ", coords.size())

	for coord in coords:
		_spawn_hex_tile(coord)

func _spawn_hex_tile(coord: Vector2i) -> void:
	var hex := Polygon2D.new()
	hex.polygon = _make_hex_points(HEX_SIZE)
	hex.color = Color(0.6, 0.6, 0.7)
	hex.position = _axial_to_pixel(coord)
	add_child(hex)

	# Borde para distinguir celdas
	var outline := Line2D.new()
	var pts: PackedVector2Array = _make_hex_points(HEX_SIZE)
	pts.append(pts[0])  # cerrar el contorno
	outline.points = pts
	outline.width = 2.0
	outline.default_color = Color.BLACK
	outline.position = _axial_to_pixel(coord)
	add_child(outline)

## Convierte coordenada axial (q, r) a posición en píxeles.
## Pointy-top, mismo sistema que usamos para HexBoard.
func _axial_to_pixel(coord: Vector2i) -> Vector2:
	var x: float = HEX_SIZE * sqrt(3) * (coord.x + coord.y / 2.0)
	var y: float = HEX_SIZE * 1.5 * coord.y
	return Vector2(x, y) + Vector2(300, 100)  # offset para centrar en pantalla

func _make_hex_points(size: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		var angle_deg: float = 60 * i - 30  # -30 para orientación pointy-top
		var angle_rad: float = deg_to_rad(angle_deg)
		points.append(Vector2(cos(angle_rad), sin(angle_rad)) * size)
	return points
