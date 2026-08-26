# res://Escenas/NPCs/lyra_cazadora.gd
extends CharacterBody3D
class_name LyraCazadora

@export var nombre_npc: String = "Lyra la Cazadora"
@export var recompensa_item: ItemData = null # Opcional si deseas darle un ítem extra aparte de oro/exp

@onready var cartel_interaccion: Label3D = $CartelInteraccion
@onready var anim_player: AnimationPlayer = $ModeloLyra/AnimationPlayer if has_node("ModeloLyra/AnimationPlayer") else null

var jugador_en_rango: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	if cartel_interaccion:
		cartel_interaccion.text = "[Z] Hablar con Lyra"
		cartel_interaccion.hide()

	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if jugador_en_rango and (event.is_action_pressed("Interactuar") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		interactuar()

func interactuar() -> void:
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		_mirar_hacia(jugador.global_position)

	# Si ya superó las misiones del catálogo
	if QuestManager.indice_mision_actual > QuestManager.CATALOGO_MISIONES.size():
		_mostrar_mensaje("Has completado todas mis misiones. ¡El destino de Aethelgard está en tus manos!")
		return

	var datos_mision = QuestManager.obtener_mision_actual()

	if QuestManager.mision_completada:
		# Avanzamos a la siguiente misión automáticamente al hablar de nuevo
		QuestManager.avanzar_siguiente_mision()
		if QuestManager.indice_mision_actual > QuestManager.CATALOGO_MISIONES.size():
			_mostrar_mensaje("¡Increíble! Has terminado la última cacería con éxito.")
			return
		datos_mision = QuestManager.obtener_mision_actual()

	if QuestManager.mision_aceptada:
		QuestManager.actualizar_progreso()
		if QuestManager.mision_cantidad_actual >= datos_mision["Req"]:
			_remover_objetos_mision(datos_mision["item_nombre"], datos_mision["Req"])
			_entregar_recompensa_final(datos_mision["oro"], datos_mision["exp"])
		else:
			_mostrar_mensaje("¿Cómo va esa caza? Vuelve cuando consigas todos los restos requeridos.")
		return

	# Búsqueda de la caja de diálogo para aceptar la misión activa
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogoUI")
	if not caja_dialogo:
		var current_scene = get_tree().current_scene
		if current_scene:
			caja_dialogo = current_scene.find_child("CajaDialogoUI", true, false)

	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo_con_opciones"):
		caja_dialogo.mostrar_dialogo_con_opciones(
			nombre_npc,
			datos_mision["dialogo"],
			"Aceptar Misión",
			func():
				# Pasamos directamente el nombre del ítem en formato String definido en el catálogo
				QuestManager.aceptar_mision(datos_mision["titulo"], datos_mision["desc"], datos_mision["Req"], datos_mision["item_nombre"])
				_mostrar_mensaje(datos_mision["aceptar"]),
			"Rechazar",
			func():
				_mostrar_mensaje("Vaya... avísame si cambias de opinión.")
		)
	else:
		print("ERROR CRÍTICO: No se encuentra la caja de diálogo para mostrar opciones.")

func _remover_objetos_mision(nombre_item_req: String, cantidad_req: int) -> void:
	var removidos: int = 0
	for i in range(InventarioManager.inventario.size() - 1, -1, -1):
		var slot = InventarioManager.inventario[i]
		if slot and slot.has("item") and slot["item"] != null:
			if slot["item"].nombre == nombre_item_req:
				var cantidad_en_slot = slot["cantidad"]
				var cantidad_necesaria = cantidad_req - removidos
				
				if cantidad_en_slot >= cantidad_necesaria:
					slot["cantidad"] -= cantidad_necesaria
					removidos += cantidad_necesaria
					if slot["cantidad"] <= 0:
						InventarioManager.inventario.remove_at(i)
					break
				else:
					removidos += cantidad_en_slot
					InventarioManager.inventario.remove_at(i)
					
	InventarioManager.inventario_actualizado.emit()
	QuestManager.actualizar_progreso()

func _entregar_recompensa_final(oro: int, exp: int) -> void:
	QuestManager.completar_mision()
	if recompensa_item:
		PlayerStats.recoger_item(recompensa_item)
	PlayerStats.ganar_monedas(oro)
	PlayerStats.ganar_experiencia(exp)
	_mostrar_mensaje("¡Excelente trabajo! Toma tu recompensa: %d monedas y %d EXP." % [oro, exp])

func _mostrar_mensaje(texto: String) -> void:
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogoUI")
	if not caja_dialogo:
		var current_scene = get_tree().current_scene
		if current_scene:
			caja_dialogo = current_scene.find_child("CajaDialogoUI", true, false)

	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo"):
		caja_dialogo.mostrar_dialogo(nombre_npc, texto)

func _mirar_hacia(pos: Vector3) -> void:
	var target = Vector3(pos.x, global_position.y, pos.z)
	if global_position.distance_squared_to(target) > 0.001:
		super.look_at(target, Vector3.UP) if "super" in self else look_at(target, Vector3.UP)
		rotate_object_local(Vector3.UP, PI)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		jugador_en_rango = true
		if cartel_interaccion:
			cartel_interaccion.show()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		jugador_en_rango = false
		if cartel_interaccion:
			cartel_interaccion.hide()
		_ocultar_dialogo()

func _ocultar_dialogo() -> void:
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogoUI")
	if not caja_dialogo:
		var current_scene = get_tree().current_scene
		if current_scene:
			caja_dialogo = current_scene.find_child("CajaDialogoUI", true, false)

	if caja_dialogo and caja_dialogo.has_method("ocultar_dialogo"):
		caja_dialogo.ocultar_dialogo()
