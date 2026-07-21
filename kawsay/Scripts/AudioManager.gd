extends Node

signal music_volume_changed(value: float)
signal sfx_volume_changed(value: float)

const TRACKS = {
	"menu": "res://Sound/Music/menu.ogg",
	"level": "res://Sound/Music/level.ogg",
	"win": "res://Sound/Music/win.ogg",
	"lose": "res://Sound/Music/lose.ogg"
}

var current_track: String = ""
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

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _fade_tween: Tween

func _ready() -> void:
	_ensure_audio_buses()
	_apply_music_volume()
	_apply_sfx_volume()
	_setup_players()

func _ensure_audio_buses() -> void:
	# Check and create Music bus
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx == -1:
		AudioServer.add_bus()
		music_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")
	
	# Check and create SFX bus
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		AudioServer.add_bus()
		sfx_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

func _setup_players() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.name = "MusicPlayerA"
	_player_a.bus = "Music"
	_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player_a)
	
	_player_b = AudioStreamPlayer.new()
	_player_b.name = "MusicPlayerB"
	_player_b.bus = "Music"
	_player_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player_b)

func play_music(track_name: String, fade_duration: float = 1.0) -> void:
	if not TRACKS.has(track_name):
		push_error("Track no encontrado en AudioManager: " + track_name)
		return
	
	if current_track == track_name:
		var active_p = _get_active_player()
		if active_p and active_p.playing:
			return
	
	current_track = track_name
	var track_path = TRACKS[track_name]
	var stream = load(track_path)
	
	if stream:
		if "loop" in stream:
			stream.loop = true
		elif stream is AudioStreamOggVorbis:
			stream.loop = true
		
		var active_p = _get_active_player()
		var inactive_p = _player_b if active_p == _player_a else _player_a
		
		inactive_p.stream = stream
		inactive_p.volume_db = -80.0
		inactive_p.play()
		
		if _fade_tween and _fade_tween.is_running():
			_fade_tween.kill()
		
		_fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_fade_tween.tween_property(inactive_p, "volume_db", 0.0, fade_duration)
		
		if active_p and active_p.playing:
			_fade_tween.tween_property(active_p, "volume_db", -80.0, fade_duration)
			_fade_tween.chain().tween_callback(active_p.stop)

func _get_active_player() -> AudioStreamPlayer:
	if _player_a and _player_a.playing:
		return _player_a
	if _player_b and _player_b.playing:
		return _player_b
	return null

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
