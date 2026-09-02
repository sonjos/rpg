# res://states/Rodar.gd
extends State

var Rodar_direction : Vector3 = Vector3.FORWARD

func enter() -> void:
	# Consumimos estamina al esquivar (si tienes el sistema activo)
	if PlayerStats.current_stamina >= state_machine.roll_stamina_cost:
		PlayerStats.current_stamina -= state_machine.roll_stamina_cost
	else:
		state_machine.transition_to("Quieto")
		return

	character.play_anim("roll")
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir != Vector2.ZERO:
		Rodar_direction = (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		Rodar_direction = -character.global_transform.basis.z

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= state_machine.gravity * delta

	character.velocity.x = Rodar_direction.x * state_machine.roll_speed
	character.velocity.z = Rodar_direction.z * state_machine.roll_speed
	
	character.move_and_slide()

	var anim_player = character.animation_player
	if anim_player and (not anim_player.is_playing() or anim_player.current_animation != character.anims["roll"]):
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir != Vector2.ZERO:
			state_machine.transition_to("Andando")
		else:
			state_machine.transition_to("Quieto")
	PlayerStats.current_stamina = max(0.0, PlayerStats.current_stamina)
	
func handle_input(_event: InputEvent) -> void:
	pass
