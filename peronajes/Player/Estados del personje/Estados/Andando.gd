# res://states/Andando.gd
extends State

func enter() -> void: 
	character.play_anim("walk")

func exit() -> void: 
	pass

func physics_update(_delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= state_machine.gravity * _delta
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir == Vector2.ZERO:
		state_machine.transition_to("Quieto")
		return

	if Input.is_action_pressed("Correr") and PlayerStats.current_stamina > 1.0:
		state_machine.transition_to("Correr")
		return

	var direction = (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	character.velocity.x = direction.x * state_machine.walk_speed
	character.velocity.z = direction.z * state_machine.walk_speed
		
	character.move_and_slide()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and character.is_on_floor(): 
		state_machine.transition_to("Saltar")
	elif event.is_action_pressed("Rodar") and PlayerStats.current_stamina >= state_machine.roll_stamina_cost:
		state_machine.transition_to("Rodar")
	elif event.is_action_pressed("Agarrar"):
		state_machine.transition_to("Agarrar")
	elif event.is_action_pressed("ataque"):
		state_machine.transition_to("Ataque")
	elif event.is_action_pressed("Bloqueo"): 
		state_machine.transition_to("Bloqueo")
