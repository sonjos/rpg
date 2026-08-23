extends Enemigo_state_machine

@export var chase_speed: float = 3.5

func enter(_msg: Dictionary = {}) -> void:
	state_machine.play_anim("Run", true) # Activa el loop por código
	
func physics_update(_delta: float) -> void:
	var Player = get_tree().get_first_node_in_group("Player")
	
	if not Player or not character:
		return
	
	var distancia = character.global_position.distance_to(Player.global_position)
	
	if distancia > 10.0:
		state_machine.transition_to("Patrullar")
		return
		
	if distancia < 2.5:
		state_machine.transition_to("Mele")
		return

	var direction = (Player.global_position - character.global_position).normalized()
	direction.y = 0
	
	character.velocity.x = direction.x * chase_speed
	character.velocity.z = direction.z * chase_speed
	character.move_and_slide()
