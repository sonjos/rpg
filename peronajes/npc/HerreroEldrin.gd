extends CharacterBody3D
class_name HerreroEldrin

@export var nombre_npc: String = "Herrero Eldrin"
@export var arma_inicial: ItemData = null
@export var lingotes_requeridos_mejora: int = 3
@export var coste_mejora_fuerza: int = 100

@onready var area_interaccion: Area3D = $AreaInteraccion
@onready var cartel_interaccion: Label3D = $CartelInteraccion
@onready var anim_player: AnimationPlayer = $ModeloHerrero/AnimationPlayer if has_node("ModeloHerrero/AnimationPlayer") else null

var jugador_en_rango: bool = false
var armo_entregada: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	if cartel_interaccion:
		cartel_interaccion.text = "[Z] Forja de Eldrin"
		cartel_interaccion.hide()

	if area_interaccion:
		area_interaccion.collision_layer = 0
		area_interaccion.collision_mask = 2
		area_interaccion.body_entered.connect(_on_body_entered)
		area_interaccion.body_exited.connect(_on_body_exited)

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
		interactuar()

func interactuar() -> void:
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		_mirar_hacia(jugador.global_position)

	if not armo_entregada:
		armo_entregada = true
		if arma_inicial:
			PlayerStats.recoger_item(arma_inicial)
		PlayerStats.fuerza += 5.0
		PlayerStats.stats_changed.emit()
		_mostrar_mensaje("Toma esta espada de hierro. Te dará +5 de Fuerza. ¡Úsala con sabiduría!")
	else:
		_intentar_mejorar_equipo()

func _intentar_mejorar_equipo() -> void:
	if PlayerStats.monedas >= coste_mejora_fuerza:
		PlayerStats.ganar_monedas(-coste_mejora_fuerza)
		PlayerStats.fuerza += 2.0
		PlayerStats.stats_changed.emit()
		_mostrar_mensaje("¡He reforzado tu equipo! Tu fuerza ha aumentado en +2.")
	else:
		_mostrar_mensaje("Puedo reforzar tu arma por %d monedas, pero no tienes suficiente oro." % coste_mejora_fuerza)

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
