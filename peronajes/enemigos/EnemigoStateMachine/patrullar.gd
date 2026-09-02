extends Enemigo_state_machine

var move_direction: Vector3 = Vector3.FORWARD
var change_direction_time: float = 3.0
var timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	timer = change_direction_time
	state_machine.play_anim("Walk", true) # Activa el loop por código

func physics_update(delta: float) -> void:
	var Player = get_tree().get_first_node_in_group("Player")
	if Player and character:
		var distancia = character.global_position.distance_to(Player.global_position)
		if distancia < 6.0:
			state_machine.transition_to("Perseguir")
			return
			
	timer -= delta
	if timer <= 0:
		move_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		timer = change_direction_time
	
	if character:
		character.velocity.x = move_direction.x * state_machine.move_speed
		character.velocity.z = move_direction.z * state_machine.move_speed
		character.move_and_slide()
