# res://autoload/SaveManager.gd
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

# En SaveManager.gd

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

	# Recopilar datos generales y económicos
	var datos = {
		"slot": slot_num,
		"escena_actual": get_tree().current_scene.scene_file_path,
		"posicion_jugador": {"x": pos.x, "y": pos.y, "z": pos.z},
		"monedas": 0,
		"experiencia": 0,
		"nivel": 1,
		"fecha_guardado": Time.get_datetime_string_from_system(false, true),
		
		# Estado de Misiones (QuestManager)
		"mision": {
			"indice": 1,
			"aceptada": false,
			"completada": false,
			"cantidad_actual": 0
		},
		
		# Estado de Jefes derrotados (se lee de PlayerStats si existe)
		"jefes_derrotados": {
			"guardian_caido": false,
			"sariel": false,
			"malakor": false
		},
		
		# Inventario y equipo
		"inventario": [],
		"equipo": {}
	}
	
	# Guardar PlayerStats si existe
	if has_node("/root/PlayerStats"):
		datos["monedas"] = PlayerStats.monedas
		if "experiencia" in PlayerStats:
			datos["experiencia"] = PlayerStats.experiencia
		if "nivel" in PlayerStats:
			datos["nivel"] = PlayerStats.nivel
		if "equipo" in PlayerStats:
			datos["equipo"] = PlayerStats.equipo
		if "jefes_derrotados" in PlayerStats:
			datos["jefes_derrotados"] = PlayerStats.jefes_derrotados

	# Guardar QuestManager si existe
	if has_node("/root/QuestManager"):
		datos["mision"] = {
			"indice": QuestManager.indice_mision_actual,
			"aceptada": QuestManager.mision_aceptada,
			"completada": QuestManager.mision_completada,
			"cantidad_actual": QuestManager.mision_cantidad_actual
		}

	# Guardar InventarioManager si existe
	if has_node("/root/InventarioManager") and "inventario" in InventarioManager:
		datos["inventario"] = InventarioManager.inventario
	
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
	
	# Restaurar PlayerStats
	if has_node("/root/PlayerStats"):
		if datos.has("monedas"):
			PlayerStats.monedas = datos["monedas"]
		if datos.has("experiencia") and "experiencia" in PlayerStats:
			PlayerStats.experiencia = datos["experiencia"]
		if datos.has("nivel") and "nivel" in PlayerStats:
			PlayerStats.nivel = datos["nivel"]
		if datos.has("equipo") and "equipo" in PlayerStats:
			PlayerStats.equipo = datos["equipo"]
		if datos.has("jefes_derrotados") and "jefes_derrotados" in PlayerStats:
			PlayerStats.jefes_derrotados = datos["jefes_derrotados"]
		if PlayerStats.has_method("emit_signal"):
			PlayerStats.emit_signal("stats_changed")

	# Restaurar QuestManager
	if has_node("/root/QuestManager") and datos.has("mision"):
		var m_data = datos["mision"]
		QuestManager.indice_mision_actual = m_data.get("indice", 1)
		QuestManager.mision_aceptada = m_data.get("aceptada", false)
		QuestManager.mision_completada = m_data.get("completada", false)
		QuestManager.mision_cantidad_actual = m_data.get("cantidad_actual", 0)
		var info_mision = QuestManager.obtener_mision_actual()
		if not info_mision.is_empty():
			QuestManager.mision_activa = info_mision.get("titulo", "")
			QuestManager.descripcion_mision = info_mision.get("desc", "")
			QuestManager.cantidad_requerida = info_mision.get("Req", 0)
			QuestManager.item_objetivo_nombre_ref = info_mision.get("item_nombre", "")
		QuestManager.emit_signal("mision_actualizada")

	# Restaurar InventarioManager
	if has_node("/root/InventarioManager") and datos.has("inventario"):
		InventarioManager.inventario.clear()
		for item_guardado in datos["inventario"]:
			InventarioManager.inventario.append(item_guardado)
			
		if InventarioManager.has_signal("inventario_actualizado"):
			InventarioManager.inventario_actualizado.emit()

	# Posicionar al jugador
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador and datos.has("posicion_jugador"):
		var p = datos["posicion_jugador"]
		jugador.global_position = Vector3(p["x"], p["y"], p["z"])

	# Despachar jefes que ya fueron derrotados anteriormente
	var jefes = get_tree().get_nodes_in_group("Jefes")
	for jefe in jefes:
		if jefe is JefeBase:
			if jefe.es_guardian_caido and PlayerStats.jefes_derrotados.get("guardian_caido", false):
				jefe.queue_free()
			elif jefe.es_sariel and PlayerStats.jefes_derrotados.get("sariel", false):
				jefe.queue_free()
			elif jefe.es_malakor and PlayerStats.jefes_derrotados.get("malakor", false):
				jefe.queue_free()

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
