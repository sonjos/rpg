extends Node
class_name Vida

var vida_actual: float

@onready var state_machine: Node = $".."

func _ready() -> void:
	vida_actual = state_machine.vida_maxima
	print("ENEMIGO INICIADO - Vida: ", vida_actual, " / ", state_machine.vida_maxima)

func recibir_dano(cantidad: float) -> void:
	var vida_anterior = vida_actual
	vida_actual = max(0.0, vida_actual - cantidad)
	print("DAÑO RECIBIDO: ", cantidad, " | Vida: ", vida_anterior, " -> ", vida_actual)
	
	if vida_actual <= 0:
		print("ENEMIGO MUERTO")
		if state_machine and state_machine.has_method("transition_to"):
			state_machine.transition_to("Morir")
	else:
		# Transición opcional a recibir golpe si el enemigo sigue vivo
		if state_machine and state_machine.has_method("transition_to"):
			state_machine.transition_to("RecibirGolpe")
