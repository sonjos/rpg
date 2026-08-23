# res://states/Muerte.gd
extends State

func enter() -> void:
	character.velocity = Vector3.ZERO
	character.play_anim("death")
	
	var ui = get_tree().root.find_child("JuegoUI", true, false)
	if ui and ui.has_node("BtnRevivir"):
		ui.get_node("BtnRevivir").show()
	
	if not PlayerStats.is_connected("revive_player", _on_revive):
		PlayerStats.connect("revive_player", _on_revive)

func _on_revive(nueva_posicion: Vector3) -> void:
	if character is Node3D:
		character.global_position = nueva_posicion
	elif owner is Node3D:
		owner.global_position = nueva_posicion
	
	var ui = get_tree().root.find_child("JuegoUI", true, false)
	if ui and ui.has_node("BtnRevivir"):
		ui.get_node("BtnRevivir").hide()
		
	if state_machine:
		state_machine.transition_to("Quieto")

func exit() -> void:
	if PlayerStats.is_connected("revive_player", _on_revive):
		PlayerStats.disconnect("revive_player", _on_revive)

func physics_update(_delta: float) -> void:
	character.move_and_slide()

func handle_input(_event: InputEvent) -> void:
	pass
