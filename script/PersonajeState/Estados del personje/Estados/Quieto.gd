# res://states/Quieto.gd
extends State

func enter() -> void:
	character.velocity.x = 0.0
	character.velocity.z = 0.0
	character.play_anim("Idle")
	
func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	
	character.move_and_slide()
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir != Vector2.ZERO:
		if Input.is_action_pressed("Correr") and PlayerStats.current_stamina > 1.0:
			state_machine.transition_to("Correr")
		else:
			state_machine.transition_to("Andando")
		return

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and character.is_on_floor():
		state_machine.transition_to("Saltar")
	elif event.is_action_pressed("Rodar") and PlayerStats.current_stamina >= 20.0:
		state_machine.transition_to("Rodar")
	elif event.is_action_pressed("Agarrar"):
		state_machine.transition_to("Agarrar")
	elif event.is_action_pressed("ataque"):
		state_machine.transition_to("Ataque")
	elif event.is_action_pressed("Bloqueo"):
		state_machine.transition_to("Bloqueo")
