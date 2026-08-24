# res://autoload/QuestManager.gd
extends Node

signal mision_actualizada

var mision_activa: String = ""
var descripcion_mision: String = ""
var cantidad_requerida: int = 0
var item_objetivo_nombre: String = ""
var mision_cantidad_actual: int = 0
var mision_aceptada: bool = false
var mision_completada: bool = false

func _ready() -> void:
	if InventarioManager.has_signal("inventario_actualizado"):
		InventarioManager.inventario_actualizado.connect(actualizar_progreso)
		
func aceptar_mision(nombre: String, desc: String, cantidad: int, nombre_item: String) -> void:
	mision_activa = nombre
	descripcion_mision = desc
	cantidad_requerida = cantidad
	item_objetivo_nombre = nombre_item
	mision_aceptada = true
	mision_completada = false
	actualizar_progreso() # Calcula al momento por si ya tenemos items en la mochila

func actualizar_progreso() -> void:
	if not mision_aceptada or mision_completada:
		return
		
	var conteo: int = 0
	for slot in InventarioManager.inventario:
		if slot and slot.has("item") and slot["item"] != null:
			if slot["item"].nombre == item_objetivo_nombre:
				conteo += slot["cantidad"]
				
	mision_cantidad_actual = conteo
	mision_actualizada.emit()

func completar_mision() -> void:
	mision_completada = true
	mision_actualizada.emit()
