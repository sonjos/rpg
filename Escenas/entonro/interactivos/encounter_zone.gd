extends Area3D
class_name EncounterZone

@export var escena_enemigo: Array[PackedScene] = []	
@export var cantidad_enemigos: int = 3
@export var radio_minimo_exterior: float = 3.0 # Distancia mínima desde el centro (fuera del área)
@export var radio_maximo_exterior: float = 6.0 # Distancia máxima de dispersión exterior

@export_group("Configuración de Recompensas y Vida por Spawn")
@export var vida_personalizada: int = 60
@export var exp_personalizada: int = 20
@export var oro_personalizado: int = 10

@onready var contenedor_enemigos: Node3D = $ContenedorEnemigos if has_node("ContenedorEnemigos") else self

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Capa 2 (Player)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" or body.is_in_group("Player") or body is CharacterBody3D:
		_generar_enemigos()

func _generar_enemigos() -> void:
	var escenas_validas = escena_enemigo.filter(func(escena): return escena != null)
	
	if escenas_validas.is_empty():
		push_warning("EncounterZone: No hay escenas de enemigos válidas asignadas.")
		return

	for i in range(cantidad_enemigos):
		var escena_seleccionada: PackedScene = escenas_validas.pick_random()
		var enemigo_instancia := escena_seleccionada.instantiate() as Node3D
		
		# Inyección de estadísticas
		enemigo_instancia.set("max_health", vida_personalizada)
		enemigo_instancia.set("current_health", vida_personalizada)
		enemigo_instancia.set("experiencia", exp_personalizada)
		enemigo_instancia.set("oro", oro_personalizado)
		
		var state_machine = enemigo_instancia.get_node_or_null("enemigo_state_machine")
		if state_machine:
			state_machine.set("health", vida_personalizada)
			state_machine.set("max_health", vida_personalizada)
			state_machine.set("exp_reward", exp_personalizada)
			state_machine.set("gold_reward", oro_personalizado)
		
		# --- CÁLCULO DE APARICIÓN FUERA DEL ÁREA ---
		# Generamos un ángulo aleatorio en radianes (0 a 2 PI)
		var angulo: float = randf_range(0.0, TAU)
		# Seleccionamos una distancia aleatoria que esté estrictamente entre el radio mínimo y máximo exterior
		var distancia: float = randf_range(radio_minimo_exterior, radio_maximo_exterior)
		
		# Convertimos coordenadas polares/esféricas a un Vector3 en el plano XZ
		var offset_x: float = cos(angulo) * distancia
		var offset_z: float = sin(angulo) * distancia
		var pos_offset: Vector3 = Vector3(offset_x, 0.0, offset_z)
		# -------------------------------------------
		
		contenedor_enemigos.add_child(enemigo_instancia)
		enemigo_instancia.global_position = global_position + pos_offset