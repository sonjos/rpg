# res://autoload/AudioManager.gd
extends Node

# Creamos múltiples reproductores de audio para permitir solapar sonidos (ej. abrir menú mientras suena un paso)
var player_ui: AudioStreamPlayer
var players_sfx: Array[AudioStreamPlayer] = []
const NUM_SFX_PLAYERS: int = 5
var current_sfx_index: int = 0

func _ready() -> void:
	# Configurar el canal exclusivo para Interfaz / Menús
	player_ui = AudioStreamPlayer.new()
	player_ui.bus = "Efectos" # Puedes cambiarlo a un bus "UI" si creas uno en el mezclador
	add_child(player_ui)
	
	# Configurar un pool de reproductores para los efectos de sonido (SFX) en 2D generales
	for i in range(NUM_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "Efectos" # Puedes cambiarlo a un bus "SFX" si creas uno
		add_child(sfx_player)
		players_sfx.append(sfx_player)

# --- REPRODUCIR SONIDOS DE INTERFAZ (UI) ---
func reproducir_ui(stream: AudioStream) -> void:
	if stream:
		player_ui.stream = stream
		player_ui.play()

# --- REPRODUCIR EFECTOS GENERALES (SFX 2D) ---
func reproducir_sfx(stream: AudioStream) -> void:
	if stream:
		var player = players_sfx[current_sfx_index]
		player.stream = stream
		player.play()
		# Rotamos el índice del pool para permitir solapar sonidos idénticos sin cortar el anterior
		current_sfx_index = (current_sfx_index + 1) % NUM_SFX_PLAYERS