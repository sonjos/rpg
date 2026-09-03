extends Node3D
class_name ValleManager

@export_category("Audio")
@export var audio_musica_valle: AudioStreamPlayer
@export var audio_campanas: AudioStreamPlayer

func _ready() -> void:
	add_to_group("ValleManager")
	iniciar_evento_campanas()

func iniciar_evento_campanas() -> void:
	# 1. Si la música normal está sonando, bajamos su volumen o la pausamos para dar dramatismo
	if audio_musica_valle and audio_musica_valle.playing:
		audio_musica_valle.volume_db = -10.0 # Reducimos el volumen de fondo
		
	# 2. Iniciar el sonido continuo de campanas
	if audio_campanas and not audio_campanas.playing:
		audio_campanas.volume_db = 0.0
		audio_campanas.play()

func detener_campanas() -> void:
	# Transición suave para desvanecer las campanas y devolver el volumen a la música
	var tween = create_tween().set_parallel(true)
	
	if audio_campanas and audio_campanas.playing:
		tween.tween_property(audio_campanas, "volume_db", -80.0, 2.5)
		tween.chain().tween_callback(audio_campanas.stop)
		
	if audio_musica_valle:
		tween.tween_property(audio_musica_valle, "volume_db", 0.0, 2.5)
