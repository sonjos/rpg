extends Node3D

# Ruta de la escena pesada que quieres cargar
var ruta_escena_destino: String = "res://Escenas/juego/escenarios/Valle de Aethelgard.tscn"
var estado_carga: int = 0
var progreso: Array = []

func _ready() -> void:
	# Iniciamos la carga en segundo plano de forma asíncrona
	estado_carga = ResourceLoader.load_threaded_request(ruta_escena_destino)
	if estado_carga != OK:
		print("Error al iniciar la carga en segundo plano.")

func _process(_delta: float) -> void:
	if estado_carga == OK:
		# Consultamos el estado actual del progreso
		var status = ResourceLoader.load_threaded_get_status(ruta_escena_destino, progreso)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var porcentaje = int(progreso[0] * 100)
				print("Cargando... ", porcentaje, "%")
				# Aquí puedes actualizar una barra de progreso o un texto en pantalla si tienes
				# $ProgressBar.value = porcentaje
				
			ResourceLoader.THREAD_LOAD_LOADED:
				# ¡Carga completa! Recuperamos la escena ya empaquetada
				var escena_cargada = ResourceLoader.load_threaded_get(ruta_escena_destino)
				# Cambiamos a la nueva escena de forma fluida
				get_tree().change_scene_to_packed(escena_cargada)
				set_process(false) # Paramos el process para que no siga comprobando
				
			ResourceLoader.THREAD_LOAD_FAILED:
				print("Error: Falló la carga del recurso.")
				set_process(false)
