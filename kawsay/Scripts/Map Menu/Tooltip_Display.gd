extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/MarginContainer/Label

func _ready() -> void:
	panel.visible = false
	layer = 100

	# Estilo: fondo negro semi-transparente con borde sutil
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.65)
	style.border_color = Color(1, 1, 1, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.custom_minimum_size.x = 200
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(_delta: float) -> void:
	if panel.visible:
		var mouse_pos: Vector2 = get_tree().root.get_mouse_position()
		panel.global_position = mouse_pos - Vector2(panel.size.x / 2.0, panel.size.y + 20)

func show_tooltip(text: String) -> void:
	label.text = text
	panel.visible = true
	await get_tree().process_frame
	if panel.visible:
		var mouse_pos: Vector2 = get_tree().root.get_mouse_position()
		panel.global_position = mouse_pos - Vector2(panel.size.x / 2.0, panel.size.y + 20)

func hide_tooltip() -> void:
	panel.visible = false
