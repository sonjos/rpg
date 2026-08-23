# res://states/Rodar.gd
extends State

@export var Rodar_speed : float = 9.0
@export var stamina_cost : float = 20.0
var Rodar_direction : Vector3 = Vector3.FORWARD

func enter() -> void:
	# Consumimos estamina al esquivar (si tienes el sistema activo)
	if PlayerStats.current_stamina >= stamina_cost:
		PlayerStats.current_stamina -= stamina_cost
	else:
		# Si no hay estamina, volvemos a Quieto inmediatamente
		state_machine.transition_to("Quieto")
		return

	# Reproducimos la animación de esquive usando nuestro diccionario
	character.play_anim("roll")
	
	# Determinamos hacia dónde esquivar según el input actual, o hacia adelante por defecto
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir != Vector2.ZERO:
		Rodar_direction = (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		# Si está quieto, esquiva hacia donde mira el personaje
		Rodar_direction = -character.global_transform.basis.z



func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta

	# Mantenemos el impulso del esquive en la dirección calculada
	character.velocity.x = Rodar_direction.x * Rodar_speed
	character.velocity.z = Rodar_direction.z * Rodar_speed
	
	character.move_and_slide()

	# Nota: Para salir del estado de Rodar, podemos esperar a que termine la animación
	# o comprobar si el AnimationPlayer ya no está reproduciendo "Rodar".
	var anim_player = character.animation_player
	if anim_player and not anim_player.is_playing() or (anim_player.current_animation != character.anims["roll"]):
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir != Vector2.ZERO:
			state_machine.transition_to("Andando")
		else:
			state_machine.transition_to("Quieto")
	# 2. Limitamos para que no baje de 0
	PlayerStats.current_stamina = max(0.0, PlayerStats.current_stamina)
	
func handle_input(_event: InputEvent) -> void:
	# Durante el esquive normalmente no permitimos interrumpir con otros inputs (invulnerabilidad/compromiso de animación)
	pass
