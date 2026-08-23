extends Node
class_name Vida

@export var vida_maxima: float = 50.0
var vida_actual: float

@onready var state_machine: Node = $".."

func _ready() -> void:
	vida_actual = vida_maxima

func recibir_dano(cantidad: float) -> void:
	vida_actual = max(0.0, vida_actual - cantidad)
	
	if vida_actual <= 0:
		if state_machine and state_machine.has_method("transition_to"):
			state_machine.transition_to("Morir")
	else:
		# Transición opcional a recibir golpe si el enemigo sigue vivo
		if state_machine and state_machine.has_method("transition_to"):
			state_machine.transition_to("RecibirGolpe")
