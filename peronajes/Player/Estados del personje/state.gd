class_name State extends Node

#Referencia que se llenan automaticamente desde satate_machine.gd al inicia
var state_machine : Node
var character : CharacterBody3D

#Configuracion del estado si es true, la maquina de intentra 
#Regenerar stamina cuando este estado este activo
@export var consumes_stamina : bool = false
 
#LLamando cuando la maquina de estados sale de este estado
#util para limpiar, desactivar hitboxes, o resetear variables 
func exit() -> void:
	pass
	
#Llamado desde _physics process de la state_machine.
#Aqui va la logica principal del personuaje (mocimiento, gravedad,
#consumo de stamina continuo etc.) frame a frame
func _physics_process(_delta: float) -> void:
	pass
	
#Llamado desde _unhantled_input de la state_machine
#se usa para detectar pulsaciones de botones que provoquen 
#cambios de estado inmediatos (como saltar, atacar, esquivar).
func _unhandled_input(_event: InputEvent) -> void:
	pass
	
#---Funciones de ayuda comunes---

# Calcula la direccion del movimiento basada en los input maps definidos en el proyecto.
# Devuelve un Vector3 normalizado listo para usar con move_and_slide()
func get_input_direction() -> Vector3:
	# Importante: Debes tener definidos estos nombres en el input map de godot
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Obtenemos la base de rotación de la cámara para que el personaje
	# se mueva en relación a la vista del jugador, no al mundo.
	var camera_basis = character.get_viewport().get_camera_3d().global_transform.basis
	
	# Calculamos la dirección 3D multiplicando la matriz de la cámara por el vector de input
	var direction = camera_basis * Vector3(input_dir.x, 0, input_dir.y)
	
	# Aplanamos la dirección para que no intente volar o hundirse
	direction.y = 0
	
	# Devolvemos la dirección normalizada
	return direction.normalized()
