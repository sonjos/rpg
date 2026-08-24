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
var mision_aceptada: bool = false
var mision_completada: bool = false
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
	if not mision_aceptada:
		mision_aceptada = true
		var nombre_item_mision = item_mision.nombre if item_mision else "Objeto"
		PlayerStats.aceptar_mision("Caza de Lobos", "Trae los restos requeridos a Lyra.", cantidad_requerida, nombre_item_mision)
		_mostrar_mensaje("Los lobos de la selva están descontrolados. Traéme sus restos y te recompensaré adecuadamente.")
	if mision_completada:
		_mostrar_mensaje("Gracias por tu ayuda previa. Los caminos del norte están más despejados ahora.")
		return

	if not mision_aceptada:
		mision_aceptada = true
		var nombre_item_mision = item_mision.nombre if item_mision else "Objeto"
		PlayerStats.aceptar_mision("Caza de Lobos", "Consigue los restos requeridos.", cantidad_requerida, nombre_item_mision)
		_mostrar_mensaje("Los lobos de la selva están descontrolados. Traéme sus restos y te recompensaré adecuadamente.")

func _comprobar_mision() -> void:
	var conteo: int = 0
	for item in PlayerStats.inventario:
		if item and item.nombre == item_mision.nombre:
			conteo += 1
	
	# Actualizamos el progreso en PlayerStats para que la UI lo lea
	PlayerStats.mision_cantidad_actual = conteo
	PlayerStats.stats_changed.emit()

func _remover_objetos_mision() -> void:
	var removidos: int = 0
	for i in range(PlayerStats.inventario.size() - 1, -1, -1):
		var item = PlayerStats.inventario[i]
		if item and item.nombre == item_mision.nombre:
			PlayerStats.inventario.remove_at(i)
			removidos += 1
			if removidos >= cantidad_requerida:
				break
	PlayerStats.stats_changed.emit()

func _entregar_recompensa_final() -> void:
	mision_completada = true
	if recompensa_item:
		PlayerStats.recoger_item(recompensa_item)
	PlayerStats.ganar_monedas(monedas_recompensa)
	PlayerStats.ganar_experiencia(exp_recompensa)
	_mostrar_mensaje("¡Excelente trabajo! Toma tu recompensa: %d monedas y %d EXP." % [monedas_recompensa, exp_recompensa])

func _mostrar_mensaje(texto: String) -> void:
	var ui = get_tree().get_first_node_in_group("HUD")
	if not ui:
		ui = get_node_or_null("/root/" + get_tree().current_scene.name + "/JuegoUI")

	if ui and ui.has_method("mostrar_dialogo"):
		ui.mostrar_dialogo(nombre_npc, texto)

func _mirar_hacia(pos: Vector3) -> void:
	var target = Vector3(pos.x, global_position.y, pos.z)
	if global_position.distance_squared_to(target) > 0.001:
		# Apuntamos directamente al jugador manteniendo el eje Y plano
		super.look_at(target, Vector3.UP) if "super" in self else look_at(target, Vector3.UP)
		
		# Como los modelos importados suelen mirar hacia el eje Z positivo o negativo,
		# sumamos o ajustamos 180 grados (PI) para que la cara del modelo quede frente al jugador
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
	var ui = get_tree().get_first_node_in_group("HUD")
	if not ui:
		ui = get_node_or_null("/root/" + get_tree().current_scene.name + "/JuegoUI")

	if ui and ui.has_method("ocultar_dialogo"):
		ui.ocultar_dialogo()
