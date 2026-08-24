# res://scripts/entorno/PuertaConLlave.gd
extends StaticBody3D

@export var llave_requerida: ItemData 
@export var consumir_al_usar: bool = true

var esta_abierta: bool = false

func _ready() -> void:
	# Conectamos automáticamente el AreaInteraccion para cerrar el diálogo al alejarte
	if has_node("AreaInteraccion"):
		var area = $AreaInteraccion
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)

# Este método es el que llama automáticamente el RayCast del jugador
func interactuar() -> void:
	if esta_abierta:
		return

	if not llave_requerida:
		return

	var indice_llave: int = -1

	# Recorremos el inventario desde InventarioManager
	for i in range(InventarioManager.inventario.size()):
		var slot = InventarioManager.inventario[i]
		if not slot or not slot.has("item") or not slot["item"]:
			continue
			
		var item = slot["item"]
		if (item.resource_path != "" and item.resource_path == llave_requerida.resource_path) \
		or (item.nombre != "" and item.nombre == llave_requerida.nombre) \
		or item == llave_requerida:
			indice_llave = i
			break

	if indice_llave != -1:
		if consumir_al_usar:
			InventarioManager.inventario.remove_at(indice_llave)
			InventarioManager.inventario_actualizado.emit()
			
		abrir_puerta()
	else:
		var nombre_mostrar = llave_requerida.nombre if llave_requerida.nombre != "" else "la llave requerida"
		_mostrar_mensaje("Puerta", "Necesitas tener " + nombre_mostrar + " en tu inventario.")

func abrir_puerta() -> void:
	esta_abierta = true
	var nombre_mostrar = llave_requerida.nombre if llave_requerida.nombre != "" else "la llave"
	_mostrar_mensaje("Puerta", "¡Has usado " + nombre_mostrar + " y la puerta se abrió!")
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 4.0, 1.5)

func _mostrar_mensaje(remitente: String, texto: String) -> void:
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogo")
	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo"):
		caja_dialogo.mostrar_dialogo(remitente, texto)
	else:
		get_tree().call_group("HUD", "mostrar_dialogo", remitente, texto)

# Ocultar el diálogo automáticamente al alejarte de la puerta
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogo")
		if caja_dialogo and caja_dialogo.has_method("ocultar_dialogo"):
			caja_dialogo.ocultar_dialogo()
		else:
			get_tree().call_group("HUD", "ocultar_dialogo")
