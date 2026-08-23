# res://states/state_alive.gd
extends Node

var health_state_machine : Node

func enter() -> void:
	print("Estado de salud: ALIVE (Salud normal)")

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	# Aquí monitorizamos si la vida llega a 0
	if PlayerStats.current_health <= 0:
		# Si la salud llega a 0, cambiamos al estado de muerte
		get_parent().transition_to("State_Dead")
		
