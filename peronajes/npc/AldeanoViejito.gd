extends CharacterBody3D
class_name AldeanoViejito

enum PasoTutorial { 
	INICIO, 
	TEXTO_TUTORIAL, 
	ESPERANDO_MOVIMIENTO, 
	ESPERANDO_SALTO,
	ESPERANDO_CORRER,
	ESPERANDO_CAMARA, 
	ESPERANDO_ATAQUE, 
	ESPERANDO_BLOQUEO, 
	ESPERANDO_RODAR, 
	ESPERANDO_AGARRAR,
	ESPERANDO_INVENTARIO, 
	ESPERANDO_MISIONES,
	FINALIZADO 
}

var paso_actual: PasoTutorial = PasoTutorial.INICIO

@export var nombre_npc: String = "Anciano Mateo"
@export var recompensa_exp: int = 150

@onready var cartel_interaccion: Label3D = $CartelInteraccion
@onready var anim_player: AnimationPlayer = $Monk2/AnimationPlayer if has_node("Monk2/AnimationPlayer") else null

var jugador_en_rango: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	if cartel_interaccion:
		cartel_interaccion.text = "[Z] Hablar con Mateo"
		cartel_interaccion.hide()

	if anim_player:
		if not anim_player.animation_finished.is_connected(_on_animation_finished):
			anim_player.animation_finished.connect(_on_animation_finished)
		_reproducir_animacion_loop("Idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

	_comprobar_progreso_tutorial()

func _unhandled_input(event: InputEvent) -> void:
	if jugador_en_rango and event.is_action_pressed("Interactuar"):
		get_viewport().set_input_as_handled()
		interactuar()

func interactuar(_player = null):
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		_mirar_hacia(jugador.global_position)

	match paso_actual:
		PasoTutorial.INICIO:
			_mostrar_mensaje("""¡Muchacho, al fin despiertas! Las campanas del templo no han dejado de sonar.
Los cristales del perímetro se han apagado tras la traición de Malakor... Si vas a salir al bosque,
al menos aprende a defenderte. No queremos que la última esperanza acabe en el estómago de un lobo.""")
			paso_actual = PasoTutorial.TEXTO_TUTORIAL

		PasoTutorial.TEXTO_TUTORIAL:
			_reproducir_animacion("PickUp")
			_mostrar_mensaje("¡Bienvenido al Valle! Usa [WASD] para moverte por el mapa.")
			paso_actual = PasoTutorial.ESPERANDO_MOVIMIENTO

		PasoTutorial.ESPERANDO_MOVIMIENTO:
			_mostrar_mensaje("Muévete usando las teclas [W], [A], [S] o [D].")

		PasoTutorial.ESPERANDO_SALTO:
			_mostrar_mensaje("Presiona [ESPACIO] para SALTAR.")

		PasoTutorial.ESPERANDO_CORRER:
			_mostrar_mensaje("Mantén presionado [SHIFT] mientras te mueves para CORRER.")

		PasoTutorial.ESPERANDO_CAMARA:
			_mostrar_mensaje("Mueve el RATÓN para orientar la CÁMARA a tu alrededor.")

		PasoTutorial.ESPERANDO_ATAQUE:
			_reproducir_animacion("Attack")
			_mostrar_mensaje("Presiona el [CLICK IZQUIERDO] del ratón para realizar un ATAQUE.")

		PasoTutorial.ESPERANDO_BLOQUEO:
			_mostrar_mensaje("Mantén presionada la tecla [E] para BLOQUEAR.")

		PasoTutorial.ESPERANDO_RODAR:
			_mostrar_mensaje("Presiona [Q] para RODAR y esquivar un golpe.")

		PasoTutorial.ESPERANDO_AGARRAR:
			_mostrar_mensaje("Presiona la tecla [F] para AGARRAR u interactuar con objetos cercanos.")

		PasoTutorial.ESPERANDO_INVENTARIO:
			_mostrar_mensaje("Presiona la tecla [TAB] para abrir tu INVENTARIO.")

		PasoTutorial.ESPERANDO_MISIONES:
			_mostrar_mensaje("Presiona la tecla [M] para revisar tu Cuaderno de MISIONES.")

		PasoTutorial.FINALIZADO:
			_reproducir_animacion("PickUp")
			_mostrar_mensaje("Las campanas han cesado... Ve al cristal del perímetro y reactívalo antes de que las sombras rodeen el poblado.")

func _comprobar_progreso_tutorial() -> void:
	match paso_actual:
		PasoTutorial.ESPERANDO_MOVIMIENTO:
			if Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_back") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				paso_actual = PasoTutorial.ESPERANDO_SALTO
				_mostrar_mensaje("¡Bien! Ahora prueba a SALTAR presionando [ESPACIO].")

		PasoTutorial.ESPERANDO_SALTO:
			if Input.is_action_just_pressed("jump"):
				paso_actual = PasoTutorial.ESPERANDO_CORRER
				_mostrar_mensaje("¡Buen salto! Ahora mantén [SHIFT] para CORRER unos pasos.")

		PasoTutorial.ESPERANDO_CORRER:
			if Input.is_action_pressed("Correr") and (Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_back") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
				paso_actual = PasoTutorial.ESPERANDO_CAMARA
				_mostrar_mensaje("¡Agilidad impecable! Mueve el RATÓN para controlar la CÁMARA.")

		PasoTutorial.ESPERANDO_CAMARA:
			var event_mouse = Input.get_last_mouse_velocity()
			if event_mouse.length() > 100.0:
				paso_actual = PasoTutorial.ESPERANDO_ATAQUE
				_reproducir_animacion("Attack")
				_mostrar_mensaje("¡Excelente! Ahora realiza un ATAQUE pulsando el [CLICK IZQUIERDO].")

		PasoTutorial.ESPERANDO_ATAQUE:
			if Input.is_action_just_pressed("ataque"):
				paso_actual = PasoTutorial.ESPERANDO_BLOQUEO
				_mostrar_mensaje("¡Buen golpe! Mantén presionada la tecla [E] para BLOQUEAR.")

		PasoTutorial.ESPERANDO_BLOQUEO:
			if Input.is_action_pressed("Bloqueo"):
				paso_actual = PasoTutorial.ESPERANDO_RODAR
				_mostrar_mensaje("¡Defensa lista! Presiona [Q] para RODAR y esquivar.")

		PasoTutorial.ESPERANDO_RODAR:
			if Input.is_action_just_pressed("Rodar"):
				paso_actual = PasoTutorial.ESPERANDO_AGARRAR
				_mostrar_mensaje("¡Gran esquiva! Presiona la tecla [F] para AGARRAR objetos.")

		PasoTutorial.ESPERANDO_AGARRAR:
			if Input.is_action_just_pressed("Agarrar"):
				paso_actual = PasoTutorial.ESPERANDO_INVENTARIO
				_reproducir_animacion("PickUp")
				_mostrar_mensaje("¡Perfecto! Ahora presiona [TAB] para abrir el INVENTARIO.")

		PasoTutorial.ESPERANDO_INVENTARIO:
			if Input.is_action_just_pressed("Inventario"):
				paso_actual = PasoTutorial.ESPERANDO_MISIONES
				_mostrar_mensaje("¡Bien hecho! Por último, presiona [M] para abrir el panel de MISIONES.")

		PasoTutorial.ESPERANDO_MISIONES:
			if Input.is_action_just_pressed("Misiones"):
				paso_actual = PasoTutorial.FINALIZADO
				PlayerStats.ganar_experiencia(recompensa_exp)
				_reproducir_animacion("PickUp")
				
				# Notifica al gestor del evento para detener el sonido de las campanas
				var valle = get_tree().get_first_node_in_group("ValleManager")
				if valle and valle.has_method("detener_campanas"):
					valle.detener_campanas()

				_mostrar_mensaje("¡Entrenamiento completado! Has ganado %d EXP. Las campanas han parado, pero el peligro sigue. Ve al Cristal del Perímetro." % recompensa_exp)

func _reproducir_animacion(nombre_anim: String) -> void:
	if anim_player and anim_player.has_animation(nombre_anim):
		anim_player.play(nombre_anim)

func _reproducir_animacion_loop(nombre_anim: String) -> void:
	if anim_player and anim_player.has_animation(nombre_anim):
		var anim = anim_player.get_animation(nombre_anim)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play(nombre_anim)

func _on_animation_finished(_anim_name: StringName) -> void:
	_reproducir_animacion_loop("Idle")

func _mostrar_mensaje(texto: String) -> void:
	var ui_nueva = get_tree().get_first_node_in_group("HUD")
	if ui_nueva and ui_nueva.has_method("mostrar_dialogo"):
		ui_nueva.mostrar_dialogo(nombre_npc, texto)
	else:
		push_warning("No se encontró ningún nodo en el grupo 'HUD' con el método mostrar_dialogo")

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
