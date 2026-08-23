# res://scripts/entorno/PuertaConLlave.gd
extends StaticBody3D

@export var llave_requerida: ItemData 
@export var consumir_al_usar: bool = true

var esta_abierta: bool = false
var jugador_cerca: bool = false

func _ready() -> void:
	# Conectamos automáticamente el AreaInteraccion si existe
	if has_node("AreaInteraccion"):
		var area = $AreaInteraccion
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	

func _unhandled_input(event: InputEvent) -> void:
	# Detecta presionar la tecla cuando estás cerca
	if jugador_cerca and event.is_action_pressed("Interactuar") and not esta_abierta:
		Interactuar()

func _on_body_entered(body: Node3D) -> void:
	
	if body.is_in_group("Player") or body.name == "Player":
		jugador_cerca = true
		if not esta_abierta:
			get_tree().call_group("HUD", "mostrar_dialogo", "Puerta", "Presiona 'z' para usar la llave.")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		jugador_cerca = false
		get_tree().call_group("HUD", "ocultar_dialogo")

func Interactuar() -> void:
	if esta_abierta:
		return

	if not llave_requerida:
		
		return

	var indice_llave: int = -1

	# Recorremos el inventario de PlayerStats
	for i in range(PlayerStats.inventario.size()):
		var item = PlayerStats.inventario[i]
		if not item:
			continue
			

		
		if (item.resource_path != "" and item.resource_path == llave_requerida.resource_path) \
		or (item.nombre != "" and item.nombre == llave_requerida.nombre) \
		or item == llave_requerida:
			indice_llave = i
			break

	if indice_llave != -1:
		if consumir_al_usar:
			PlayerStats.inventario.remove_at(indice_llave)
			PlayerStats.stats_changed.emit()
			
		abrir_puerta()
	else:
		var nombre_mostrar = llave_requerida.nombre if llave_requerida.nombre != "" else "la llave requerida"
		get_tree().call_group("HUD", "mostrar_dialogo", "Puerta", "Necesitas tener " + nombre_mostrar + " en tu inventario.")

func abrir_puerta() -> void:
	esta_abierta = true
	var nombre_mostrar = llave_requerida.nombre if llave_requerida.nombre != "" else "la llave"
	get_tree().call_group("HUD", "mostrar_dialogo", "Puerta", "¡Has usado " + nombre_mostrar + " y la puerta se abrió!")
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 4.0, 1.5)
