# res://scripts/entorno/PuertaMazmorra3D.gd
extends StaticBody3D

@export var esta_bloqueada: bool = false
var esta_abierta: bool = false

func interactuar() -> void:
	if esta_bloqueada:
		get_tree().call_group("HUD", "mostrar_dialogo", "Puerta", "La puerta está sellada. Necesitas activar el mecanismo.")
		return
		
	if not esta_abierta:
		abrir_puerta()

func abrir_puerta() -> void:
	esta_abierta = true
	get_tree().call_group("HUD", "mostrar_dialogo", "Puerta", "La pesada puerta de piedra se abre...")
	# Eleva la puerta en Y para abrir el paso
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 4.0, 1.5)
