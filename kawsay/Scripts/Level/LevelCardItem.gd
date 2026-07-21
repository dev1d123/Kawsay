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
	
	if is_unlocked:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		var icon_str = "⛰️"
		if level_num > 10:
			icon_str = "🔥"
		elif level_num > 5:
			icon_str = "🌋"
		icon_label.text = icon_str
		badge_label.text = "DESBLOQUEADO"
		badge_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5, 1.0))
		sub_label.text = "Nivel %d • Activo" % level_num
		sub_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.55, 1.0))
	else:
		modulate = Color(0.65, 0.68, 0.75, 0.6)
		icon_label.text = "🔒"
		badge_label.text = "BLOQUEADO"
		badge_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4, 1.0))
		sub_label.text = "🔒 Supera el Nivel %d" % (level_num - 1)
		sub_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5, 1.0))

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	
	pressed.connect(func():
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
