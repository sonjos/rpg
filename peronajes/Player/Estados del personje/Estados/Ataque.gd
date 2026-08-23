extends State

# --- EXPORT PARA CONFIGURAR EL DAÑO DESDE EL INSPECTOR ---
@export var dano_base: float = 15.0 # Cambia este valor directamente en el Inspector

@onready var espada_colision: CollisionShape3D = $"../../HitboxAtaque/CollisionShape3D"

var combo_step : int = 1
var can_queue_next : bool = false

func enter() -> void:
	combo_step = 1
	can_queue_next = false
	character.velocity.x = 0.0
	character.velocity.z = 0.0
	
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
		character.play_anim("attack_2")
		
		if espada_colision:
			espada_colision.disabled = false
		var hitbox = character.get_node_or_null("HitboxAtaque")
		if hitbox:
			hitbox.monitoring = true

func _on_hitbox_body_entered(body: Node3D) -> void:
	# 1. Comprobación para enemigos normales con nodo Vida
	var nodo_vida = body.get_node_or_null("Enemigo_state_machine/Vida")
	var dano_total = dano_base + (PlayerStats.obtener_fuerza_total() if PlayerStats.has_method("obtener_fuerza_total") else 0.0)

	if nodo_vida and nodo_vida.has_method("recibir_dano"):
		nodo_vida.recibir_dano(dano_total)
		PlayerStats.actualizar_vida_enemigo(nodo_vida.vida_actual, nodo_vida.vida_maxima)
	
	# 2. Comprobación directa para Jefes (JefeBase)
	elif body.has_method("take_damage"):
		body.take_damage(dano_total)
