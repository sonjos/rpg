# res://states/state_dead.gd
extends Node

var health_state_machine : Node

func enter() -> void:
	print("Estado de salud: DEAD (Fin del juego)")
	
	# Desactivamos el movimiento del jugador físicamente
	health_state_machine.player.velocity = Vector3.ZERO
	
	# Esta es la línea importante que hablábamos antes:
	# Bloqueamos el movimiento para que no pueda caminar mientras está muerto
	var movement_machine = health_state_machine.player.get_node("State_Machine")
	if movement_machine.has_method("set_state_locked"):
		movement_machine.set_state_locked(true)

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	# Aquí no hacemos nada, el jugador está muerto
	pass
