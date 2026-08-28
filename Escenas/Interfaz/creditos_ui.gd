# res://Escenas/UI/creditos_ui.gd
extends Control



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Esperar los 15 segundos de duración de los créditos
	await get_tree().create_timer(15.0).timeout
	
	# 1. Si los créditos tienen su propio reproductor de música, lo pausamos/detenemos
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.stop()
	
	# Si usas un AudioManager o música global (Autoload), la detienes/cambias aquí
	# if has_node("/root/AudioManager"):
	#     AudioManager.detener_musica()

	# 2. Redirigir al menú principal
	get_tree().change_scene_to_file("res://Escenas/Interfaz/menu_principal.tscn")
	
	# 3. Eliminar la instancia de los créditos para limpiar memoria y detener scripts activos
	queue_free()

func _on_boton_menu_pressed() -> void:
	# Nos aseguramos de quitar la pausa por si el juego la tuviera
	get_tree().paused = false
	
	# Cambia a la escena del menú principal (ajusta la ruta exacta si la tienes en otra carpeta)
	get_tree().change_scene_to_file("res://Escenas/Interfaz/menu_principal.tscn")
