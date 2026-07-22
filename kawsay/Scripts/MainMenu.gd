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

	# Conectar sonidos de botones
	_connect_click_sfx(self)
	var tree := get_tree()

	tree.node_added.connect(_on_node_added)

	tree_exited.connect(func():
		if tree.node_added.is_connected(_on_node_added):
			tree.node_added.disconnect(_on_node_added)
	)

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

	# Aplicar las 2 fuentes globales (MoonlitFlow-Regular y MoonlitFlow-Italic) a todo el texto del menú
	_apply_custom_fonts(self)

	# Aplicar texturas con tiling de sillar.png a las opciones del menú
	_apply_sillar_tiling_styles()

	# Construir tarjetas dinámicas de nivel
	_build_level_cards()

	# Animación de entrada inicial del título y menú principal
	main_menu_container.modulate.a = 0.0
	main_menu_container.position.y += 20
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_menu_container, "modulate:a", 1.0, 0.6)
	tween.tween_property(main_menu_container, "position:y", main_menu_container.position.y - 20, 0.6)

func _apply_custom_fonts(node: Node) -> void:
	var font_reg = load("res://Font/MoonlitFlow-Regular.ttf")
	var font_ita = load("res://Font/MoonlitFlow-Italic.ttf")
	
	if node is Label or node is Button or node is LineEdit or node is RichTextLabel:
		var node_name = node.name.to_lower()
		if "sub" in node_name or "desc" in node_name or "badge" in node_name or "info" in node_name:
			node.add_theme_font_override("font", font_ita)
		else:
			node.add_theme_font_override("font", font_reg)
			
	for child in node.get_children():
		_apply_custom_fonts(child)

func _apply_sillar_tiling_to_button(btn: Button, tint_normal: Color, tint_hover: Color, text_color: Color = Color(0.12, 0.14, 0.20)) -> void:
	if not btn:
		return
		
	# Hacer el fondo del botón vacío para evitar que opaque los fondos
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
		
	# Agregar ColorRect sólido detrás de todo
	var solid_bg = btn.get_node_or_null("SolidBG")
	if not solid_bg:
		solid_bg = ColorRect.new()
		solid_bg.name = "SolidBG"
		solid_bg.layout_mode = 1
		solid_bg.anchors_preset = 15
		solid_bg.anchor_right = 1.0
		solid_bg.anchor_bottom = 1.0
		solid_bg.grow_horizontal = 2
		solid_bg.grow_vertical = 2
		solid_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		solid_bg.show_behind_parent = true
		btn.add_child(solid_bg)
		btn.move_child(solid_bg, 0)
	solid_bg.color = tint_normal

	# Agregar sillar.png repetido encima de SolidBG pero detrás de la tipografía
	var tex = load("res://Sprites/Prueba/sillar.png")
	if not tex:
		return
		
	var sillar_rect: TextureRect = btn.get_node_or_null("SillarBG")
	if not sillar_rect:
		sillar_rect = TextureRect.new()
		sillar_rect.name = "SillarBG"
		sillar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sillar_rect.texture = tex
		sillar_rect.stretch_mode = TextureRect.STRETCH_TILE
		sillar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sillar_rect.show_behind_parent = true
		btn.add_child(sillar_rect)
		btn.move_child(sillar_rect, 1)
		
	var tile_scale = 0.06
	sillar_rect.scale = Vector2(tile_scale, tile_scale)
	sillar_rect.self_modulate = tint_normal
	
	# Colores de texto oscuros para máximo contraste y legibilidad sobre tonos pastel
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_focus_color", text_color)
	
	var update_size = func():
		if is_instance_valid(btn):
			if is_instance_valid(solid_bg):
				solid_bg.size = btn.size
			if is_instance_valid(sillar_rect):
				sillar_rect.size = btn.size / tile_scale
			
	update_size.call()
	if not btn.resized.is_connected(update_size):
		btn.resized.connect(update_size)
		
	btn.mouse_entered.connect(func():
		if is_instance_valid(solid_bg):
			solid_bg.color = tint_hover
		if is_instance_valid(sillar_rect):
			sillar_rect.self_modulate = tint_hover
	)
	btn.mouse_exited.connect(func():
		if is_instance_valid(solid_bg):
			solid_bg.color = tint_normal
		if is_instance_valid(sillar_rect):
			sillar_rect.self_modulate = tint_normal
	)

func _apply_sillar_tiling_styles() -> void:
	# Botón JUGAR (Pastel Menta Suave)
	_apply_sillar_tiling_to_button(
		play_button,
		Color(0.68, 0.88, 0.78),
		Color(0.78, 0.95, 0.86),
		Color(0.08, 0.25, 0.18)
	)
	
	# Botones Generales (Pastel Crema / Sillar de Arequipa Claro)
	var norm_color = Color(0.92, 0.90, 0.85)
	var hov_color = Color(0.98, 0.96, 0.92)
	var dark_txt = Color(0.16, 0.16, 0.22)
	
	for btn in [settings_button, credits_button, help_button, credits_back_button, settings_back_button, level_select_back_button, test_unlock_button]:
		_apply_sillar_tiling_to_button(btn, norm_color, hov_color, dark_txt)
		
	# Botón SALIR (Pastel Coral / Rosado Suave)
	_apply_sillar_tiling_to_button(
		quit_button,
		Color(0.94, 0.72, 0.74),
		Color(0.98, 0.82, 0.84),
		Color(0.38, 0.12, 0.15)
	)

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
	print("[LOG MainMenu] === EVENTO CLICK RECIBIDO EN TARJETA DE NIVEL ===")
	print("[LOG MainMenu] Nivel pulsado: %d | Nivel máximo desbloqueado: %d" % [level_num, max_unlocked_level])

	var card: LevelCardItem = _card_items.get(level_num, null)
	var level_name = "Nivel %d" % level_num
	var config_path = "res://Data/level_%d.tres" % level_num
	if ResourceLoader.exists(config_path):
		var cfg = load(config_path) as LevelConfig
		if cfg and not cfg.level_name.is_empty():
			level_name = cfg.level_name

	if level_num <= max_unlocked_level:
		print("[LOG MainMenu] Nivel %d DESBLOQUEADO (%s). Iniciando nivel..." % [level_num, level_name])
		_show_log_banner("Iniciando Nivel %d: %s" % [level_num, level_name])

		if card:
			card.play_bounce()

		if get_node_or_null("/root/GameGlobals"):
			print("[LOG MainMenu] Invocando GameGlobals.select_and_start_level(%d)..." % level_num)
			get_node("/root/GameGlobals").select_and_start_level(level_num)
		else:
			print("[LOG MainMenu] ALERTA: /root/GameGlobals no existe. Cambiando directamente a dani.tscn...")
			var err = get_tree().change_scene_to_file("res://Scene/DaniPrueba/dani.tscn")
			print("[LOG MainMenu] Resultado de cambio directo: %d" % err)
	else:
		print("[LOG MainMenu] Nivel %d BLOQUEADO. Requiere superar nivel %d." % [level_num, level_num - 1])
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

func _on_node_added(node: Node) -> void:
	if node is Button:
		_connect_button(node)

func _connect_click_sfx(node: Node) -> void:
	if node is Button:
		_connect_button(node)
	for child in node.get_children():
		_connect_click_sfx(child)

func _connect_button(btn: Button) -> void:
	if not btn.pressed.is_connected(_play_button_click):
		btn.pressed.connect(_play_button_click)

func _play_button_click() -> void:
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("button_click")
