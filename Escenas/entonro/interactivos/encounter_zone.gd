extends Area3D
class_name EncounterZone

@export var escena_enemigo: PackedScene
@export var cantidad_enemigos: int = 3
@export var radio_aparicion: float = 5.0
@export var es_zona_unica: bool = true

@onready var contenedor_enemigos: Node3D = $ContenedorEnemigos if has_node("ContenedorEnemigos") else self

var zona_activada: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Layer 2 (Player)
	

func _on_body_entered(body: Node3D) -> void:
	if zona_activada and es_zona_unica:
		return
		
	if body.is_in_group("Player") or body.name == "Player":
		zona_activada = true
		_generar_enemigos()

func _generar_enemigos() -> void:
	if not escena_enemigo:
		push_warning("EncounterZone: No se ha asignado una escena de enemigo.")
		return

	for i in range(cantidad_enemigos):
		var enemigo_instancia = escena_enemigo.instantiate() as Node3D
		
		# Offset aleatorio dentro del radio estipulado
		var offset_x: float = randf_range(-radio_aparicion, radio_aparicion)
		var offset_z: float = randf_range(-radio_aparicion, radio_aparicion)
		var pos_offset: Vector3 = Vector3(offset_x, 0.0, offset_z)
		
		contenedor_enemigos.add_child(enemigo_instancia)
		enemigo_instancia.global_position = global_position + pos_offset
