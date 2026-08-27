extends CharacterBody3D
class_name AldeanoViejito

enum PasoTutorial { 
	INICIO, 
	ESPERANDO_MOVIMIENTO, 
	ESPERANDO_CAMARA, 
	ESPERANDO_ATAQUE, 
	ESPERANDO_BLOQUEO, 
	ESPERANDO_RODAR, 
	ESPERANDO_INVENTARIO, 
	FINALIZADO 
}

var paso_actual: PasoTutorial = PasoTutorial.INICIO

@export var nombre_npc: String = "Anciano Mateo"
@export var recompensa_exp: int = 150


@onready var cartel_interaccion: Label3D = $CartelInteraccion
@onready var anim_player: AnimationPlayer = $Monk2/AnimationPlayer if has_node("Monk2/AnimationPlayer") else null

var jugador_en_rango: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Control para verificar si se movieron en todas las direcciones
var teclas_movimiento_usadas: Dictionary = {"W": false, "A": false, "S": false, "D": false}

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
	if jugador_en_rango and (event.is_action_pressed("Interactuar") or event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_Z)):
		get_viewport().set_input_as_handled()
		interactuar()

func interactuar(_player = null):
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		_mirar_hacia(jugador.global_position)

	match paso_actual:
		PasoTutorial.INICIO:
			_reproducir_animacion("PickUp")
			_mostrar_mensaje("¡Bienvenido al Valle! Usa [W] para avanzar, [S] para retroceder, [A] para la izquierda y [D] para la derecha. ¡Pruébalos!")
			paso_actual = PasoTutorial.ESPERANDO_MOVIMIENTO

		PasoTutorial.ESPERANDO_MOVIMIENTO:
			_mostrar_mensaje("Para moverte usa: [W] Avanzar, [S] Retroceder, [A] Izquierda, [D] Derecha. Muévete un poco.")

		PasoTutorial.ESPERANDO_CAMARA:
			_mostrar_mensaje("Mueve la cámara arrastrando o moviendo el RATÓN para observar a tu alrededor.")

		PasoTutorial.ESPERANDO_ATAQUE:
			_reproducir_animacion("Attack")
			_mostrar_mensaje("Aprende a combatir: Presiona el CLICK IZQUIERDO del ratón para realizar un ataque.")

		PasoTutorial.ESPERANDO_BLOQUEO:
			_mostrar_mensaje("Para defenderte de los golpes enemigos, mantén presionada la tecla [E] para BLOQUEAR.")

		PasoTutorial.ESPERANDO_RODAR:
			_mostrar_mensaje("Si necesitas esquivar un ataque rápido, presiona [Q] para RODAR por el suelo.")

		PasoTutorial.ESPERANDO_INVENTARIO:
			_mostrar_mensaje("Para revisar tus objetos y equipamiento, presiona la tecla [SHIFT] para abrir el INVENTARIO.")

		PasoTutorial.FINALIZADO:
			_reproducir_animacion("PickUp")
			_mostrar_mensaje("¡Ya dominas los controles! Recuerda usar [Z] para hablar con los aldeanos. Ve con el Herrero Eldrin.")

func _comprobar_progreso_tutorial() -> void:
	match paso_actual:
		PasoTutorial.ESPERANDO_MOVIMIENTO:
			if Input.is_key_pressed(KEY_W): teclas_movimiento_usadas["W"] = true
			if Input.is_key_pressed(KEY_A): teclas_movimiento_usadas["A"] = true
			if Input.is_key_pressed(KEY_S): teclas_movimiento_usadas["S"] = true
			if Input.is_key_pressed(KEY_D): teclas_movimiento_usadas["D"] = true

			# Comprueba si ha pulsado las direcciones principales
			if teclas_movimiento_usadas["W"] or teclas_movimiento_usadas["A"] or teclas_movimiento_usadas["S"] or teclas_movimiento_usadas["D"]:
				paso_actual = PasoTutorial.ESPERANDO_CAMARA
				_mostrar_mensaje("¡Bien hecho! Ahora mueve el RATÓN para orientar la CÁMARA a tu alrededor.")

		PasoTutorial.ESPERANDO_CAMARA:
			var event_mouse = Input.get_last_mouse_velocity()
			if event_mouse.length() > 100.0:
				paso_actual = PasoTutorial.ESPERANDO_ATAQUE
				_reproducir_animacion("Attack")
				_mostrar_mensaje("¡Excelente control visual! Ahora realiza un ATAQUE pulsando el CLICK IZQUIERDO del ratón.")

		PasoTutorial.ESPERANDO_ATAQUE:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_just_pressed("ataque"):
				paso_actual = PasoTutorial.ESPERANDO_BLOQUEO
				_mostrar_mensaje("¡Buen golpe! Ahora mantén presionada la tecla [E] para BLOQUEAR los ataques.")

		PasoTutorial.ESPERANDO_BLOQUEO:
			if Input.is_key_pressed(KEY_E) or Input.is_action_just_pressed("bloqueo"):
				paso_actual = PasoTutorial.ESPERANDO_RODAR
				_mostrar_mensaje("¡Buena defensa! Ahora pulsa la tecla [Q] para RODAR y esquivar rápidamente.")

		PasoTutorial.ESPERANDO_RODAR:
			if Input.is_key_pressed(KEY_Q) or Input.is_action_just_pressed("rodar"):
				paso_actual = PasoTutorial.ESPERANDO_INVENTARIO
				_reproducir_animacion("PickUp")
				_mostrar_mensaje("¡Gran maniobra! Por último, presiona la tecla [SHIFT] para abrir tu INVENTARIO.")

		PasoTutorial.ESPERANDO_INVENTARIO:
			if Input.is_key_pressed(KEY_SHIFT) or Input.is_action_just_pressed("inventario"):
				paso_actual = PasoTutorial.FINALIZADO
				PlayerStats.ganar_experiencia(recompensa_exp)
				_reproducir_animacion("PickUp")
				_mostrar_mensaje("¡Tutorial completado! Has aprendido: WASD (mover), RATÓN (cámara), CLICK IZQ (atacar), E (bloquear), Q (rodar), SHIFT (inventario) y Z (interactuar). Has ganado %d EXP." % recompensa_exp)

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
	# Busca primero si existe la nueva UI instanciada
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
