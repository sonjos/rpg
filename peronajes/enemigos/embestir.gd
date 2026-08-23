extends Enemigo_state_machine

@export var attack_speed: float = 6.0 
var attack_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	attack_timer = 0.8
	state_machine.play_anim("Roll")

func physics_update(delta: float) -> void:
	var Player = get_tree().get_first_node_in_group("Player")
	
	if not character:
		return
		
	if Player:
		var direction = (Player.global_position - character.global_position).normalized()
		direction.y = 0
		character.velocity.x = direction.x * attack_speed
		character.velocity.z = direction.z * attack_speed
		character.move_and_slide()
		
	attack_timer -= delta
	if attack_timer <= 0:
		if Player and character.global_position.distance_to(Player.global_position) < 3.0:
			state_machine.transition_to("Mele")
		else:
			state_machine.transition_to("Patrullar")
