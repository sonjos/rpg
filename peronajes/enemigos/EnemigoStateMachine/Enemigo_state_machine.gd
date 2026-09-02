# res://states/Enemigo_state_machine.gd
extends Node
class_name Enemigo_state_machine

@export var initial_state: NodePath

# --- STATS DEL ENEMIGO ---
@export var vida_maxima: float = 50.0

# --- MOVIMIENTO ---
@export var move_speed: float = 2.0
@export var chase_speed: float = 3.5

# --- ATAQUE MELEE ---
@export var fuerza_ataque: float = 10.0
@export var attack_cooldown: float = 1.5

# --- ATAQUE EMBESTIDA ---
@export var attack_speed: float = 6.0

# --- RECIBIR GOLPE ---
@export var stun_duration: float = 0.4

# --- RECOMPENSAS AL MORIR ---
@export var experiencia_otorgada: float = 50.0
@export var monedas_otorgadas: int = 100
@export var tabla_botin: Array[Resource] = []  # Array de LootEntry.gd
@export var probabilidad_drop_general: float = 0.2  # Probabilidad base de drop

var current_state: Node
var states: Dictionary = {}
var state_machine = null
var character = null

func _ready() -> void:
	character = owner 
	
	for child in get_children():
		if child.name == "Vida":
			continue
			
		if child.get_script() != null:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.character = character

	if initial_state:
		current_state = get_node(initial_state)
		if current_state:
			current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	# --- GRAVEDAD CORREGIDA EN PHYSICS PROCESS ---
	if character and character is CharacterBody3D:
		if not character.is_on_floor():
			# Restamos el valor absoluto (9.8) para garantizar que baje en Y
			character.velocity.y -= 9.8 * delta
		elif character.velocity.y < 0:
			character.velocity.y = -0.1

	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	var target_lower = target_state_name.to_lower()
	if not states.has(target_lower):
		return
	
	var new_state = states[target_lower]
	if current_state == new_state:
		return
	
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter(msg)

func play_anim(anim_name: String, loop: bool = false) -> void:
	if character:
		var anim_player: AnimationPlayer = character.find_child("AnimationPlayer", true, false)
		if anim_player and anim_player.has_animation(anim_name):
			var anim_resource = anim_player.get_animation(anim_name)
			if anim_resource:
				anim_resource.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

			if anim_player.current_animation != anim_name:
				anim_player.play(anim_name)

func mirar_hacia(posicion_destino: Vector3) -> void:
	if not character:
		return
	
	var direccion = posicion_destino - character.global_position
	direccion.y = 0.0
	
	if direccion.length_squared() > 0.001:
		character.look_at(character.global_position - direccion, Vector3.UP)

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
