# res://scripts/entorno/TrampaDaño.gd
extends Area3D

@export var daño: float = 1.0
@export var es_caida_al_vacio: bool = false # Si está activado, reaparece siempre. Si no, solo quita vida.

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited) # 1. Conectamos la señal de salida[cite: 27]

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		# Aplicamos el daño procesado por PlayerStats
		PlayerStats.take_damage(daño)
		
		# Mostramos aviso en pantalla con la salud actual de PlayerStats
		get_tree().call_group("HUD", "mostrar_dialogo", "Trampa", "¡Has recibido " + str(daño) + " de daño! Vida restante: " + str(PlayerStats.current_health))
		
		# Solo reaparece si es caída al vacío O si el jugador ha muerto
		if es_caida_al_vacio or PlayerStats.is_dead:
			if PlayerStats.is_dead:
				PlayerStats.revivir()
			if "reaparecer" in body:
				body.reaparecer()

# 2. Función que oculta el diálogo al salir del Area3D
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		get_tree().call_group("HUD", "ocultar_dialogo")
