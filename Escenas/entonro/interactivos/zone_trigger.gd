@tool
extends Area3D
class_name ZoneTrigger

@export_file("*.tscn", "*.res") var escena_destino: String = "":
	set(val):
		escena_destino = val
		_actualizar_texto()

@export var posicion_aparicion: Vector3 = Vector3.ZERO
@export var mostrar_cartel_en_juego: bool = true

@onready var label_3d: Label3D = $Label3D if has_node("Label3D") else null

func _ready() -> void:
	_actualizar_texto()
	collision_layer = 0
	collision_mask = 2 # Layer 2 (Player)
	
	
	
	if not Engine.is_editor_hint():
		if label_3d and not mostrar_cartel_en_juego:
			label_3d.hide()

func _actualizar_texto() -> void:
	if not label_3d:
		label_3d = get_node_or_null("Label3D") as Label3D
		
	if label_3d:
		if escena_destino.is_empty():
			label_3d.text = "Sin escena asignada"
		else:
			var nombre_limpio = escena_destino.get_file().get_basename().capitalize()
			label_3d.text = "Viajando a:\n" + nombre_limpio

func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
		
	if body.is_in_group("Player") or body.name == "Player":
		if escena_destino.is_empty():
			push_warning("ZoneTrigger: No se ha asignado una escena de destino.")
			return
		
		if posicion_aparicion != Vector3.ZERO:
			PlayerStats.ultimo_punto_control = posicion_aparicion
		
		call_deferred("_cambiar_escena")

func _cambiar_escena() -> void:
	get_tree().change_scene_to_file(escena_destino)
