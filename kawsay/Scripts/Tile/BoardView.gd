# board_view.gd
extends Node2D

@export var tile_map_layer: TileMapLayer
@export var level_config: LevelConfig
@export var camera: Camera2D  
const HEX_SIZE := 71.0
const SOURCE_ID := 0
@export var empty_atlas_coord: Vector2i = Vector2i(0, 0)
@export var player1_atlas_coord: Vector2i = Vector2i(1, 0)  # IA / lava / rojo
@export var player2_atlas_coord: Vector2i = Vector2i(2, 0)  # Tú / restaurado / amarillo

@export var empty_atlas_coords: Array[Vector2i] = []
@export var player1_atlas_coords: Array[Vector2i] = []
@export var player2_atlas_coords: Array[Vector2i] = []

var _empty_tile_map: Dictionary = {}
const AI_PLAYER_ID := 1
const HUMAN_PLAYER_ID := 2
const AI_MOVE_DELAY := 0.5
var game: GameManager
var _board_coords: Array[Vector2i]  # <-- se genera UNA vez y se guarda
var ai: AIStrategy
var _highlight_sprites: Dictionary = {}
var _highlight_tweens: Array[Tween] = []

var _selected_card_type: int = -1
var _roulette_active: bool = true
var _roulette_overlay: ColorRect = null
var _hover_info_panel: PanelContainer = null
var _hover_pulse_tween: Tween = null

const CARD_DETAILS = {
	0: {
		"title": "CARTA DE COMUNIDAD",
		"desc": "Por dos fichas adyacentes aparece una tercera aleatoria en las posiciones disponibles (tanto para ti como para la lava).",
		"texture": "res://Sprites/Cards/comunity_card.png"
	},
	1: {
		"title": "CARTA DE DOBLE RIESGO",
		"desc": "Produce que el jugador tenga dos turnos, así como que la lava tenga dos turnos.",
		"texture": "res://Sprites/Cards/double_card.png"
	},
	2: {
		"title": "CARTA DE RESISTENCIA",
		"desc": "Otorga una probabilidad de que aparezcan powerups en el mapa.",
		"texture": "res://Sprites/Cards/resistance_card.png"
	}
}

const HEX_DIRECTIONS := [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
]
const INVALID_NEIGHBOR := Vector2i(-99999, -99999)

# Referencias del HUD
@onready var hud: CanvasLayer = $HUD
@onready var level_name_label: Label = $HUD/TopCenterBanner/Margin/VBox/LevelNameLabel
@onready var objective_label: Label = $HUD/TopCenterBanner/Margin/VBox/ObjectiveLabel

@onready var selector_button: Button = $HUD/TopRightButtons/SelectorButton
@onready var restart_button: Button = $HUD/TopRightButtons/RestartButton
@onready var settings_button: Button = $HUD/TopRightButtons/SettingsButton
@onready var pause_button: Button = $HUD/TopRightButtons/PauseButton

@onready var pause_overlay: Control = $HUD/PauseOverlay
@onready var settings_overlay: PanelContainer = $HUD/SettingsOverlay
@onready var music_slider: HSlider = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/MusicBox/MusicSlider
@onready var sfx_slider: HSlider = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/SfxBox/SfxSlider
@onready var music_val_label: Label = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/MusicBox/HeaderHBox/MusicValLabel
@onready var sfx_val_label: Label = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/SfxBox/HeaderHBox/SfxValLabel
@onready var settings_back_button: Button = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/BackButton

@onready var result_dialog: PanelContainer = $HUD/ResultDialog
@onready var result_title: Label = $HUD/ResultDialog/Margin/VBox/ResultTitle
@onready var result_message: Label = $HUD/ResultDialog/Margin/VBox/ResultMessage
@onready var unlock_info_label: Label = $HUD/ResultDialog/Margin/VBox/UnlockInfoLabel
@onready var retry_button: Button = $HUD/ResultDialog/Margin/VBox/ButtonsHBox/RetryButton
@onready var result_level_select_button: Button = $HUD/ResultDialog/Margin/VBox/ButtonsHBox/LevelSelectBtn

func _ready() -> void:
	# Activar flag de ruleta al iniciar
	_roulette_active = true

	# Iniciar música de nivel
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").play_music("level")

	# Cargar nivel desde el Singleton global si está disponible
	if get_node_or_null("/root/GameGlobals") and get_node("/root/GameGlobals").selected_level_config:
		level_config = get_node("/root/GameGlobals").selected_level_config

	# Asegurar que el árbol no esté pausado
	get_tree().paused = false

	# Inicializar HUD
	_setup_hud()
	_init_bottom_card_layout()

	# Generar tablero e iniciar juego
	_board_coords = level_config.generate_coords()
	_center_board(_board_coords) 
	_draw_board(_board_coords)
	_setup_game(_board_coords)
	camera.setup_limits(_board_coords, tile_map_layer, HEX_SIZE)
	
	# Ejecutar ruleta de cartas
	_run_card_roulette()

func _setup_hud() -> void:
	# 1. Configuración de Banner Central
	var level_num: int = 1
	if get_node_or_null("/root/GameGlobals"):
		level_num = get_node("/root/GameGlobals").selected_level_num

	var name_str = level_config.level_name if level_config else "Volcan"
	var win_len = level_config.win_length if level_config else 4

	level_name_label.text = "%s (Nivel %d)" % [name_str, level_num]
	objective_label.text = "🎯 Objetivo: Conecta %d fichas en línea para ganar" % win_len

	# 2. Conexión de 4 Botones Top Right
	selector_button.pressed.connect(_on_selector_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	pause_button.pressed.connect(_on_pause_pressed)

	# Hover animado en botones HUD
	_setup_hud_button_hover(selector_button)
	_setup_hud_button_hover(restart_button)
	_setup_hud_button_hover(settings_button)
	_setup_hud_button_hover(pause_button)

	# 3. Configuración de Modales (Pause, Settings y ResultDialog)
	pause_overlay.visible = false
	settings_overlay.visible = false
	result_dialog.visible = false

	# Configuración de Audio Modal
	if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
		var audio_mgr = get_node("/root/AudioManager")
		music_slider.value = audio_mgr.get_music_volume()
		sfx_slider.value = audio_mgr.get_sfx_volume()

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	_update_volume_labels()

	# Botones de ResultDialog
	retry_button.pressed.connect(_on_restart_pressed)
	result_level_select_button.pressed.connect(_on_selector_pressed)
	_setup_hud_button_hover(retry_button)
	_setup_hud_button_hover(result_level_select_button)
	_setup_hud_button_hover(settings_back_button)

func _setup_hud_button_hover(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.15)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	)

# --- BOTONES Y ACCIONES DEL HUD ---
func _on_selector_pressed() -> void:
	get_tree().paused = false
	if get_node_or_null("/root/GameGlobals"):
		get_node("/root/GameGlobals").return_to_level_selector()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_overlay.visible = true
	pause_overlay.modulate.a = 0.0
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_overlay, "modulate:a", 1.0, 0.25)

func _on_settings_pressed() -> void:
	settings_overlay.visible = true
	settings_overlay.modulate.a = 0.0
	settings_overlay.scale = Vector2(0.85, 0.85)
	settings_overlay.pivot_offset = settings_overlay.size / 2.0

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(settings_overlay, "modulate:a", 1.0, 0.3)
	tween.tween_property(settings_overlay, "scale", Vector2(1.0, 1.0), 0.3)

func _on_settings_back_pressed() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(settings_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_property(settings_overlay, "scale", Vector2(0.85, 0.85), 0.2)
	tween.chain().tween_callback(func(): settings_overlay.visible = false)

func _on_music_slider_changed(val: float) -> void:
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").set_music_volume(val)
	_update_volume_labels()

func _on_sfx_slider_changed(val: float) -> void:
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").set_sfx_volume(val)
	_update_volume_labels()

func _update_volume_labels() -> void:
	music_val_label.text = "%d%%" % int(round(music_slider.value * 100))
	sfx_val_label.text = "%d%%" % int(round(sfx_slider.value * 100))

# --- CONTROL DE ENTRADA Y DESPAUSADO POR CLICK ---
func _input(event: InputEvent) -> void:
	if get_tree().paused and pause_overlay.visible:
		if event is InputEventMouseButton and event.pressed:
			get_tree().paused = false
			pause_overlay.visible = false
			get_viewport().set_input_as_handled()

func _build_neighbor_map(coords: Array[Vector2i]) -> Dictionary:
	var valid_set: Dictionary = {}
	for c in coords:
		valid_set[c] = true

	var map: Dictionary = {}
	for c in coords:
		var neighbors: Array = []
		for dir in HEX_DIRECTIONS:
			var n: Vector2i = tile_map_layer.get_neighbor_cell(c, dir)
			neighbors.append(n if valid_set.has(n) else INVALID_NEIGHBOR)
		map[c] = neighbors
	return map

func _setup_game(coords: Array[Vector2i]) -> void:
	var neighbor_map: Dictionary = _build_neighbor_map(coords)
	var hex_board := HexBoard.new(coords, neighbor_map, level_config.win_length)
	game = GameManager.new(hex_board)

	ai = AIFactory.create(level_config.ai_difficulty, hex_board, AI_PLAYER_ID, HUMAN_PLAYER_ID, level_config.win_length)

	game.piece_placed.connect(_on_piece_placed)
	game.turn_changed.connect(_on_turn_changed)
	game.game_won.connect(_on_game_won)
	game.invalid_move.connect(_on_invalid_move)
	
	if game.current_player == HUMAN_PLAYER_ID:
		_highlight_available_cells()
	else:
		_clear_highlights()
		
	_maybe_trigger_ai_turn()

func _get_random_empty_coord() -> Vector2i:
	if not empty_atlas_coords.is_empty():
		return empty_atlas_coords.pick_random()
	return empty_atlas_coord

func _get_random_player1_coord() -> Vector2i:
	if not player1_atlas_coords.is_empty():
		return player1_atlas_coords.pick_random()
	return player1_atlas_coord

func _get_random_player2_coord() -> Vector2i:
	if not player2_atlas_coords.is_empty():
		return player2_atlas_coords.pick_random()
	return player2_atlas_coord

func _get_empty_tile_at(coord: Vector2i) -> Vector2i:
	return _empty_tile_map.get(coord, empty_atlas_coord)

func _draw_board(coords: Array[Vector2i]) -> void:
	tile_map_layer.clear()
	_empty_tile_map.clear()
	for coord in coords:
		var empty_coord: Vector2i = _get_random_empty_coord()
		_empty_tile_map[coord] = empty_coord
		tile_map_layer.set_cell(coord, SOURCE_ID, empty_coord)

func _unhandled_input(event: InputEvent) -> void:
	if _roulette_active or game.game_over or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var world_pos: Vector2 = get_global_mouse_position()
		var local_pos: Vector2 = tile_map_layer.to_local(world_pos)
		var cell: Vector2i = tile_map_layer.local_to_map(local_pos)
		game.play_at(cell)

func _on_piece_placed(coord: Vector2i, player_id: int) -> void:
	if _highlight_sprites.has(coord):
		var sprite = _highlight_sprites[coord]
		if is_instance_valid(sprite):
			sprite.queue_free()
		_highlight_sprites.erase(coord)
		
	var atlas_coord: Vector2i = _get_random_player1_coord() if player_id == AI_PLAYER_ID else _get_random_player2_coord()
	tile_map_layer.set_cell(coord, SOURCE_ID, atlas_coord)

func _on_turn_changed(player_id: int) -> void:
	print("Turno de jugador ", player_id)
	if player_id == HUMAN_PLAYER_ID:
		_highlight_available_cells()
	else:
		_clear_highlights()
	_maybe_trigger_ai_turn()

func _maybe_trigger_ai_turn() -> void:
	if _roulette_active or game.game_over or get_tree().paused:
		return
	if game.current_player != AI_PLAYER_ID:
		return
	await get_tree().create_timer(AI_MOVE_DELAY).timeout
	if game.game_over or get_tree().paused:
		return
	var move: Vector2i = ai.choose_move(_board_coords)
	game.play_at(move)

func _center_board(coords: Array[Vector2i]) -> void:
	if coords.is_empty():
		return

	var min_pos: Vector2 = tile_map_layer.map_to_local(coords[0])
	var max_pos: Vector2 = min_pos

	for coord in coords:
		var pos: Vector2 = tile_map_layer.map_to_local(coord)
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)

	var board_center: Vector2 = (min_pos + max_pos) / 2.0
	tile_map_layer.position = -board_center

# --- DIÁLOGO DE RESULTADO Y VICTORIA/DERROTA ---
func _on_game_won(player_id: int) -> void:
	_clear_highlights()
	print("¡GANÓ EL JUGADOR ", player_id, "!")
	
	result_dialog.visible = true
	result_dialog.modulate.a = 0.0
	result_dialog.scale = Vector2(0.85, 0.85)
	result_dialog.pivot_offset = result_dialog.size / 2.0

	var level_num: int = 1
	var lvl_name: String = level_config.level_name if level_config else "Volcan"
	if get_node_or_null("/root/GameGlobals"):
		level_num = get_node("/root/GameGlobals").selected_level_num

	if player_id == HUMAN_PLAYER_ID:
		# Música de victoria
		if get_node_or_null("/root/AudioManager"):
			get_node("/root/AudioManager").play_music("win")

		result_title.text = "¡VICTORIA!"
		result_title.add_theme_color_override("font_color", Color(0.960784, 0.745098, 0.278431, 1.0))
		result_message.text = "¡Has conquistado el %s (Nivel %d)!" % [lvl_name, level_num]

		var newly_unlocked: bool = false
		if get_node_or_null("/root/GameGlobals"):
			newly_unlocked = get_node("/root/GameGlobals").complete_level(level_num)

		if newly_unlocked:
			var next_lvl = level_num + 1
			unlock_info_label.visible = true
			unlock_info_label.text = "🔓 ¡Felicidades! Se ha desbloqueado el Nivel %d" % next_lvl
		else:
			unlock_info_label.visible = false
	else:
		# Música de derrota
		if get_node_or_null("/root/AudioManager"):
			get_node("/root/AudioManager").play_music("lose")

		result_title.text = "DERROTA"
		result_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
		result_message.text = "La lava ha ganado esta batalla en el %s..." % lvl_name
		unlock_info_label.visible = false

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_dialog, "modulate:a", 1.0, 0.35)
	tween.tween_property(result_dialog, "scale", Vector2(1.0, 1.0), 0.35)

func _on_invalid_move(coord: Vector2i) -> void:
	print("Movimiento inválido en ", coord)

func _highlight_available_cells() -> void:
	_clear_highlights()
	
	if _roulette_active or not game or game.game_over or get_tree().paused:
		return
	
	if game.current_player != HUMAN_PLAYER_ID:
		return
		
	var tile_set: TileSet = tile_map_layer.tile_set
	if not tile_set:
		return
		
	var source: TileSetAtlasSource = tile_set.get_source(SOURCE_ID) as TileSetAtlasSource
	if not source:
		return
		
	var texture: Texture2D = source.texture
	
	for coord in _board_coords:
		if game.board.can_place_at(coord):
			# Limpiar la celda en el TileMapLayer para que no se dibuje doble
			tile_map_layer.set_cell(coord, -1)
			
			var cell_empty_coord: Vector2i = _get_empty_tile_at(coord)
			var region: Rect2 = source.get_tile_texture_region(cell_empty_coord)
			
			# Crear el Sprite2D de reemplazo y agregarlo
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.region_enabled = true
			sprite.region_rect = region
			sprite.position = tile_map_layer.map_to_local(coord)
			sprite.modulate = Color.WHITE
			tile_map_layer.add_child(sprite)
			_highlight_sprites[coord] = sprite
			
			# Crear Tween infinito para el pulso de tamaño y color blanco brillante (modulación)
			var tween = create_tween().set_loops().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Escala y brillo (modulación > 1.0 hace que resalte en blanco brillante)
			tween.tween_property(sprite, "scale", Vector2(1.08, 1.08), 0.6)
			tween.parallel().tween_property(sprite, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.6)
			
			tween.chain().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.6)
			tween.parallel().tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)
			
			_highlight_tweens.append(tween)

func _clear_highlights() -> void:
	for tween in _highlight_tweens:
		if tween and tween.is_running():
			tween.kill()
	_highlight_tweens.clear()
	
	for coord in _highlight_sprites.keys():
		var sprite = _highlight_sprites[coord]
		if is_instance_valid(sprite):
			sprite.queue_free()
		if game and game.board and game.board.get_piece_at(coord) == -1:
			tile_map_layer.set_cell(coord, SOURCE_ID, _get_empty_tile_at(coord))
			
	_highlight_sprites.clear()

# --- RULETA DE CARTAS Y HUD DE CARTA ---
func _init_bottom_card_layout() -> void:
	var cartas_section = $HUD/BottomCategoryBar/Margin/CategoriesHBox/CartasSection
	var slots_hbox = cartas_section.get_node("Margin/VBox/SlotsHBox")
	var slot1 = slots_hbox.get_node("Slot1")
	var slot2 = slots_hbox.get_node("Slot2")
	var slot3 = slots_hbox.get_node("Slot3")
	
	# Ocultar slots secundarios desde el inicio
	slot2.visible = false
	slot3.visible = false
	
	# Hacer que la sección de cartas sea ligeramente más corta (angosta)
	cartas_section.size_flags_stretch_ratio = 0.75
	
	# Desactivar clipping para permitir sobresalir
	cartas_section.clip_contents = false
	cartas_section.get_node("Margin").clip_contents = false
	cartas_section.get_node("Margin/VBox").clip_contents = false
	slots_hbox.clip_contents = false
	slot1.clip_contents = false
	
	# Hacer el slot transparente por defecto (sin borde ni fondo visual)
	slot1.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	slot1.custom_minimum_size = Vector2(64, 88)
	
	# Ocultar el Label original ("Carta I")
	var orig_label = slot1.get_node_or_null("Label")
	if orig_label:
		orig_label.visible = false

func _run_card_roulette() -> void:
	_roulette_active = true
	
	# Crear el overlay de fondo
	_roulette_overlay = ColorRect.new()
	_roulette_overlay.name = "RouletteOverlay"
	_roulette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_roulette_overlay.color = Color(0.04, 0.05, 0.08, 0.9)
	_roulette_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(_roulette_overlay)
	
	# VBox central para título, carrusel y descripción
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	_roulette_overlay.add_child(vbox)
	
	# Título de la ruleta
	var title_label := Label.new()
	title_label.text = "🔮 SELECCIONANDO CARTA DEL NIVEL... 🔮"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.75, 0.28))
	vbox.add_child(title_label)
	
	# Marco visual del carrusel (Viewport contenedor con clip, ahora de ancho 700)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(700, 240)
	frame.clip_contents = true
	
	# Estilo del marco del carrusel
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.10, 0.16, 0.8)
	frame_style.border_width_left = 3
	frame_style.border_width_top = 3
	frame_style.border_width_right = 3
	frame_style.border_width_bottom = 3
	frame_style.border_color = Color(0.29, 0.35, 0.49, 0.8)
	frame_style.corner_radius_top_left = 12
	frame_style.corner_radius_top_right = 12
	frame_style.corner_radius_bottom_right = 12
	frame_style.corner_radius_bottom_left = 12
	frame_style.shadow_color = Color(0, 0, 0, 0.5)
	frame_style.shadow_size = 15
	frame.add_theme_stylebox_override("panel", frame_style)
	vbox.add_child(frame)
	
	# Control intermedio para evitar que el HBox agrande el PanelContainer y rompa el recorte (clip)
	var clipper := Control.new()
	clipper.custom_minimum_size = Vector2(700, 240)
	frame.add_child(clipper)
	
	# HBox Container para las cartas
	var hbox := HBoxContainer.new()
	hbox.position.y = 20 # Centrar verticalmente la carta (200px de altura en un clipper de 240px)
	hbox.add_theme_constant_override("separation", 20)
	clipper.add_child(hbox)
	
	# Generamos una secuencia de 36 cartas (50 iteraciones de la baraja)
	var seq = []
	for r in 50:
		seq.append(0)
		seq.append(1)
		seq.append(2)
		
	# Elegir al azar la carta final (0, 1, o 2)
	randomize()
	_selected_card_type = randi() % 3
	
	# Queremos detenernos en la ronda final del carrusel (entre 30 y 32)
	var stop_idx = 30 + _selected_card_type
	
	# Crear visualmente las cartas en la secuencia
	var card_nodes = []
	for i in seq.size():
		var type = seq[i]
		var card_details = CARD_DETAILS[type]
		
		# Contenedor de la carta
		var card_panel := PanelContainer.new()
		card_panel.custom_minimum_size = Vector2(140, 200)
		card_panel.pivot_offset = Vector2(70, 100)
		
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.15, 0.22, 1.0)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.border_color = Color(0.4, 0.45, 0.6, 0.4)
		card_panel.add_theme_stylebox_override("panel", card_style)
		
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(card_details["texture"])
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_panel.add_child(tex_rect)
		
		hbox.add_child(card_panel)
		card_nodes.append(card_panel)

	# Forzar actualización del layout de la interfaz para obtener tamaños válidos
	await get_tree().process_frame
	
	# Ancho de la carta: 140, Separación: 20
	var step_width = 140 + 20
	
	# Posición del HBox para centrar la carta en stop_idx (Centro en 350 para frame de 700)
	var target_x = 350.0 - (stop_idx * step_width + 70.0)
	
	# Establecer posición inicial
	hbox.position.x = 0
	
	# Animación del carrusel con desaceleración suave
	var roulette_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	roulette_tween.tween_property(hbox, "position:x", target_x, 3.5)
	
	# Al detenerse la ruleta, resaltar la carta seleccionada
	roulette_tween.chain().tween_callback(func():
		var final_card = card_nodes[stop_idx]
		
		# Efecto de escala
		var bounce_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bounce_tween.tween_property(final_card, "scale", Vector2(1.15, 1.15), 0.3)
		
		# Cambiar el borde a dorado brillante
		var final_style: StyleBoxFlat = final_card.get_theme_stylebox("panel").duplicate()
		final_style.border_color = Color(0.96, 0.75, 0.28)
		final_style.shadow_color = Color(0.96, 0.75, 0.28, 0.5)
		final_style.shadow_size = 12
		final_card.add_theme_stylebox_override("panel", final_style)
		
		# Mostrar la descripción de la carta en la ruleta
		var desc_panel := PanelContainer.new()
		desc_panel.custom_minimum_size = Vector2(360, 80)
		desc_panel.modulate.a = 0.0
		
		var desc_style := StyleBoxFlat.new()
		desc_style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
		desc_style.border_width_left = 1
		desc_style.border_width_top = 1
		desc_style.border_width_right = 1
		desc_style.border_width_bottom = 1
		desc_style.border_color = Color(0.96, 0.75, 0.28, 0.5)
		desc_style.corner_radius_top_left = 8
		desc_style.corner_radius_top_right = 8
		desc_style.corner_radius_bottom_right = 8
		desc_style.corner_radius_bottom_left = 8
		desc_panel.add_theme_stylebox_override("panel", desc_style)
		
		var desc_margin := MarginContainer.new()
		desc_margin.add_theme_constant_override("margin_left", 12)
		desc_margin.add_theme_constant_override("margin_top", 8)
		desc_margin.add_theme_constant_override("margin_right", 12)
		desc_margin.add_theme_constant_override("margin_bottom", 8)
		desc_panel.add_child(desc_margin)
		
		var desc_vbox := VBoxContainer.new()
		desc_margin.add_child(desc_vbox)
		
		var desc_title := Label.new()
		desc_title.text = CARD_DETAILS[_selected_card_type]["title"]
		desc_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_title.add_theme_font_size_override("font_size", 14)
		desc_title.add_theme_color_override("font_color", Color(0.96, 0.75, 0.28))
		desc_vbox.add_child(desc_title)
		
		var desc_text := Label.new()
		desc_text.text = CARD_DETAILS[_selected_card_type]["desc"]
		desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_text.add_theme_font_size_override("font_size", 11)
		desc_text.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		desc_vbox.add_child(desc_text)
		
		vbox.add_child(desc_panel)
		
		var fade_desc_tween := create_tween()
		fade_desc_tween.tween_property(desc_panel, "modulate:a", 1.0, 0.4)
		
		# Esperar y cerrar
		fade_desc_tween.chain().tween_interval(2.2)
		fade_desc_tween.chain().tween_callback(func():
			_close_card_roulette()
		)
	)

func _close_card_roulette() -> void:
	if not _roulette_overlay:
		return
		
	var fade_out = create_tween()
	fade_out.tween_property(_roulette_overlay, "modulate:a", 0.0, 0.4)
	fade_out.chain().tween_callback(func():
		_roulette_overlay.queue_free()
		_roulette_overlay = null
		_roulette_active = false
		
		# Configurar la carta única en la barra inferior
		_setup_bottom_card_ui()
		
		# Iniciar turnos del juego
		if game:
			if game.current_player == HUMAN_PLAYER_ID:
				_highlight_available_cells()
			_maybe_trigger_ai_turn()
	)

func _setup_bottom_card_ui() -> void:
	var cartas_section = $HUD/BottomCategoryBar/Margin/CategoriesHBox/CartasSection
	var slots_hbox = cartas_section.get_node("Margin/VBox/SlotsHBox")
	var slot1 = slots_hbox.get_node("Slot1")
	
	# Mover el Label "🎴 CARTAS" debajo del SlotsHBox
	var vbox = cartas_section.get_node("Margin/VBox")
	var header_label = vbox.get_node("HeaderLabel")
	vbox.move_child(header_label, 1)
	
	# Asegurar que el slot1 sea transparente y no dibuje bordes
	slot1.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	# Limpiar hijos dinámicos anteriores de Slot1
	for child in slot1.get_children():
		if child.name == "CardTexture" or child is TextureRect:
			child.queue_free()
		
	# Crear el TextureRect para la carta elegida (CARTA MÁS GRANDE: 80x114)
	var card_details = CARD_DETAILS[_selected_card_type]
	var tex_rect := TextureRect.new()
	tex_rect.name = "CardTexture"
	tex_rect.texture = load(card_details["texture"])
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Posicionamiento elevado y centrado en Slot1 (tamaño 80x114)
	tex_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tex_rect.position = Vector2(-8, -48)
	tex_rect.size = Vector2(80, 114)
	slot1.add_child(tex_rect)
	
	# Conectar hover
	if not slot1.mouse_entered.is_connected(_on_card_mouse_entered):
		slot1.mouse_entered.connect(_on_card_mouse_entered)
	if not slot1.mouse_exited.is_connected(_on_card_mouse_exited):
		slot1.mouse_exited.connect(_on_card_mouse_exited)

func _on_card_mouse_entered() -> void:
	if _selected_card_type == -1 or _roulette_active:
		return
		
	var slot1 = $HUD/BottomCategoryBar/Margin/CategoriesHBox/CartasSection/Margin/VBox/SlotsHBox/Slot1
	var card_details = CARD_DETAILS[_selected_card_type]
	
	if is_instance_valid(_hover_info_panel):
		_hover_info_panel.queue_free()
		
	_hover_info_panel = PanelContainer.new()
	_hover_info_panel.name = "CardHoverInfo"
	_hover_info_panel.custom_minimum_size = Vector2(240, 110)
	_hover_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.96, 0.75, 0.28, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	_hover_info_panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	_hover_info_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	var title_lbl := Label.new()
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.text = card_details["title"]
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.75, 0.28))
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	
	var desc_lbl := Label.new()
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.text = card_details["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_lbl)
	
	hud.add_child(_hover_info_panel)
	
	var slot_global_pos = slot1.global_position
	var target_x = slot_global_pos.x + (slot1.size.x / 2.0) - (240.0 / 2.0)
	var target_y = slot_global_pos.y - 125.0
	
	_hover_info_panel.global_position = Vector2(target_x, target_y + 15.0)
	_hover_info_panel.modulate.a = 0.0
	
	var hover_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(_hover_info_panel, "global_position:y", target_y, 0.25)
	hover_tween.tween_property(_hover_info_panel, "modulate:a", 1.0, 0.25)

func _on_card_mouse_exited() -> void:
	if _hover_pulse_tween and _hover_pulse_tween.is_running():
		_hover_pulse_tween.kill()
		_hover_pulse_tween = null
		
	if is_instance_valid(_hover_info_panel):
		var panel = _hover_info_panel
		_hover_info_panel = null
		
		var hover_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		hover_tween.tween_property(panel, "global_position:y", panel.global_position.y + 10.0, 0.2)
		hover_tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		hover_tween.chain().tween_callback(panel.queue_free)

	_highlight_sprites.clear()
