# res://scripts/entorno/PuntoDeControl.gd
extends Area3D

var activado: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		# 1. Restaurar salud y estamina completas en PlayerStats
		PlayerStats.ultimo_punto_control = global_position
		PlayerStats.current_health = PlayerStats.max_health
		PlayerStats.current_stamina = PlayerStats.max_stamina
		PlayerStats.is_dead = false
		PlayerStats.stats_changed.emit()
		
		# 2. Notificar al usuario a través del HUD
		get_tree().call_group("HUD", "mostrar_dialogo", "Punto de Control", "Salud y estamina restauradas en la hoguera.")
		
		# 3. Guardar el nuevo punto de respawn
		if not activado:
			activado = true
			if "punto_respawn" in body:
				body.punto_respawn = global_position
				get_tree().call_group("HUD", "mostrar_dialogo", "Checkpoint", "Punto de control activado.")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		get_tree().call_group("HUD", "ocultar_dialogo")
