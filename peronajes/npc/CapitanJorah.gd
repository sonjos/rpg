extends CharacterBody3D
class_name CapitanJorah

@export var nombre_npc: String = "Capitán Jorah"
@export var coste_pasaje: int = 30
@export var destino_posicion: Vector3 = Vector3(120.0, 2.0, -80.0) # Coordenadas de Costa Norte
@export var es_puerto_bruma: bool = true

@onready var area_interaccion: Area3D = $AreaInteraccion
@onready var cartel_interaccion: Label3D = $CartelInteraccion
@onready var anim_player: AnimationPlayer = $ModeloCapitan/AnimationPlayer if has_node("ModeloCapitan/AnimationPlayer") else null

var jugador_en_rango: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	if cartel_interaccion:
		cartel_interaccion.text = "[Z] Viajar con Jorah"
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

	var destino_nombre = "la Costa Norte" if es_puerto_bruma else "Puerto Bruma"

	if PlayerStats.monedas >= coste_pasaje:
		PlayerStats.ganar_monedas(-coste_pasaje)
		_mostrar_mensaje("¡Izad las velas! Zarpamos hacia %s." % destino_nombre)
		_teletransportar_jugador(jugador)
	else:
		_mostrar_mensaje("El pasaje hacia %s cuesta %d monedas. Vuelve cuando tengas el oro." % [destino_nombre, coste_pasaje])

func _teletransportar_jugador(jugador: Node3D) -> void:
	if jugador:
		await get_tree().create_timer(1.0).timeout
		jugador.global_position = destino_posicion

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
