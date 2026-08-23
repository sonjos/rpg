# res://states/Bloqueo.gd
extends State

@export var stamina_drain_rate : float = 15.0

func enter() -> void:
	character.velocity.x = 0.0
	character.velocity.z = 0.0
	character.play_anim("block")
	PlayerStats.is_Bloqueo = true


func exit() -> void:
	PlayerStats.is_Bloqueo = false

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	
	character.move_and_slide()
	
	# Soltar el botón de bloqueo para volver a Quieto o Andar
	if not Input.is_action_pressed("Bloqueo"):
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir != Vector2.ZERO:
			state_machine.transition_to("Andando")
		else:
			state_machine.transition_to("Quieto")
		return
	
	PlayerStats.current_stamina -= stamina_drain_rate * delta
	PlayerStats.current_stamina = max(0.0, PlayerStats.current_stamina)
	PlayerStats.emit_signal("stats_changed")
	
	if PlayerStats.current_stamina <= 0:
		state_machine.transition_to("Quieto")

func handle_input(_event: InputEvent) -> void:
	pass
