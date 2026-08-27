# res://autoload/InventarioManager.gd
extends Node

signal inventario_actualizado()

const TOTAL_CASILLAS: int = 18 # 3 columnas x 6 filas

# Cada ranura es un diccionario: {"item": ItemData, "cantidad": int}
var inventario: Array[Dictionary] = []

# Variable para almacenar las casillas extra otorgadas por las mochilas
var casillas_extra: int = 0

func recoger_item(item: ItemData, cantidad_a_recoger: int = 1) -> bool:
	if not item:
		return false
		
	# 1. Si es acumulable, buscamos si ya existe una pila incompleta
	if item.es_acumulable:
		for slot in inventario:
			if slot["item"] == item and slot["cantidad"] < item.cantidad_maxima:
				slot["cantidad"] += cantidad_a_recoger
				inventario_actualizado.emit()
				return true
				
	# 2. Si no es acumulable o no hay pilas, buscamos casilla libre (respetando las casillas extra de la mochila)
	var capacidad_maxima_total = TOTAL_CASILLAS + casillas_extra
	if inventario.size() < capacidad_maxima_total:
		inventario.append({
			"item": item,
			"cantidad": cantidad_a_recoger
		})
		inventario_actualizado.emit()
		return true
		
	return false

func contar_item(item_buscado: ItemData) -> int:
	if not item_buscado:
		return 0
	var total: int = 0
	for slot in inventario:
		if slot.has("item") and slot["item"] == item_buscado:
			total += slot["cantidad"]
	return total

func contar_item_por_nombre(nombre_item: String) -> int:
	var total: int = 0
	for slot in inventario:
		if slot.has("item") and slot["item"] and slot["item"].nombre == nombre_item:
			total += slot["cantidad"]
	return total

func remover_items_por_nombre(nombre_item: String, cantidad_a_remover: int) -> bool:
	var restando = cantidad_a_remover
	for i in range(inventario.size() - 1, -1, -1):
		var slot = inventario[i]
		if slot.has("item") and slot["item"] and slot["item"].nombre == nombre_item:
			if slot["cantidad"] >= restando:
				slot["cantidad"] -= restando
				restando = 0
				if slot["cantidad"] <= 0:
					inventario.remove_at(i)
				break
			else:
				restando -= slot["cantidad"]
				inventario.remove_at(i)
				
	inventario_actualizado.emit()
	return restando <= 0
