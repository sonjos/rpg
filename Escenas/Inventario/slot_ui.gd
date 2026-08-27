# res://Escenas/Inventario/slot_ui.gd
extends Button

func actualizar_slot(item: ItemData, cantidad: int) -> void:
	var icono_node = get_node_or_null("Icono") as TextureRect
	var lbl_node = get_node_or_null("LblCantidad") as Label
	
	if item != null and item.icono != null:
		if icono_node:
			icono_node.texture = item.icono
			icono_node.visible = true
		if lbl_node:
			if cantidad > 1:
				lbl_node.text = str(cantidad)
				lbl_node.visible = true
			else:
				lbl_node.text = ""
				lbl_node.visible = false
				
		# --- GENERACIÓN DEL TOOLTIP CON DESCRIPCIÓN Y STATS ---
		var texto_tooltip = item.nombre
		
		# Si el item tiene una descripción escrita en el recurso, la añadimos
		if "descripcion" in item and item.descripcion != "":
			texto_tooltip += "\n" + item.descripcion
			
		texto_tooltip += "\n-------------------"
		
		# Añadimos los stats que modifica (siempre que sean mayores a 0 o distintos de 0)
		if "bonus_fuerza_poder" in item and item.bonus_fuerza_poder != 0:
			texto_tooltip += "\n+ Fuerza: " + str(item.bonus_fuerza_poder)
		if "bonus_defensa" in item and item.bonus_defensa != 0:
			texto_tooltip += "\n+ Defensa: " + str(item.bonus_defensa)
		if "bonus_saqueo" in item and item.bonus_saqueo != 0:
			texto_tooltip += "\n+ Saqueo: " + str(item.bonus_saqueo)
		if "bonus_agilidad_velocidad" in item and item.bonus_agilidad_velocidad != 0:
			texto_tooltip += "\n+ Agilidad: " + str(item.bonus_agilidad_velocidad)
		if "cantidad_curacion" in item and item.cantidad_curacion > 0:
			texto_tooltip += "\n+ Curación: " + str(item.cantidad_curacion)
			
		tooltip_text = texto_tooltip
		# ----------------------------------------------------
	else:
		if icono_node:
			icono_node.texture = null
			icono_node.visible = false
		if lbl_node:
			lbl_node.text = ""
			lbl_node.visible = false
			
		# Si está vacío, limpiamos el tooltip
		tooltip_text = ""
