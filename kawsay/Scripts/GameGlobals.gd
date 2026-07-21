extends Node

var max_unlocked_level: int = 1
var selected_level_num: int = 1
var selected_level_config: LevelConfig

const GAME_SCENE_PATH: String = "res://Scene/DaniPrueba/dani.tscn"
const MAIN_MENU_PATH: String = "res://Scene/MenuPrincipal/main_menu.tscn"

func _ready() -> void:
	_load_config_for_level(1)

func _load_config_for_level(level_num: int) -> void:
	selected_level_num = level_num
	var path = "res://Data/level_%d.tres" % level_num
	var cfg = load(path) as LevelConfig
	if cfg:
		selected_level_config = cfg
	else:
		push_error("No se pudo cargar: " + path)

func select_and_start_level(level_num: int) -> void:
	_load_config_for_level(level_num)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func complete_level(level_num: int) -> bool:
	var newly_unlocked: bool = false
	if level_num == max_unlocked_level and max_unlocked_level < 3:
		max_unlocked_level += 1
		newly_unlocked = true
		print("¡Felicidades! Nivel %d desbloqueado." % max_unlocked_level)
	return newly_unlocked

func return_to_level_selector() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
