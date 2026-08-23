# res://states/state_hit.gd
extends State

func enter() -> void:
	# Detenemos al personaje momentáneamente al recibir el golpe
	character.velocity.x = 0.0
	character.velocity.z = 0.0

	# Reproducimos la animación de daño usando nuestro diccionario centralizado
	character.play_anim("hit")
	print("Estado: RECIBIENDO DAÑO (Hit)")

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	
	character.move_and_slide()

	# Cuando termine de reproducirse la animación de golpe, devolvemos el control
	var anim_player = character.animation_player
	if anim_player and not anim_player.is_playing() or (anim_player.current_animation != character.anims["hit"]):
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir != Vector2.ZERO:
			state_machine.transition_to("Andando")
		else:
			state_machine.transition_to("Quieto")

func handle_input(_event: InputEvent) -> void:
	# Durante la recepción del golpe el personaje está aturdido y no responde a inputs
	pass
