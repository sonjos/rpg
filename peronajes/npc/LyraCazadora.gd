# res://Escenas/NPCs/lyra_cazadora.gd
extends CharacterBody3D
class_name LyraCazadora

@export var nombre_npc: String = "Lyra la Cazadora"
@export var item_mision: ItemData = null
@export var cantidad_requerida: int = 1
@export var recompensa_item: ItemData = null
@export var monedas_recompensa: int = 150
@export var exp_recompensa: int = 120

@onready var area_interaccion: Area3D = $AreaInteraccion
@onready var cartel_interaccion: Label3D = $CartelInteraccion
@onready var anim_player: AnimationPlayer = $ModeloLyra/AnimationPlayer if has_node("ModeloLyra/AnimationPlayer") else null

var jugador_en_rango: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	if cartel_interaccion:
		cartel_interaccion.text = "[Z] Hablar con Lyra"
		cartel_interaccion.hide()

	if area_interaccion:
		area_interaccion.collision_layer = 0
		area_interaccion.collision_mask = 2
		area_interaccion.body_entered.connect(_on_body_entered)
		area_interaccion.body_exited.connect(_on_body_exited)

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

	if QuestManager.mision_completada:
		_mostrar_mensaje("Gracias por tu ayuda previa. Los caminos del norte están más despejados ahora.")
		return

	if QuestManager.mision_aceptada:
		QuestManager.actualizar_progreso()
		if QuestManager.mision_cantidad_actual >= cantidad_requerida:
			_remover_objetos_mision()
			_entregar_recompensa_final()
		else:
			_mostrar_mensaje("¿Cómo va esa caza? Vuelve cuando consigas todos los restos requeridos.")
		return

	# Búsqueda directa y blindada de la caja de diálogo en la escena activa
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogoUI")
	if not caja_dialogo:
		var current_scene = get_tree().current_scene
		if current_scene:
			caja_dialogo = current_scene.find_child("CajaDialogoUI", true, false)

	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo_con_opciones"):
		var nombre_item_mision = item_mision.nombre if item_mision else "Objeto"
		
		caja_dialogo.mostrar_dialogo_con_opciones(
			nombre_npc,
			"Los lobos de la selva están descontrolados. ¿Aceptas cazaros y traerme sus restos?",
			"Aceptar Misión",
			func():
				QuestManager.aceptar_mision("Caza de Lobos", "Consigue los restos requeridos.", cantidad_requerida, nombre_item_mision)
				_mostrar_mensaje("¡Perfecto! Ve al bosque y tráeme los huesos de lobo."),
			"Rechazar",
			func():
				_mostrar_mensaje("Vaya... avísame si cambias de opinión.")
		)
	else:
		print("ERROR CRÍTICO: No se encuentra la caja de diálogo para mostrar opciones.")

func _remover_objetos_mision() -> void:
	var removidos: int = 0
	for i in range(InventarioManager.inventario.size() - 1, -1, -1):
		var slot = InventarioManager.inventario[i]
		if slot and slot.has("item") and slot["item"] != null:
			if item_mision and slot["item"].nombre == item_mision.nombre:
				var cantidad_en_slot = slot["cantidad"]
				var cantidad_necesaria = cantidad_requerida - removidos
				
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

func _entregar_recompensa_final() -> void:
	QuestManager.completar_mision()
	if recompensa_item:
		PlayerStats.recoger_item(recompensa_item)
	PlayerStats.ganar_monedas(monedas_recompensa)
	PlayerStats.ganar_experiencia(exp_recompensa)
	_mostrar_mensaje("¡Excelente trabajo! Toma tu recompensa: %d monedas y %d EXP." % [monedas_recompensa, exp_recompensa])

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
