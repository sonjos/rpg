extends CharacterBody3D
class_name CapitanJorah

@export var nombre_npc: String = "Capitán Jorah"



@onready var anim_player: AnimationPlayer = $ModeloCapitan/AnimationPlayer if has_node("ModeloCapitan/AnimationPlayer") else null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
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

func interactuar(_player = null):
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		_mirar_hacia(jugador.global_position)

	# Construimos la lista de destinos leyendo directamente desde MapManager.ZONAS_MUNDO
	var destinos_disponibles: Array[Dictionary] = []
	
	for id_zona in MapManager.ZONAS_MUNDO.keys():
		# Si ya estás en esta zona, la omitimos para no mostrar la opción de viaje a ti mismo
		if id_zona == MapManager.zona_actual:
			continue
			
		# Verificamos si el jugador ya ha visitado o desbloqueado la zona
		if MapManager.ha_visitado_zona(id_zona):
			var nombre_zona = MapManager.obtener_nombre_zona(id_zona)
			
			var coste_viaje = 30
			
			destinos_disponibles.append({
				"nombre": nombre_zona,
				"id_zona": id_zona,
				"posicion": Vector3(0.0, 2.0, 0.0), # Coordenadas de llegada ajustables
				"coste": coste_viaje
			})

	if destinos_disponibles.is_empty():
		_mostrar_mensaje("Ya te encuentras en el único destino disponible o no hay más lugares a los que pueda llevarte.")
		return

	# Solicitamos a la UI que despliegue el menú de selección de destinos
	_mostrar_menu_viaje(destinos_disponibles, jugador)
	# Solicitamos a la UI que despliegue el menú de selección de destinos
	_mostrar_menu_viaje(destinos_disponibles, jugador)
func _mostrar_menu_viaje(destinos_disponibles: Array[Dictionary], jugador: Node3D) -> void:
	var ui = get_tree().get_first_node_in_group("HUD")
	if not ui:
		ui = get_node_or_null("/root/" + get_tree().current_scene.name + "/JuegoUI")

	# Llamamos a la función de la caja de diálogo que despliega la lista
	if ui and ui.has_method("mostrar_dialogo_con_lista_destinos"):
		ui.mostrar_dialogo_con_lista_destinos(
			nombre_npc, 
			"¿A qué puerto deseas zarpar, viajero? Elige tu destino:", 
			destinos_disponibles, 
			jugador
		)
	else:
		_mostrar_mensaje("Destinos disponibles listados. (Falta actualizar la CajaDialogoUI)")

func _mostrar_mensaje(texto: String) -> void:
	var ui = get_tree().get_first_node_in_group("HUD")
	if not ui:
		ui = get_node_or_null("/root/" + get_tree().current_scene.name + "/JuegoUI")

	if ui and ui.has_method("mostrar_dialogo"):
		ui.mostrar_dialogo(nombre_npc, texto)

func _mirar_hacia(pos: Vector3) -> void:
	var target = Vector3(pos.x, global_position.y, pos.z)
	if global_position.distance_squared_to(target) > 0.001:
		look_at(target, Vector3.UP)
