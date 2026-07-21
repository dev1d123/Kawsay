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
const AI_PLAYER_ID := 1
const HUMAN_PLAYER_ID := 2
const AI_MOVE_DELAY := 0.5
var game: GameManager
var _board_coords: Array[Vector2i]  # <-- se genera UNA vez y se guarda
var ai: AIStrategy
var _highlight_sprites: Dictionary = {}
var _highlight_tweens: Array[Tween] = []
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

	# Generar tablero e iniciar juego
	_board_coords = level_config.generate_coords()
	_center_board(_board_coords) 
	_draw_board(_board_coords)
	_setup_game(_board_coords)
	camera.setup_limits(_board_coords, tile_map_layer, HEX_SIZE)

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

func _draw_board(coords: Array[Vector2i]) -> void:
	tile_map_layer.clear()
	for coord in coords:
		tile_map_layer.set_cell(coord, SOURCE_ID, empty_atlas_coord)

func _unhandled_input(event: InputEvent) -> void:
	if game.game_over or get_tree().paused:
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
		
	var atlas_coord: Vector2i = player1_atlas_coord if player_id == 1 else player2_atlas_coord
	tile_map_layer.set_cell(coord, SOURCE_ID, atlas_coord)

func _on_turn_changed(player_id: int) -> void:
	print("Turno de jugador ", player_id)
	if player_id == HUMAN_PLAYER_ID:
		_highlight_available_cells()
	else:
		_clear_highlights()
	_maybe_trigger_ai_turn()

func _maybe_trigger_ai_turn() -> void:
	if game.game_over or get_tree().paused:
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
	
	if not game or game.game_over or get_tree().paused:
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
	var region: Rect2 = source.get_tile_texture_region(empty_atlas_coord)
	
	for coord in _board_coords:
		if game.board.can_place_at(coord):
			# Limpiar la celda en el TileMapLayer para que no se dibuje doble
			tile_map_layer.set_cell(coord, -1)
			
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
			tile_map_layer.set_cell(coord, SOURCE_ID, empty_atlas_coord)
			
	_highlight_sprites.clear()
