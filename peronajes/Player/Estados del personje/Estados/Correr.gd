# res://states/Correr.gd
extends State

func enter() -> void: 
	character.play_anim("run")

func exit() -> void: 
	pass

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= state_machine.gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if not Input.is_action_pressed("Correr") or PlayerStats.current_stamina <= 0.0 or input_dir == Vector2.ZERO:
		if input_dir != Vector2.ZERO: 
			state_machine.transition_to("Andando")
		else: 
			state_machine.transition_to("Quieto")
		return

	PlayerStats.current_stamina -= state_machine.stamina_drain_rate * delta
	PlayerStats.current_stamina = max(0.0, PlayerStats.current_stamina)
	PlayerStats.emit_signal("stats_changed")

	var direction = (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	character.velocity.x = direction.x * state_machine.run_speed
	character.velocity.z = direction.z * state_machine.run_speed
		
	character.move_and_slide()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and character.is_on_floor():
		state_machine.transition_to("Saltar")
	elif event.is_action_pressed("Rodar") and PlayerStats.current_stamina >= state_machine.roll_stamina_cost:
		state_machine.transition_to("Rodar")
