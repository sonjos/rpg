# res://scripts/actores/npcs/NpcInteractuable.gd
extends Area3D

@export var nombre_npc: String = "Aldeano Viejito"
@export_multiline var dialogo: String = "¡Las campanas del templo no han dejado de sonar!\nLos cristales del perímetro se han apagado... Si vas\na salir al bosque, ten mucho cuidado."

var player_en_rango: bool = false

# Método llamado cuando se interactúa vía RayCast
func interactuar() -> void:
	hablar()

func hablar() -> void:
	
	get_tree().call_group("HUD", "mostrar_dialogo", nombre_npc, dialogo)

# Interacción física directa (al pulsar tecla dentro del Area3D)
func _unhandled_input(event: InputEvent) -> void:
	if player_en_rango and event.is_action_pressed("Interactuar"):
		hablar()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_en_rango = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_en_rango = false
		get_tree().call_group("HUD", "ocultar_dialogo")
