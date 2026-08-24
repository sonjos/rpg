# res://scripts/entorno/PuzleAntorchcha.gd
extends Node3D

signal puzle_resuelto

@export var puerta_objetivo: StaticBody3D
@export var antorchas: Array[NodePath] = []
@export var secuencia_correcta: Array[int] = [1, 3, 2]

var secuencia_actual: Array[int] = []

func registrar_activacion(id_antorcha: int) -> void:
	secuencia_actual.append(id_antorcha)
	
	# Verificar si el orden hasta ahora es correcto
	for i in range(secuencia_actual.size()):
		if secuencia_actual[i] != secuencia_correcta[i]:
			_mostrar_mensaje("Mecanismo", "Secuencia incorrecta. El mecanismo se ha reiniciado.")
			reiniciar_puzle()
			return
			
	# Si se completó toda la secuencia con éxito
	if secuencia_actual.size() == secuencia_correcta.size():
		puzle_resuelto.emit()
		desbloquear_paso()

func reiniciar_puzle() -> void:
	secuencia_actual.clear()
	
	# Espera un instante para que el jugador note la luz antes de apagarla
	await get_tree().create_timer(0.6).timeout
	
	for path in antorchas:
		var antorcha = get_node_or_null(path)
		if antorcha and antorcha.has_method("apagar"):
			antorcha.apagar()

func desbloquear_paso() -> void:
	_mostrar_mensaje("Mecanismo", "¡Secuencia correcta! La puerta se ha desbloqueado.")
	if puerta_objetivo:
		if "esta_bloqueada" in puerta_objetivo:
			puerta_objetivo.esta_bloqueada = false
		if puerta_objetivo.has_method("abrir_puerta"):
			puerta_objetivo.abrir_puerta() # Abre la puerta automáticamente

func _mostrar_mensaje(remitente: String, texto: String) -> void:
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogo")
	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo"):
		caja_dialogo.mostrar_dialogo(remitente, texto)
	else:
		get_tree().call_group("HUD", "mostrar_dialogo", remitente, texto)
