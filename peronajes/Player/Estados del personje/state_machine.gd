# res://states/state_machine.gd
extends Node

@export var initial_state : State

var current_state : State
var character : CharacterBody3D

func _ready() -> void:
	# Obtenemos el personaje padre (el Player)
	character = owner as CharacterBody3D
	if not character:
		
		return

	# Inicializamos todos los estados hijos
	for child in get_children():
		if child is State:
			child.state_machine = self
			child.character = character

	# Activamos el estado inicial por defecto si está asignado
	if initial_state:
		initial_state.enter()
		current_state = initial_state
		
	else:
		# Si no asignaste uno en el inspector, cogemos el primero que haya
		var first_state = get_child(0) as State
		if first_state:
			first_state.enter()
			current_state = first_state
		

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func transition_to(target_state_name: String) -> void:
	var target_state = get_node_or_null(target_state_name)
	if not target_state:
	
		return

	if current_state:
		current_state.exit()

	current_state = target_state
	current_state.enter()
	



		
