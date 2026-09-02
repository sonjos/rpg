# res://states/Mele.gd
extends Enemigo_state_machine

var timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	timer = state_machine.attack_cooldown # Iniciar con el tiempo completo de espera
	var Player = get_tree().get_first_node_in_group("Player")
	if Player:
		state_machine.mirar_hacia(Player.global_position)
	state_machine.play_anim("Punch")

func physics_update(delta: float) -> void:
	var Player = get_tree().get_first_node_in_group("Player")
	
	if not Player or not character:
		return
		
	character.velocity.x = 0
	character.velocity.z = 0
	character.move_and_slide()
	
	var distancia = character.global_position.distance_to(Player.global_position)
	
	if distancia > 2.5:
		state_machine.transition_to("Perseguir")
		return
		
	timer -= delta
	if timer <= 0:
		# Girar de nuevo hacia el jugador justo antes del impacto
		state_machine.mirar_hacia(Player.global_position)
		state_machine.play_anim("Punch")
		
		if Player.has_method("recibir_dano_jugador"):
			Player.recibir_dano_jugador(state_machine.fuerza_ataque)
		timer = state_machine.attack_cooldown
