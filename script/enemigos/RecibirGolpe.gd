# res://states/RecibirGolpe.gd
extends Enemigo_state_machine

var stun_timer: float = 0.4

func enter(_msg: Dictionary = {}) -> void:
	stun_timer = 0.4
	if character:
		character.velocity = Vector3.ZERO
	state_machine.play_anim("RecieveHit")

func physics_update(delta: float) -> void:
	stun_timer -= delta
	if stun_timer <= 0:
		state_machine.transition_to("Perseguir")
