extends Control

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

@onready var level1_button: Button = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level1Card
@onready var level2_button: Button = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level2Card
@onready var level3_button: Button = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level3Card

@onready var level1_badge_label: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level1Card/Margin/HBox/StatusBadge/BadgeLabel
@onready var level2_badge_label: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level2Card/Margin/HBox/StatusBadge/BadgeLabel
@onready var level3_badge_label: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level3Card/Margin/HBox/StatusBadge/BadgeLabel

@onready var level1_icon: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level1Card/Margin/HBox/Icon
@onready var level2_icon: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level2Card/Margin/HBox/Icon
@onready var level3_icon: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level3Card/Margin/HBox/Icon

@onready var level1_sub_label: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level1Card/Margin/HBox/InfoVBox/SubLabel
@onready var level2_sub_label: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level2Card/Margin/HBox/InfoVBox/SubLabel
@onready var level3_sub_label: Label = $LevelSelectOverlay/MarginContainer/VBoxContainer/LevelsContainer/Level3Card/Margin/HBox/InfoVBox/SubLabel

var _log_tween: Tween

# Estado de progreso de niveles (por defecto Nivel 1 activo)
var max_unlocked_level: int = 1

func _ready() -> void:
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

	level1_button.pressed.connect(func(): _on_level_card_pressed(1, "Volcan Pichu Pichu"))
	level2_button.pressed.connect(func(): _on_level_card_pressed(2, "Volcan Chachani"))
	level3_button.pressed.connect(func(): _on_level_card_pressed(3, "Volcan Misti"))

	# Agregar animaciones de hover a botones estándar
	_setup_button_hover_effects(play_button)
	_setup_button_hover_effects(settings_button)
	_setup_button_hover_effects(credits_button)
	_setup_button_hover_effects(quit_button)
	_setup_button_hover_effects(help_button)
	_setup_button_hover_effects(credits_back_button)
	_setup_button_hover_effects(settings_back_button)
	_setup_button_hover_effects(level_select_back_button)

	# Configurar interactividad y hover de las tarjetas de nivel
	_setup_level_card_hover(level1_button, 1)
	_setup_level_card_hover(level2_button, 2)
	_setup_level_card_hover(level3_button, 3)

	# Actualizar aspecto visual según niveles desbloqueados
	_update_level_cards_ui()

	# Animación de entrada inicial del título y menú principal
	main_menu_container.modulate.a = 0.0
	main_menu_container.position.y += 20
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_menu_container, "modulate:a", 1.0, 0.6)
	tween.tween_property(main_menu_container, "position:y", main_menu_container.position.y - 20, 0.6)

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

func _setup_level_card_hover(btn: Button, level_num: int) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)

	btn.mouse_entered.connect(func():
		if level_num <= max_unlocked_level:
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.18)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18)
	)

# --- BOTÓN DE AYUDA (?) ---
func _on_help_pressed() -> void:
	print("Botón de ayuda (?) presionado")
	_show_log_banner("❓ Ayuda / Información (Próximamente)")

	# Animación de rebote al pulsar el botón de ayuda
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

	# 3. Animación escalonada (Staggered Tweens) de aparición para cada tarjeta de nivel
	_animate_level_cards_entrance()

func _animate_level_cards_entrance() -> void:
	var cards = [level1_button, level2_button, level3_button]
	for i in range(cards.size()):
		var card = cards[i]
		card.pivot_offset = card.size / 2.0
		card.modulate.a = 0.0
		card.scale = Vector2(0.8, 0.8)

		var card_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.tween_interval(0.1 + i * 0.08)
		card_tween.chain().tween_property(card, "modulate:a", 1.0, 0.3)
		card_tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3)

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

func _on_level_card_pressed(level_num: int, level_name: String) -> void:
	var card_btn: Button
	match level_num:
		1: card_btn = level1_button
		2: card_btn = level2_button
		3: card_btn = level3_button

	if level_num <= max_unlocked_level:
		print("Nivel seleccionado: %s (Nivel %d)" % [level_name, level_num])
		_show_log_banner("Nivel %d: %s" % [level_num, level_name])

		if card_btn:
			card_btn.pivot_offset = card_btn.size / 2.0
			var bounce_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			bounce_tween.tween_property(card_btn, "scale", Vector2(1.1, 1.1), 0.12)
			bounce_tween.tween_property(card_btn, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		print("Nivel %d bloqueado (%s): Debes superar el nivel anterior primero." % [level_num, level_name])
		_show_log_banner("🔒 Completa el Nivel %d primero" % (level_num - 1))

		if card_btn:
			_play_locked_shake(card_btn)

func _play_locked_shake(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1.05, 0.93), 0.08)
	tween.tween_property(node, "scale", Vector2(0.93, 1.05), 0.08)
	tween.tween_property(node, "scale", Vector2(1.03, 0.97), 0.08)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.1)

func _update_level_cards_ui() -> void:
	_update_single_card_ui(level1_button, level1_icon, level1_badge_label, level1_sub_label, 1, "⛰️", "Nivel 1 • Inicial")
	_update_single_card_ui(level2_button, level2_icon, level2_badge_label, level2_sub_label, 2, "🌋", "Nivel 2 • Intermedio")
	_update_single_card_ui(level3_button, level3_icon, level3_badge_label, level3_sub_label, 3, "🔥", "Nivel 3 • Avanzado")

func _update_single_card_ui(btn: Button, icon_label: Label, badge_label: Label, sub_label: Label, level_num: int, unlocked_icon: String, sub_text: String) -> void:
	var is_unlocked = level_num <= max_unlocked_level

	if is_unlocked:
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		icon_label.text = unlocked_icon
		badge_label.text = "DESBLOQUEADO"
		badge_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5, 1.0))
		sub_label.text = sub_text
		sub_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.55, 1.0))
	else:
		btn.modulate = Color(0.65, 0.68, 0.75, 0.6)
		icon_label.text = "🔒"
		badge_label.text = "BLOQUEADO"
		badge_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4, 1.0))
		sub_label.text = "🔒 Supera el Nivel %d" % (level_num - 1)
		sub_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5, 1.0))

func _on_test_unlock_pressed() -> void:
	max_unlocked_level += 1
	if max_unlocked_level > 3:
		max_unlocked_level = 1

	_update_level_cards_ui()

	var msg: String
	if max_unlocked_level == 1:
		msg = "⚡ Reiniciado: Solo Nivel 1 activo"
	else:
		msg = "⚡ Nivel %d desbloqueado para pruebas" % max_unlocked_level

	print(msg)
	_show_log_banner(msg)

	var target_btn: Button
	match max_unlocked_level:
		1: target_btn = level1_button
		2: target_btn = level2_button
		3: target_btn = level3_button

	if target_btn:
		target_btn.pivot_offset = target_btn.size / 2.0
		var pulse_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse_tween.tween_property(target_btn, "scale", Vector2(1.12, 1.12), 0.15)
		pulse_tween.tween_property(target_btn, "scale", Vector2(1.0, 1.0), 0.15)

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
