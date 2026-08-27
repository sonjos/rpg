# res://scripts/entorno/HerreroEldrin.gd
extends CharacterBody3D
class_name HerreroEldrin

@export var nombre_npc: String = "Herrero Eldrin"
@export var arma_inicial: ItemData = null
@export var coste_mejora_fuerza: int = 100


@onready var cartel_interaccion: Label3D = $CartelInteraccion
@onready var anim_player: AnimationPlayer = $ModeloHerrero/AnimationPlayer if has_node("ModeloHerrero/AnimationPlayer") else null

var jugador_en_rango: bool = false
var arma_entregada: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	if cartel_interaccion:
		cartel_interaccion.text = "[Z] Hablar con Eldrin"
		cartel_interaccion.hide()

	if anim_player and anim_player.has_animation("Forging"):
		anim_player.play("Forging")

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
		
		var caja_dialogo = _obtener_caja_dialogo()
		if caja_dialogo:
			# Si la caja de diálogo está visible (ya sea con texto plano o con el menú de opciones abierto),
			# pulsando Z de nuevo la cerramos al instante.
			if caja_dialogo.visible:
				_ocultar_dialogo()
				return
			
		interactuar()

func interactuar(_player = null):
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		_mirar_hacia(jugador.global_position)

	if not arma_entregada:
		arma_entregada = true
		if arma_inicial:
			InventarioManager.recoger_item(arma_inicial)
		
		if "fuerza" in PlayerStats:
			PlayerStats.fuerza += 5.0
		if PlayerStats.has_signal("stats_changed"):
			PlayerStats.stats_changed.emit()
			
		_mostrar_mensaje("Toma esta espada de hierro. ¡Úsala con sabiduría!")
	else:
		_abrir_menu_comercio()

func _abrir_menu_comercio() -> void:
	var caja_dialogo = _obtener_caja_dialogo()
	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo_con_opciones"):
		caja_dialogo.mostrar_dialogo_con_opciones(
			nombre_npc,
			"¡Hola de nuevo, viajero! ¿Qué necesitas hoy en la forja?",
			"Mejorar Equipo (%d monedas)" % coste_mejora_fuerza,
			Callable(self, "_intentar_mejorar_equipo"),
			"Ver Tienda",
			Callable(self, "_abrir_interfaz_tienda")
		)
	else:
		_intentar_mejorar_equipo()

func _intentar_mejorar_equipo() -> void:
	if "monedas" in PlayerStats and PlayerStats.monedas >= coste_mejora_fuerza:
		PlayerStats.ganar_monedas(-coste_mejora_fuerza)
		if "fuerza" in PlayerStats:
			PlayerStats.fuerza += 2.0
		if PlayerStats.has_signal("stats_changed"):
			PlayerStats.stats_changed.emit()
		_mostrar_mensaje("¡He reforzado tu equipo con éxito!")
	else:
		_mostrar_mensaje("No tienes suficiente oro. Necesitas %d monedas." % coste_mejora_fuerza)

func _abrir_interfaz_tienda() -> void:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("_abrir_interfaz_tienda"):
		hud._abrir_interfaz_tienda()
	else:
		var interfaz = get_node_or_null("/root/Node3D/JuegoUI")
		if interfaz and interfaz.has_method("_abrir_interfaz_tienda"):
			interfaz._abrir_interfaz_tienda()
		else:
			_mostrar_mensaje("No encuentro la interfaz de la tienda.")

func _mostrar_mensaje(texto: String) -> void:
	var caja_dialogo = _obtener_caja_dialogo()
	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo"):
		caja_dialogo.mostrar_dialogo(nombre_npc, texto)

func _obtener_caja_dialogo() -> Node:
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogoUI")
	if not caja_dialogo:
		var current_scene = get_tree().current_scene
		if current_scene:
			caja_dialogo = current_scene.find_child("CajaDialogoUI", true, false)
	return caja_dialogo

func _mirar_hacia(pos: Vector3) -> void:
	var target = Vector3(pos.x, global_position.y, pos.z)
	if global_position.distance_squared_to(target) > 0.001:
		look_at(target, Vector3.UP)
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
	var caja_dialogo = _obtener_caja_dialogo()
	if caja_dialogo and caja_dialogo.has_method("ocultar_dialogo"):
		caja_dialogo.ocultar_dialogo()
