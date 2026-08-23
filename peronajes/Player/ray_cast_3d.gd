extends RayCast3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Interactuar") and is_colliding():
		var colisionador = get_collider()
		# Verifica si el objeto alcanzado por el rayo tiene una función interactuar()
		if colisionador and colisionador.has_method("Interactuar"):
			colisionador.Interactuar()
