# res://states/state_machine.gd
extends Node

@export var initial_state : State

# --- MOVIMIENTO ---
@export_group("Movimiento")
@export var walk_speed: float = 4.2
@export var run_speed: float = 6.8
@export var jump_velocity: float = 5.2
@export var roll_speed: float = 10.5
@export var gravity: float = 18.0

# --- ESTAMINA ---
@export_group("Estamina")
@export var stamina_drain_rate: float = 12.0
@export var roll_stamina_cost: float = 18.0

# --- COMBATE ---
@export_group("Combate")
@export var attack_damage_base: float = 12.0

# --- CONTROL / EFECTOS ---
@export_group("Control y Efectos")
@export var hit_recovery_time: float = 0.45

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
