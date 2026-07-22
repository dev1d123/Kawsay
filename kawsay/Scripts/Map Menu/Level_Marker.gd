class_name LevelMarker
extends Area2D

signal level_selected(level_num: int)

@export var level_number: int = 1
@export var level_name: String = "Nivel 1"
@export var unlocked: bool = true

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D
var _glow_tween: Tween

func _refresh_visual() -> void:
	if label:
		label.text = str(level_number)
	modulate = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5, 0.8)

	if unlocked:
		_start_glow_pulse()
	else:
		_stop_glow_pulse()

func _start_glow_pulse() -> void:
	_stop_glow_pulse()
	_glow_tween = create_tween().set_loops()
	_glow_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(sprite, "modulate", Color(1.3, 1.3, 1.0), 0.7)
	_glow_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.7)

func _stop_glow_pulse() -> void:
	if _glow_tween and _glow_tween.is_running():
		_glow_tween.kill()
	if sprite:
		sprite.modulate = Color.WHITE
func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	_refresh_visual()

func setup(number: int, lvl_name: String, is_unlocked: bool) -> void:
	level_number = number
	level_name = lvl_name
	unlocked = is_unlocked
	if is_inside_tree():
		_refresh_visual()
		
func set_unlocked(value: bool) -> void:
	unlocked = value
	_update_visual()

func _update_visual() -> void:
	modulate = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5, 0.8)

func _on_mouse_entered() -> void:
	var status: String = "" if unlocked else " (bloqueado)"
	TooltipDisplay.show_tooltip(level_name + status)

func _on_mouse_exited() -> void:
	TooltipDisplay.hide_tooltip()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if unlocked:
			TooltipDisplay.hide_tooltip()
			level_selected.emit(level_number)
