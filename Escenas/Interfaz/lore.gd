extends ScrollContainer

# Esto intercepta la rueda del ratón en cualquier parte del ScrollContainer y mueve la barra
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_vertical -= 40 # Velocidad al subir
				accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_vertical += 40 # Velocidad al bajar
				accept_event()
