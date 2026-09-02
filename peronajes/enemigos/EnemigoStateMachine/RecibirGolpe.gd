# res://states/RecibirGolpe.gd
extends Enemigo_state_machine

var stun_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	stun_timer = state_machine.stun_duration
	if character:
		character.velocity = Vector3.ZERO
	state_machine.play_anim("RecieveHit")

func physics_update(delta: float) -> void:
	stun_timer -= delta
	if stun_timer <= 0:
		state_machine.transition_to("Perseguir")
