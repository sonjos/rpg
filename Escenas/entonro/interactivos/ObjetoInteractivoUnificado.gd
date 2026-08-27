class_name ObjetoInteractivoUnificado
extends StaticBody3D

# Tipos de objetos soportados por el mismo script
enum TipoObjeto { PUERTA, COFRE, TRAMPILLA }
enum NivelLlave { COMUN = 1, NORMAL = 2, MAESTRA = 3 }

@export_category("Configuración General")
@export var tipo_objeto: TipoObjeto = TipoObjeto.PUERTA
@export var esta_bloqueada: bool = false
@export var nivel_requerido: NivelLlave = NivelLlave.COMUN
@export var consume_llave: bool = false

@export_category("Recompensa (Solo para Cofres)")
@export var item_recompensa: Resource

# Estado interno
var esta_activado: bool = false 

# Referencia opcional al AnimationPlayer
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false)

func interactuar(player) -> void:
	if esta_activado and tipo_objeto == TipoObjeto.COFRE:
		_mostrar_mensaje("Cofre", "El cofre ya está abierto y vacío.")
		return

	if esta_bloqueada:
		var llave_valida = player.obtener_llave_en_inventario(nivel_requerido)
		if llave_valida == null:
			_mostrar_mensaje("Sistema", "Está cerrado con llave. Necesitas un nivel superior.")
			return
		
		esta_bloqueada = false
		if consume_llave:
			InventarioManager.remover_items_por_nombre(llave_valida.nombre, 1)

	match tipo_objeto:
		TipoObjeto.PUERTA:
			_accion_puerta()
		TipoObjeto.COFRE:
			_accion_cofre()
		TipoObjeto.TRAMPILLA:
			_accion_trampilla()

func _accion_puerta() -> void:
	esta_activado = !esta_activado
	if esta_activado:
		_mostrar_mensaje("Puerta", "La puerta se abre.")
		var tween = create_tween()
		tween.tween_property(self, "position:y", position.y + 4.0, 1.5)
	else:
		_mostrar_mensaje("Puerta", "La puerta se cierra.")
		var tween = create_tween()
		tween.tween_property(self, "position:y", position.y - 4.0, 1.5)

func _accion_cofre() -> void:
	esta_activado = true
	
	if item_recompensa:
		InventarioManager.recoger_item(item_recompensa)
		var nombre_item = "Objeto misterioso"
		if "nombre" in item_recompensa:
			nombre_item = item_recompensa.nombre
		elif "resource_name" in item_recompensa and item_recompensa.resource_name != "":
			nombre_item = item_recompensa.resource_name
			
		_mostrar_mensaje("Cofre", "¡Has abierto el cofre y obtenido: " + nombre_item + "!")
	else:
		_mostrar_mensaje("Cofre", "¡Has abierto el cofre, pero estaba vacío!")

	if animation_player:
		if animation_player.has_animation("Chest_Open"):
			animation_player.play("Chest_Open")
		elif animation_player.has_animation("Chest_Opened"):
			animation_player.play("Chest_Opened")

func _accion_trampilla() -> void:
	esta_activado = !esta_activado
	_mostrar_mensaje("Mecanismo", "Accionando trampilla...")

func _mostrar_mensaje(remitente: String, texto: String) -> void:
	var caja_dialogo = get_tree().get_first_node_in_group("CajaDialogo")
	if caja_dialogo and caja_dialogo.has_method("mostrar_dialogo"):
		caja_dialogo.mostrar_dialogo(remitente, texto)
	else:
		print(remitente + ": " + texto)
