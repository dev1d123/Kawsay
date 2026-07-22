class_name AutoGameDemo
extends Node2D

@export var level_config: LevelConfig = preload("res://Data/level_10.tres")

const AI_PLAYER_ID := 1   # Volcán
const HUMAN_PLAYER_ID := 2 # Restaurador

var board_view: BoardView
var game: GameManager
var ai_volcan: AIStrategy
var ai_restaurador: AIStrategy
var move_timer: Timer
var restart_delay: float = 2.0

func _ready():
	_setup_board()

func _setup_board():
	# Cargar la escena completa dani.tscn
	var scene = load("res://Scene/DaniPrueba/dani.tscn")
	board_view = scene.instantiate()
	board_view.is_demo = true
	board_view.level_config = level_config  # opcional, ya se carga internamente
	add_child(board_view)

	# Ocultar el HUD (por si acaso, aunque el modo demo no lo crea)
	if board_view.has_node("HUD"):
		board_view.get_node("HUD").visible = false

	# Ajustar cámara para que se vea bien en el menú
	if board_view.camera:
		board_view.camera.zoom = Vector2(0.4, 0.4)
		board_view.camera.position = Vector2.ZERO

	# Ahora board_view._ready() ya se ejecutó con is_demo true,
	# creando el tablero y el GameManager (board_view.game)
	game = board_view.game
	if not game:
		push_error("AutoGameDemo: No se pudo obtener game de board_view")
		return

	var hex_board = game.board  # asumiendo que GameManager tiene board

	# Crear las IA
	ai_volcan = AIMinimax.new(hex_board, AI_PLAYER_ID, HUMAN_PLAYER_ID, level_config.get_max_required_length(), 3, 0.1)
	ai_restaurador = AIMinimax.new(hex_board, HUMAN_PLAYER_ID, AI_PLAYER_ID, level_config.get_max_required_length(), 2, 0.2)

	# Conectar señales del juego
	game.turn_changed.connect(_on_turn_changed)
	game.game_won.connect(_on_game_won)

	# Iniciar el primer turno (comienza el volcán)
	game.current_player = AI_PLAYER_ID
	_on_turn_changed(game.current_player)

func _on_turn_changed(player_id: int):
	if move_timer:
		move_timer.stop()
		move_timer.queue_free()
		move_timer = null

	move_timer = Timer.new()
	move_timer.one_shot = true
	move_timer.wait_time = 0.6
	add_child(move_timer)
	move_timer.timeout.connect(_make_ai_move.bind(player_id))
	move_timer.start()

func _make_ai_move(player_id: int):
	if game.game_over:
		return

	var ai: AIStrategy = ai_volcan if player_id == AI_PLAYER_ID else ai_restaurador
	var move = ai.choose_move(board_view._board_coords)
	if move != Vector2i.ZERO:
		game.play_at(move)
	else:
		game.game_over = true
		game.game_won.emit(0)

func _on_game_won(player_id: int):
	print("AutoGame: Ganó ", player_id)
	var restart_timer = Timer.new()
	restart_timer.one_shot = true
	restart_timer.wait_time = restart_delay
	add_child(restart_timer)
	restart_timer.timeout.connect(_restart_game)
	restart_timer.start()

func _restart_game():
	if board_view:
		board_view._kill_all_tweens()
		board_view.queue_free()
		board_view = null
	call_deferred("_setup_board")

func _exit_tree():
	if move_timer:
		move_timer.stop()
		move_timer.queue_free()
	if board_view:
		board_view._kill_all_tweens()
