extends StaticBody3D

@export var esta_bloqueada: bool = false
var esta_abierta: bool = false

func _ready() -> void:
	if has_node("AreaInteraccion"):
		var area = $AreaInteraccion
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)

# Añadido el parámetro (player) para evitar errores de argumentos con el RayCast
func interactuar(_player) -> void:
	if esta_bloqueada:
		_mostrar_mensaje("Puerta", "La puerta está sellada. Necesitas activar el mecanismo.")
		return
		
	if not esta_abierta:
		abrir_puerta()

func abrir_puerta() -> void:
	esta_abierta = true
	_mostrar_mensaje("Puerta", "La pesada puerta de piedra se abre...")
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 4.0, 1.5)

func _mostrar_mensaje(remitente: String, texto: String) -> void:
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogo")
	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo"):
		caja_dialogo.mostrar_dialogo(remitente, texto)
	else:
		get_tree().call_group("HUD", "mostrar_dialogo", remitente, texto)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogo")
		if caja_dialogo and caja_dialogo.has_method("ocultar_dialogo"):
			caja_dialogo.ocultar_dialogo()
		else:
			get_tree().call_group("HUD", "ocultar_dialogo")
