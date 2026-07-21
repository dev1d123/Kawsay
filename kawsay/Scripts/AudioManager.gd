extends Node

signal music_volume_changed(value: float)
signal sfx_volume_changed(value: float)

var music_volume: float = 0.8:
	set(val):
		music_volume = clamp(val, 0.0, 1.0)
		_apply_music_volume()
		music_volume_changed.emit(music_volume)

var sfx_volume: float = 0.8:
	set(val):
		sfx_volume = clamp(val, 0.0, 1.0)
		_apply_sfx_volume()
		sfx_volume_changed.emit(sfx_volume)

func _ready() -> void:
	_apply_music_volume()
	_apply_sfx_volume()

func set_music_volume(value: float) -> void:
	music_volume = value

func set_sfx_volume(value: float) -> void:
	sfx_volume = value

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func _apply_music_volume() -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))

func _apply_sfx_volume() -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))
