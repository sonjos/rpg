# res://states/state_hit.gd
extends Node

var health_state_machine : Node
@export var hit_duration : float = 0.3 # Tiempo que dura la animación/pausa de daño
var timer : float = 0.0

func enter() -> void:
	timer = 0.0
	print("Estado de salud: HIT (Recibiendo daño)")
	# Aquí podrías disparar una animación de "hit" o "flicker"
	# health_state_machine.player.animation_tree.set("parameters/playback/travel", "hit")

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	timer += delta
	
	# Cuando termine el tiempo de reacción, volvemos a estar vivos
	if timer >= hit_duration:
		health_state_machine.transition_to("State_Alive")
