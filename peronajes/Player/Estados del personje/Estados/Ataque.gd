extends State

@onready var espada_colision: CollisionShape3D = $"../../HitboxAtaque/CollisionShape3D"

var combo_step : int = 1
var can_queue_next : bool = false
var enemigos_golpeados_ataque1: Array = []  # Rastrear enemigos golpeados en attack_1
var enemigos_golpeados_ataque2: Array = []  # Rastrear enemigos golpeados en attack_2

func enter() -> void:
	combo_step = 1
	can_queue_next = false
	enemigos_golpeados_ataque1.clear()  # Limpiar enemigos del ataque anterior
	enemigos_golpeados_ataque2.clear()
	
	character.velocity.x = 0.0
	character.velocity.z = 0.0
	
	# Capturamos el cursor del ratón al empezar a atacar
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 1. Aceleración de ataque según la estadística de Agilidad
	var anim_player = character.animation_player
	if anim_player:
		var agilidad_multiplicador = PlayerStats.obtener_agilidad_total() if PlayerStats.has_method("obtener_agilidad_total") else 1.0
		anim_player.speed_scale = max(1.0, agilidad_multiplicador)

	character.play_anim("attack_1")
	
	if espada_colision:
		espada_colision.disabled = false
		
	var hitbox = character.get_node_or_null("HitboxAtaque")
	if hitbox:
		hitbox.monitoring = true
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)

func exit() -> void:
	if espada_colision:
		espada_colision.disabled = true
		
	var hitbox = character.get_node_or_null("HitboxAtaque")
	if hitbox and hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.disconnect(_on_hitbox_body_entered)
		
	var anim_player = character.animation_player
	if anim_player:
		anim_player.speed_scale = 1.0
		
	combo_step = 1
	can_queue_next = false
	enemigos_golpeados_ataque1.clear()
	enemigos_golpeados_ataque2.clear()

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	character.move_and_slide()
	
	var anim_player = character.animation_player
	if not anim_player:
		return
		
	var pos_anim = anim_player.current_animation_position
	var largo_anim = anim_player.current_animation_length
	
	if pos_anim >= (largo_anim * 0.2):
		can_queue_next = true
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir != Vector2.ZERO and pos_anim >= (largo_anim * 0.7):
		state_machine.transition_to("Andando")
		return

	if not anim_player.is_playing() or (anim_player.current_animation != character.anims["attack_1"] and anim_player.current_animation != character.anims["attack_2"]):
		if input_dir != Vector2.ZERO:
			state_machine.transition_to("Andando")
		else:
			state_machine.transition_to("Quieto")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("ataque") and combo_step == 1 and can_queue_next:
		combo_step = 2
		can_queue_next = false
		enemigos_golpeados_ataque2.clear()  # Limpiar para el segundo ataque
		character.play_anim("attack_2")
		
		if espada_colision:
			espada_colision.disabled = false
		var hitbox = character.get_node_or_null("HitboxAtaque")
		if hitbox:
			hitbox.monitoring = true

func _on_hitbox_body_entered(body: Node3D) -> void:
	# Determinar cuál lista de enemigos golpeados usar según el ataque actual
	var enemigos_golpeados = enemigos_golpeados_ataque1 if combo_step == 1 else enemigos_golpeados_ataque2
	
	# Evitar aplicar daño múltiples veces al mismo enemigo en el mismo ataque
	if body in enemigos_golpeados:
		return
	
	# 1. Comprobación para enemigos normales con nodo Vida
	var nodo_vida = body.get_node_or_null("Enemigo_state_machine/Vida")
	var fuerza_total = PlayerStats.obtener_fuerza_total() if PlayerStats.has_method("obtener_fuerza_total") else 0.0
	var dano_total = state_machine.attack_damage_base + fuerza_total
	
	print("ATAQUE CONECTADO - Daño Base: ", state_machine.attack_damage_base, " + Fuerza: ", fuerza_total, " = Total: ", dano_total)

	if nodo_vida and nodo_vida.has_method("recibir_dano"):
		enemigos_golpeados.append(body)  # Marcar como golpeado
		nodo_vida.recibir_dano(dano_total)
		var enemy_state_machine = body.get_node_or_null("Enemigo_state_machine")
		if enemy_state_machine:
			PlayerStats.actualizar_vida_enemigo(nodo_vida.vida_actual, enemy_state_machine.vida_maxima)
	
	# 2. Comprobación directa para Jefes (JefeBase)
	elif body.has_method("take_damage"):
		enemigos_golpeados.append(body)  # Marcar como golpeado
		body.take_damage(dano_total)
