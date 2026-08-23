# res://states/Saltar.gd
extends State

@export var jump_velocity : float = 4.5

func enter() -> void:
	character.velocity.y = jump_velocity
	
	var anim_player = character.find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("Jump"):
		anim_player.play("Jump")

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		character.velocity.x = direction.x * 4.0
		character.velocity.z = direction.z * 4.0
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, 4.0 * delta)
		character.velocity.z = move_toward(character.velocity.z, 0, 4.0 * delta)

	character.move_and_slide()

	if character.is_on_floor():
		if input_dir != Vector2.ZERO:
			state_machine.transition_to("Andando")
		else:
			state_machine.transition_to("Quieto")

func handle_input(_event: InputEvent) -> void:
	pass
