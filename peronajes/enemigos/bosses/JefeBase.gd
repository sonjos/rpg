extends CharacterBody3D
class_name JefeBase

# Enumeración de estados para evitar colisión de nombres
enum EstadoJefe { IDLE, CHASE, ATTACK_MELEE, ATTACK_SPECIAL, HURT, DIE }
var current_state: EstadoJefe = EstadoJefe.IDLE

# --- CONFIGURACIÓN DE PARÁMETROS DEL JEFE ---
@export_group("Tipo de Jefe")
@export var es_malakor: bool = false
@export var es_sariel: bool = false

@export_group("Estadísticas")
@export var nombre_jefe: String = "Guardián Caído"
@export var max_health: float = 500.0
@export var attack_power: float = 25.0
@export var special_attack_power: float = 40.0
@export var move_speed: float = 3.5
@export var xp_reward: int = 250
@export var gold_reward: int = 150

@export_group("Rangos y Tiempos")
@export var chase_range: float = 15.0
@export var attack_range: float = 2.5
@export var special_attack_cooldown: float = 8.0

# --- REFERENCIAS A NODOS ---
@onready var animation_player: AnimationPlayer = $Knight_Golden_Male/AnimationPlayer
@onready var area_ataque: Area3D = $AreaAtaque
@onready var timer_especial: Timer = $TimerEspecial

var current_health: float = 0.0
var player_target: CharacterBody3D = null
var can_special_attack: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Posición y rotación iniciales para reiniciar al morir el jugador
var posicion_inicial: Vector3
var rotacion_inicial: Vector3

func _ready() -> void:
	current_health = max_health
	posicion_inicial = global_position
	rotacion_inicial = global_rotation

	if es_malakor:
		if _jugador_tiene_espada_rayo():
			max_health *= 0.7
			current_health = max_health

	if animation_player:
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)

	if timer_especial:
		timer_especial.wait_time = special_attack_cooldown
		if not timer_especial.timeout.is_connected(_on_timer_especial_timeout):
			timer_especial.timeout.connect(_on_timer_especial_timeout)
		timer_especial.start()

	if area_ataque:
		if not area_ataque.body_entered.is_connected(_on_area_ataque_body_entered):
			area_ataque.body_entered.connect(_on_area_ataque_body_entered)

	if PlayerStats.has_signal("stats_changed"):
		if not PlayerStats.stats_changed.is_connected(_comprobar_estado_jugador):
			PlayerStats.stats_changed.connect(_comprobar_estado_jugador)

	_cambiar_estado(EstadoJefe.IDLE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if current_state == EstadoJefe.DIE:
		move_and_slide()
		return

	if PlayerStats.is_dead or PlayerStats.current_health <= 0:
		_resetear_posicion()
		return

	if not player_target:
		_buscar_jugador()

	if player_target:
		var dist = global_position.distance_to(player_target.global_position)
		_procesar_fsm(dist, delta)

	move_and_slide()

# --- MÁQUINA DE ESTADOS FINITA (FSM) ---
func _procesar_fsm(dist: float, delta: float) -> void:
	match current_state:
		EstadoJefe.IDLE:
			velocity.x = 0
			velocity.z = 0
			if dist <= chase_range:
				_cambiar_estado(EstadoJefe.CHASE)

		EstadoJefe.CHASE:
			_mirar_hacia(player_target.global_position)
			var dir = (player_target.global_position - global_position).normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

			if dist <= attack_range:
				if can_special_attack:
					_cambiar_estado(EstadoJefe.ATTACK_SPECIAL)
				else:
					_cambiar_estado(EstadoJefe.ATTACK_MELEE)
			elif dist > chase_range * 1.2:
				_cambiar_estado(EstadoJefe.IDLE)

		EstadoJefe.ATTACK_MELEE, EstadoJefe.ATTACK_SPECIAL:
			_mirar_hacia(player_target.global_position)
			velocity.x = move_toward(velocity.x, 0, move_speed * delta)
			velocity.z = move_toward(velocity.z, 0, move_speed * delta)

		EstadoJefe.HURT:
			velocity.x = move_toward(velocity.x, 0, move_speed * delta)
			velocity.z = move_toward(velocity.z, 0, move_speed * delta)

func _reproducir_animacion_loop(nombre_anim: String) -> void:
	if animation_player and animation_player.has_animation(nombre_anim):
		var anim = animation_player.get_animation(nombre_anim)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		animation_player.play(nombre_anim)

func _cambiar_estado(nuevo_estado: EstadoJefe) -> void:
	current_state = nuevo_estado
	
	if player_target and (nuevo_estado == EstadoJefe.ATTACK_MELEE or nuevo_estado == EstadoJefe.ATTACK_SPECIAL):
		_mirar_hacia(player_target.global_position)

	match current_state:
		EstadoJefe.IDLE:
			_reproducir_animacion_loop("Idle")

		EstadoJefe.CHASE:
			_reproducir_animacion_loop("Walk")

		EstadoJefe.ATTACK_MELEE:
			if animation_player and animation_player.has_animation("Punch"):
				animation_player.play("Punch")
			else:
				_ejecutar_golpe_melee()

		EstadoJefe.ATTACK_SPECIAL:
			can_special_attack = false
			if timer_especial:
				timer_especial.start()
			if animation_player and animation_player.has_animation("SwordSlash"):
				animation_player.play("SwordSlash")
			else:
				_ejecutar_golpe_especial()

		EstadoJefe.HURT:
			if animation_player and animation_player.has_animation("hurt"):
				animation_player.play("hurt")

		EstadoJefe.DIE:
			velocity = Vector3.ZERO
			if animation_player and animation_player.has_animation("Death"):
				animation_player.play("Death")
			_procesar_muerte()

func _on_animation_finished(anim_name: StringName) -> void:
	if current_state == EstadoJefe.DIE:
		return

	if anim_name == "Punch":
		_ejecutar_golpe_melee()
	elif anim_name == "SwordSlash":
		_ejecutar_golpe_especial()
	elif anim_name == "hurt":
		_cambiar_estado(EstadoJefe.CHASE)

func _comprobar_estado_jugador() -> void:
	if PlayerStats.is_dead or PlayerStats.current_health <= 0:
		_resetear_posicion()

func _resetear_posicion() -> void:
	if current_state == EstadoJefe.DIE:
		return
	
	global_position = posicion_inicial
	global_rotation = rotacion_inicial
	current_health = max_health
	velocity = Vector3.ZERO
	player_target = null
	can_special_attack = true
	_cambiar_estado(EstadoJefe.IDLE)
	
	PlayerStats.actualizar_vida_enemigo(0, max_health)

func _on_player_died() -> void:
	_resetear_posicion()

func take_damage(amount: float) -> void:
	if current_state == EstadoJefe.DIE:
		return

	current_health = max(0.0, current_health - amount)
	PlayerStats.actualizar_vida_enemigo(current_health, max_health)

	if current_health <= 0:
		_cambiar_estado(EstadoJefe.DIE)
	else:
		_cambiar_estado(EstadoJefe.HURT)

func _procesar_muerte() -> void:
	PlayerStats.reportar_enemigo_muerto()
	PlayerStats.ganar_experiencia(xp_reward)
	PlayerStats.ganar_monedas(gold_reward)
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _ejecutar_golpe_melee() -> void:
	if player_target and global_position.distance_to(player_target.global_position) <= attack_range:
		PlayerStats.take_damage(attack_power)
	
	if current_state != EstadoJefe.DIE:
		_cambiar_estado(EstadoJefe.CHASE)

func _ejecutar_golpe_especial() -> void:
	if player_target and global_position.distance_to(player_target.global_position) <= attack_range * 1.5:
		PlayerStats.take_damage(special_attack_power)
		
		if es_sariel:
			PlayerStats.agilidad = max(0.2, PlayerStats.agilidad - 0.2)
			PlayerStats.stats_changed.emit()

	if current_state != EstadoJefe.DIE:
		_cambiar_estado(EstadoJefe.CHASE)

func _on_area_ataque_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		PlayerStats.actualizar_vida_enemigo(current_health, max_health)
		
		if current_state == EstadoJefe.ATTACK_MELEE or current_state == EstadoJefe.ATTACK_SPECIAL:
			if current_state == EstadoJefe.ATTACK_SPECIAL:
				_ejecutar_golpe_especial()
			else:
				_ejecutar_golpe_melee()

func _buscar_jugador() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_target = players[0]

# --- ORIENTACIÓN AL JUGADOR CORREGIDA ---
func _mirar_hacia(pos: Vector3) -> void:
	var pos_objetivo = Vector3(pos.x, global_position.y, pos.z)
	if global_position.distance_squared_to(pos_objetivo) > 0.001:
		look_at(pos_objetivo, Vector3.UP)
		# Corrige la inversión del modelo 3D aplicándole un giro de 180°
		rotate_object_local(Vector3.UP, PI)

func _jugador_tiene_espada_rayo() -> bool:
	for item in PlayerStats.inventario:
		if item and item.nombre == "Espada_del_Rayo":
			return true
	for slot in PlayerStats.equipo:
		if PlayerStats.equipo[slot] and PlayerStats.equipo[slot].nombre == "Espada_del_Rayo":
			return true
	return false

func _on_timer_especial_timeout() -> void:
	can_special_attack = true
