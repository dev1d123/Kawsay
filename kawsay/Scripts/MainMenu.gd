extends Control

const LEVEL_CARD_PREFAB = preload("res://Scene/MenuPrincipal/level_card_item.tscn")

@onready var main_menu_container: Control = $MarginContainer/VBoxContainer
@onready var play_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/PlayButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/SettingsButton
@onready var credits_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/CreditsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/QuitButton
@onready var help_button: Button = $HelpButton

@onready var credits_panel: PanelContainer = $CreditsOverlay
@onready var credits_back_button: Button = $CreditsOverlay/MarginContainer/VBoxContainer/BackButton

@onready var settings_panel: PanelContainer = $SettingsOverlay
@onready var settings_back_button: Button = $SettingsOverlay/MarginContainer/VBoxContainer/BackButton
@onready var music_slider: HSlider = $SettingsOverlay/MarginContainer/VBoxContainer/MusicBox/MusicSlider
@onready var sfx_slider: HSlider = $SettingsOverlay/MarginContainer/VBoxContainer/SfxBox/SfxSlider
@onready var music_val_label: Label = $SettingsOverlay/MarginContainer/VBoxContainer/MusicBox/HeaderHBox/MusicValLabel
@onready var sfx_val_label: Label = $SettingsOverlay/MarginContainer/VBoxContainer/SfxBox/HeaderHBox/SfxValLabel

@onready var log_banner: PanelContainer = $LogBanner
@onready var log_label: Label = $LogBanner/MarginContainer/LogLabel

# Elementos del Selector de Niveles
@onready var level_select_overlay: Control = $LevelSelectOverlay
@onready var level_select_back_button: Button = $LevelSelectOverlay/MarginContainer/VBoxContainer/Footer/BackButton
@onready var test_unlock_button: Button = $LevelSelectOverlay/MarginContainer/VBoxContainer/Footer/TestUnlockButton
@onready var levels_container: VBoxContainer = $LevelSelectOverlay/MarginContainer/VBoxContainer/ScrollContainer/LevelsContainer

var _log_tween: Tween

# Estado de progreso de niveles (por defecto Nivel 1 activo)
var max_unlocked_level: int = 1
var _card_items: Dictionary = {} # level_num -> LevelCardItem

func _ready() -> void:
	# Iniciar música de menú
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").play_music("menu")

	# Configuración inicial de vistas secundarias
	credits_panel.visible = false
	credits_panel.modulate.a = 0.0
	credits_panel.scale = Vector2(0.85, 0.85)

	settings_panel.visible = false
	settings_panel.modulate.a = 0.0
	settings_panel.scale = Vector2(0.85, 0.85)

	if level_select_overlay:
		level_select_overlay.visible = false
		level_select_overlay.modulate.a = 0.0

	if log_banner:
		log_banner.visible = false
		log_banner.modulate.a = 0.0

	# Sincronizar estado global de progreso
	if get_node_or_null("/root/GameGlobals"):
		max_unlocked_level = get_node("/root/GameGlobals").max_unlocked_level

	# Conexión del Singleton de Audio con los HSliders
	if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
		var audio_mgr = get_node("/root/AudioManager")
		music_slider.value = audio_mgr.get_music_volume()
		sfx_slider.value = audio_mgr.get_sfx_volume()
	
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	_update_volume_labels()

	# Conexión de señales de botones del menú principal
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	help_button.pressed.connect(_on_help_pressed)

	credits_back_button.pressed.connect(_on_credits_back_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)

	# Conexión de señales del selector de niveles
	level_select_back_button.pressed.connect(_on_level_back_pressed)
	if test_unlock_button:
		test_unlock_button.pressed.connect(_on_test_unlock_pressed)
		_setup_button_hover_effects(test_unlock_button)

	# Agregar animaciones de hover a botones estándar
	_setup_button_hover_effects(play_button)
	_setup_button_hover_effects(settings_button)
	_setup_button_hover_effects(credits_button)
	_setup_button_hover_effects(quit_button)
	_setup_button_hover_effects(help_button)
	_setup_button_hover_effects(credits_back_button)
	_setup_button_hover_effects(settings_back_button)
	_setup_button_hover_effects(level_select_back_button)

	# Construir tarjetas dinámicas de nivel
	_build_level_cards()

	# Animación de entrada inicial del título y menú principal
	main_menu_container.modulate.a = 0.0
	main_menu_container.position.y += 20
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_menu_container, "modulate:a", 1.0, 0.6)
	tween.tween_property(main_menu_container, "position:y", main_menu_container.position.y - 20, 0.6)

func _build_level_cards() -> void:
	for child in levels_container.get_children():
		child.queue_free()
	_card_items.clear()

	var total_levels: int = 15
	if get_node_or_null("/root/GameGlobals"):
		total_levels = get_node("/root/GameGlobals").TOTAL_LEVELS

	for i in range(1, total_levels + 1):
		var card: LevelCardItem = LEVEL_CARD_PREFAB.instantiate() as LevelCardItem
		levels_container.add_child(card)
		
		var level_name = "Nivel %d" % i
		var config_path = "res://Data/level_%d.tres" % i
		if ResourceLoader.exists(config_path):
			var cfg = load(config_path) as LevelConfig
			if cfg and not cfg.level_name.is_empty():
				level_name = cfg.level_name
		
		var is_unlocked = (i <= max_unlocked_level)
		card.setup_card(i, level_name, is_unlocked)
		card.card_selected.connect(_on_level_card_pressed)
		_card_items[i] = card

func _update_level_cards_ui() -> void:
	var total_levels: int = 15
	if get_node_or_null("/root/GameGlobals"):
		total_levels = get_node("/root/GameGlobals").TOTAL_LEVELS

	for i in range(1, total_levels + 1):
		if _card_items.has(i):
			var card: LevelCardItem = _card_items[i]
			var level_name = "Nivel %d" % i
			var config_path = "res://Data/level_%d.tres" % i
			if ResourceLoader.exists(config_path):
				var cfg = load(config_path) as LevelConfig
				if cfg and not cfg.level_name.is_empty():
					level_name = cfg.level_name
			var is_unlocked = (i <= max_unlocked_level)
			card.setup_card(i, level_name, is_unlocked)

func _setup_button_hover_effects(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)

	btn.mouse_entered.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.18)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18)
	)
	btn.button_down.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.1)
	)
	btn.button_up.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.1)
	)

# --- BOTÓN DE AYUDA (?) ---
func _on_help_pressed() -> void:
	print("Botón de ayuda (?) presionado")
	_show_log_banner("❓ Ayuda / Información (Próximamente)")

	help_button.pivot_offset = help_button.size / 2.0
	var bounce_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(help_button, "scale", Vector2(1.2, 1.2), 0.12)
	bounce_tween.tween_property(help_button, "scale", Vector2(1.0, 1.0), 0.15)

# --- VISTA CONFIGURACIÓN ---
func _on_settings_pressed() -> void:
	settings_panel.visible = true
	settings_panel.pivot_offset = settings_panel.size / 2.0

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.35)
	tween.tween_property(settings_panel, "scale", Vector2(1.0, 1.0), 0.35)

func _on_settings_back_pressed() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.25)
	tween.tween_property(settings_panel, "scale", Vector2(0.85, 0.85), 0.25)
	tween.chain().tween_callback(func(): settings_panel.visible = false)

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

# --- SELECTOR DE NIVELES ---
func _on_play_pressed() -> void:
	print("Abriendo selector de niveles...")
	
	# 1. Animación de salida del menú principal
	var menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	menu_tween.tween_property(main_menu_container, "modulate:a", 0.0, 0.25)
	menu_tween.tween_property(main_menu_container, "scale", Vector2(0.95, 0.95), 0.25)
	menu_tween.chain().tween_callback(func(): main_menu_container.visible = false)

	# 2. Despliegue con Tween de la vista Selector de Niveles
	level_select_overlay.visible = true
	level_select_overlay.modulate.a = 0.0
	level_select_overlay.scale = Vector2(1.05, 1.05)
	level_select_overlay.pivot_offset = level_select_overlay.size / 2.0

	var overlay_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	overlay_tween.tween_property(level_select_overlay, "modulate:a", 1.0, 0.35)
	overlay_tween.tween_property(level_select_overlay, "scale", Vector2(1.0, 1.0), 0.35)

	# 3. Animación escalonada de aparición para tarjetas
	_animate_level_cards_entrance()

func _animate_level_cards_entrance() -> void:
	var total_levels: int = 15
	if get_node_or_null("/root/GameGlobals"):
		total_levels = get_node("/root/GameGlobals").TOTAL_LEVELS

	for i in range(1, min(6, total_levels + 1)):
		var card = _card_items.get(i, null)
		if card:
			card.pivot_offset = card.size / 2.0
			card.modulate.a = 0.0
			card.scale = Vector2(0.8, 0.8)

			var card_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			card_tween.tween_interval(0.05 + i * 0.05)
			card_tween.chain().tween_property(card, "modulate:a", 1.0, 0.25)
			card_tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.25)

func _on_level_back_pressed() -> void:
	var overlay_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	overlay_tween.tween_property(level_select_overlay, "modulate:a", 0.0, 0.25)
	overlay_tween.tween_property(level_select_overlay, "scale", Vector2(0.95, 0.95), 0.25)
	overlay_tween.chain().tween_callback(func(): level_select_overlay.visible = false)

	main_menu_container.visible = true
	main_menu_container.scale = Vector2(0.95, 0.95)
	main_menu_container.pivot_offset = main_menu_container.size / 2.0
	
	var menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_tween.tween_property(main_menu_container, "modulate:a", 1.0, 0.3)
	menu_tween.tween_property(main_menu_container, "scale", Vector2(1.0, 1.0), 0.3)

func _on_level_card_pressed(level_num: int) -> void:
	var card: LevelCardItem = _card_items.get(level_num, null)
	var level_name = "Nivel %d" % level_num
	var config_path = "res://Data/level_%d.tres" % level_num
	if ResourceLoader.exists(config_path):
		var cfg = load(config_path) as LevelConfig
		if cfg and not cfg.level_name.is_empty():
			level_name = cfg.level_name

	if level_num <= max_unlocked_level:
		print("Nivel seleccionado: %s (Nivel %d) [Recurso: %s]" % [level_name, level_num, config_path])
		_show_log_banner("Nivel %d: %s" % [level_num, level_name])

		if card:
			card.play_bounce()
			var tween = create_tween()
			tween.tween_interval(0.2)
			tween.tween_callback(func():
				if get_node_or_null("/root/GameGlobals"):
					get_node("/root/GameGlobals").select_and_start_level(level_num)
			)
	else:
		print("Nivel %d bloqueado (%s): Debes superar el nivel anterior primero." % [level_num, level_name])
		_show_log_banner("🔒 Completa el Nivel %d primero" % (level_num - 1))

		if card:
			card.play_locked_shake()

func _on_test_unlock_pressed() -> void:
	max_unlocked_level += 1
	var total_levels: int = 15
	if get_node_or_null("/root/GameGlobals"):
		total_levels = get_node("/root/GameGlobals").TOTAL_LEVELS

	if max_unlocked_level > total_levels:
		max_unlocked_level = 1

	if get_node_or_null("/root/GameGlobals"):
		get_node("/root/GameGlobals").max_unlocked_level = max_unlocked_level

	_update_level_cards_ui()

	var msg: String
	if max_unlocked_level == 1:
		msg = "⚡ Reiniciado: Solo Nivel 1 activo"
	else:
		msg = "⚡ Nivel %d desbloqueado para pruebas" % max_unlocked_level

	print(msg)
	_show_log_banner(msg)

	var card: LevelCardItem = _card_items.get(max_unlocked_level, null)
	if card:
		card.play_bounce()

func _show_log_banner(message: String) -> void:
	if _log_tween and _log_tween.is_running():
		_log_tween.kill()

	log_label.text = message
	log_banner.visible = true
	log_banner.modulate.a = 0.0
	log_banner.scale = Vector2(0.8, 0.8)
	log_banner.pivot_offset = log_banner.size / 2.0

	_log_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_log_tween.tween_property(log_banner, "modulate:a", 1.0, 0.3)
	_log_tween.tween_property(log_banner, "scale", Vector2(1.0, 1.0), 0.3)

	var fade_tween = create_tween()
	fade_tween.tween_interval(2.5)
	fade_tween.tween_property(log_banner, "modulate:a", 0.0, 0.4)
	fade_tween.tween_callback(func(): log_banner.visible = false)

func _on_credits_pressed() -> void:
	credits_panel.visible = true
	credits_panel.pivot_offset = credits_panel.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(credits_panel, "modulate:a", 1.0, 0.35)
	tween.tween_property(credits_panel, "scale", Vector2(1.0, 1.0), 0.35)

func _on_credits_back_pressed() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(credits_panel, "modulate:a", 0.0, 0.25)
	tween.tween_property(credits_panel, "scale", Vector2(0.85, 0.85), 0.25)
	tween.chain().tween_callback(func(): credits_panel.visible = false)

func _on_quit_pressed() -> void:
	print("Saliendo del juego...")
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().quit())
