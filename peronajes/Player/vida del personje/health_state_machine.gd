# res://states/health_state_machine.gd
extends Node

signal health_state_changed(current_state, previous_state)

@export var initial_state : NodePath
var current_state : Node
var previous_state : Node
@onready var player : CharacterBody3D = get_parent() as CharacterBody3D

func _ready() -> void:
	# Inicializamos los hijos: cada estado sabrá quién es su máquina
	for child in get_children():
		child.health_state_machine = self
			
	if initial_state:
		current_state = get_node(initial_state)
		if current_state and current_state.has_method("enter"):
			current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("physics_update"):
		current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	if not has_node(target_state_name):
		printerr("ERROR: El estado de salud ", target_state_name, " no existe.")
		return

	var new_state = get_node(target_state_name)
	if new_state == current_state:
		return

	if current_state and current_state.has_method("exit"):
		current_state.exit()
	
	previous_state = current_state
	current_state = new_state
	
	if current_state and current_state.has_method("enter"):
		current_state.enter()
		
	emit_signal("health_state_changed", current_state, previous_state)

# Esta función actúa como el "botón de pánico" del jugador
func take_damage_and_react(amount: float) -> void:
	# 1. Aplicamos el daño al Autoload global
	PlayerStats.take_damage(amount)
	
	# 2. Comprobamos si el jugador ha muerto
	if PlayerStats.current_health <= 0:
		transition_to("State_Dead")
	else:
		# 3. Si sigue vivo, reaccionamos al golpe
		transition_to("State_Hit")
