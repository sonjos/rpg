extends Node

const RUTA_DIRECTORIO: String = "user://saves/"

func _ready() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

func _obtener_ruta_slot(slot_num: int) -> String:
	return RUTA_DIRECTORIO + "partida_slot_" + str(slot_num) + ".save"

func existe_partida(slot_num: int) -> bool:
	return FileAccess.file_exists(_obtener_ruta_slot(slot_num))

func guardar_partida(slot_num: int) -> void:
	var ruta = _obtener_ruta_slot(slot_num)
	var file = FileAccess.open(ruta, FileAccess.WRITE)
	if not file:
		print("Error: No se pudo abrir el archivo de guardado para escribir en el slot ", slot_num)
		return

	var jugador = get_tree().get_first_node_in_group("Player")
	var pos = Vector3.ZERO
	if jugador:
		pos = jugador.global_position

	var datos = {
		"slot": slot_num,
		"escena_actual": get_tree().current_scene.scene_file_path,
		"posicion_jugador": {"x": pos.x, "y": pos.y, "z": pos.z},
		"monedas": 0,
		"fecha_guardado": Time.get_datetime_string_from_system(false, true)
	}
	
	if has_node("/root/PlayerStats"):
		datos["monedas"] = PlayerStats.monedas

	var json_string = JSON.stringify(datos)
	file.store_string(json_string)
	print("Partida guardada con éxito en el slot ", slot_num)

func cargar_partida(slot_num: int) -> bool:
	var ruta = _obtener_ruta_slot(slot_num)
	if not FileAccess.file_exists(ruta):
		print("No existe archivo de guardado en el slot ", slot_num)
		return false

	var file = FileAccess.open(ruta, FileAccess.READ)
	if not file:
		print("Error al leer el archivo del slot ", slot_num)
		return false

	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Error al parsear el JSON de guardado: ", json.get_error_message())
		return false

	var datos = json.get_data()
	
	var escena_a_cargar = datos.get("escena_actual", "res://Escenas/juego/mundo.tscn")
	var resultado = get_tree().change_scene_to_file(escena_a_cargar)
	if resultado != OK:
		print("Error al cambiar a la escena guardada: ", escena_a_cargar)
		return false

	await get_tree().process_frame
	
	if has_node("/root/PlayerStats") and datos.has("monedas"):
		PlayerStats.monedas = datos["monedas"]

	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador and datos.has("posicion_jugador"):
		var p = datos["posicion_jugador"]
		jugador.global_position = Vector3(p["x"], p["y"], p["z"])

	print("Partida cargada correctamente desde el slot ", slot_num)
	return true

func obtener_info_slot(slot_num: int) -> Dictionary:
	var ruta = _obtener_ruta_slot(slot_num)
	if not FileAccess.file_exists(ruta):
		return {"vacio": true, "texto": "Partida Vacía"}

	var file = FileAccess.open(ruta, FileAccess.READ)
	if not file:
		return {"vacio": true, "texto": "Error de lectura"}

	var json = JSON.parse_string(file.get_as_text())
	if not json:
		return {"vacio": true, "texto": "Datos corruptos"}

	var fecha = json.get("fecha_guardado", "Fecha desconocida")
	var monedas = json.get("monedas", 0)
	var texto_resumen = "Slot %d - Monedas: %d\n(%s)" % [slot_num, monedas, fecha]
	
	return {
		"vacio": false,
		"texto": texto_resumen,
		"datos": json
	}

func borrar_partida(slot_num: int) -> void:
	var ruta = _obtener_ruta_slot(slot_num)
	if FileAccess.file_exists(ruta):
		var err = DirAccess.remove_absolute(ruta)
		if err == OK:
			print("Partida del slot ", slot_num, " borrada correctamente.")
		else:
			print("Error al intentar borrar el archivo del slot ", slot_num)
	else:
		print("No existe archivo de guardado para borrar en el slot ", slot_num)
