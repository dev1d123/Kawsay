extends Button
class_name LevelCardItem

signal card_selected(level_num: int)

@onready var icon_label: Label = $Margin/HBox/Icon
@onready var name_label: Label = $Margin/HBox/InfoVBox/NameLabel
@onready var sub_label: Label = $Margin/HBox/InfoVBox/SubLabel
@onready var badge_label: Label = $Margin/HBox/StatusBadge/BadgeLabel

var _level_num: int = 1
var _is_unlocked: bool = false
var _level_name: String = ""

func setup_card(level_num: int, level_name: String, is_unlocked: bool) -> void:
	_level_num = level_num
	_level_name = level_name
	_is_unlocked = is_unlocked
	
	if not is_inside_tree():
		await ready
		
	name_label.text = level_name

	# Aplicar fuentes personalizadas MoonlitFlow a las etiquetas
	var font_reg = load("res://Font/MoonlitFlow-Regular.ttf")
	var font_ita = load("res://Font/MoonlitFlow-Italic.ttf")
	if name_label:
		name_label.add_theme_font_override("font", font_reg)
	if sub_label:
		sub_label.add_theme_font_override("font", font_ita)
	if badge_label:
		badge_label.add_theme_font_override("font", font_ita)

	# Hacer el fondo del botón vacío para evitar que opaque los fondos
	var empty_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_style)
	add_theme_stylebox_override("hover", empty_style)
	add_theme_stylebox_override("pressed", empty_style)
	add_theme_stylebox_override("focus", empty_style)

	# Agregar ColorRect sólido detrás de todo
	var solid_bg = get_node_or_null("SolidBG")
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
		add_child(solid_bg)
		move_child(solid_bg, 0)

	# Aplicar tiling de sillar.png escalado para repetirse MÚLTIPLES VECES
	var tex = load("res://Sprites/Prueba/sillar.png")
	var sillar_rect: TextureRect = get_node_or_null("SillarBG")
	if tex:
		if not sillar_rect:
			sillar_rect = TextureRect.new()
			sillar_rect.name = "SillarBG"
			sillar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sillar_rect.texture = tex
			sillar_rect.stretch_mode = TextureRect.STRETCH_TILE
			sillar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sillar_rect.show_behind_parent = true
			add_child(sillar_rect)
			move_child(sillar_rect, 1)
			
		var tile_scale = 0.06
		sillar_rect.scale = Vector2(tile_scale, tile_scale)
		
		var update_size = func():
			if is_instance_valid(self):
				if is_instance_valid(solid_bg):
					solid_bg.size = size
				if is_instance_valid(sillar_rect):
					sillar_rect.size = size / tile_scale
				
		update_size.call()
		if not resized.is_connected(update_size):
			resized.connect(update_size)
	
	if is_unlocked:
		modulate = Color(1.0, 1.0, 1.0)
		if solid_bg:
			solid_bg.color = Color(0.18, 0.22, 0.32)
		if sillar_rect:
			sillar_rect.self_modulate = Color(0.90, 0.92, 0.96)
		var icon_str = ""
		icon_label.text = icon_str
		name_label.add_theme_color_override("font_color", Color(0.12, 0.15, 0.24))
		badge_label.text = "DESBLOQUEADO"
		badge_label.add_theme_color_override("font_color", Color(0.1, 0.55, 0.3))
		sub_label.text = "Nivel %d • Activo" % level_num
		sub_label.add_theme_color_override("font_color", Color(0.15, 0.5, 0.35))
	else:
		modulate = Color(0.9, 0.9, 0.9)
		if solid_bg:
			solid_bg.color = Color(0.10, 0.11, 0.15)
		if sillar_rect:
			sillar_rect.self_modulate = Color(0.78, 0.80, 0.84)
		icon_label.text = ""
		name_label.add_theme_color_override("font_color", Color(0.3, 0.32, 0.38))
		badge_label.text = "BLOQUEADO"
		badge_label.add_theme_color_override("font_color", Color(0.65, 0.25, 0.25))
		sub_label.text = "Supera el Nivel %d" % (level_num - 1)
		sub_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		
	# Simular grosor/bold usando un outline del mismo color que el texto
	for lbl in [name_label, sub_label, badge_label]:
		if is_instance_valid(lbl):
			var color = lbl.get_theme_color("font_color")
			if lbl.has_theme_color_override("font_color"):
				color = lbl.get_theme_color("font_color")
			lbl.add_theme_color_override("font_outline_color", color)
			lbl.add_theme_constant_override("outline_size", 2)

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	
	pressed.connect(func():
		print("[LOG LevelCardItem] CLICK FÍSICO DETECTADO en Tarjeta Nivel %d (Desbloqueado: %s)" % [_level_num, str(_is_unlocked)])
		card_selected.emit(_level_num)
	)
	
	mouse_entered.connect(func():
		if _is_unlocked:
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.15)
	)
	mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	)

func play_locked_shake() -> void:
	pivot_offset = size / 2.0
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.05, 0.93), 0.08)
	tween.tween_property(self, "scale", Vector2(0.93, 1.05), 0.08)
	tween.tween_property(self, "scale", Vector2(1.03, 0.97), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func play_bounce() -> void:
	pivot_offset = size / 2.0
	var bounce_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	bounce_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
