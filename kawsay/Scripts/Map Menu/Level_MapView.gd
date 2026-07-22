# level_map_view.gd
extends Node2D

const LEVEL_MARKER_SCENE := preload("res://Scene/MenuPrincipal/level_marker.tscn")

@export var map_sprite: Sprite2D
@export var camera: Camera2D  # tu camera_controller.gd ya hecho

# Posiciones manuales de cada nivel sobre TU mapa dibujado a mano.
# Ajusta estas coordenadas mirando tu imagen en el editor.
var level_positions: Dictionary = {
	1: Vector2(-360, 333),
	2: Vector2(-13, 278),
	3: Vector2(-282, 700),
	4: Vector2(-1056, 350),
	5: Vector2(-386, 22),
	6: Vector2(-555, -150),
	7: Vector2(-700, -371),
	8: Vector2(-230, -330),
	9: Vector2(49, -71),
	10: Vector2(400, 400),
	11: Vector2(640, 84),
	12: Vector2(840, -9),
	13: Vector2(1050, -150),
	14: Vector2(850, -450),
	15: Vector2(1110, -710),
	# ... completa hasta el 15 según tu arte
}

var level_names: Dictionary = {
	1: "Sabandía – Molino en el Valle",
	2: "Yumina – Andenes Verdes",
	3: "Characato – Plaza del Loncco",
	# ... completa
}

signal level_chosen(level_num: int)

func _ready() -> void:
	var max_unlocked: int = 1
	if get_node_or_null("/root/GameGlobals"):
		max_unlocked = get_node("/root/GameGlobals").max_unlocked_level
	if camera and map_sprite:
		var map_size: Vector2 = map_sprite.texture.get_size() * map_sprite.scale
		var viewport_size: Vector2 = get_viewport_rect().size
		camera.fit_to_map(map_size, viewport_size)
		camera.setup_limits_rect(map_size / 2.0)
	for level_num in level_positions.keys():
		_spawn_marker(level_num, max_unlocked)

	if camera and map_sprite:
		var half_size: Vector2 = map_sprite.texture.get_size() * map_sprite.scale / 2.0
		camera.setup_limits_rect(half_size)  # ver método nuevo abajo

func _spawn_marker(level_num: int, max_unlocked: int) -> void:
	var marker: LevelMarker = LEVEL_MARKER_SCENE.instantiate()
	add_child(marker)
	marker.position = level_positions[level_num]
	var lvl_name: String = level_names.get(level_num, "Nivel %d" % level_num)
	marker.setup(level_num, lvl_name, level_num <= max_unlocked)  # <-- una sola llamada, orden garantizado
	marker.level_selected.connect(_on_level_selected)

func _on_level_selected(level_num: int) -> void:
	level_chosen.emit(level_num)
	if GameGlobals:   # si es autoload
		GameGlobals.select_and_start_level(level_num)
