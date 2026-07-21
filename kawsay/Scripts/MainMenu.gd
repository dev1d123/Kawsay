extends Control

@onready var main_menu_container: Control = $MarginContainer/VBoxContainer
@onready var play_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/PlayButton
@onready var credits_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/CreditsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/QuitButton

@onready var credits_panel: PanelContainer = $CreditsOverlay
@onready var credits_back_button: Button = $CreditsOverlay/MarginContainer/VBoxContainer/BackButton

@onready var log_banner: PanelContainer = $LogBanner
@onready var log_label: Label = $LogBanner/MarginContainer/LogLabel

var _log_tween: Tween

func _ready() -> void:
	# Configuración inicial del panel de créditos y banner de log
	credits_panel.visible = false
	credits_panel.modulate.a = 0.0
	credits_panel.scale = Vector2(0.85, 0.85)

	if log_banner:
		log_banner.visible = false
		log_banner.modulate.a = 0.0

	# Conexión de señales de botones
	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	credits_back_button.pressed.connect(_on_credits_back_pressed)

	# Agregar animaciones de hover a todos los botones
	_setup_button_hover_effects(play_button)
	_setup_button_hover_effects(credits_button)
	_setup_button_hover_effects(quit_button)
	_setup_button_hover_effects(credits_back_button)

	# Animación de entrada inicial del título y menú
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

func _on_play_pressed() -> void:
	# Requisito explícito del prompt: Log("Empezando Juego")
	print("Empezando Juego")
	
	# Banner visual dinámico para notificar en pantalla al usuario
	_show_log_banner("Empezando Juego")

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

	# Se oculta suavemente tras 2.5 segundos
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
