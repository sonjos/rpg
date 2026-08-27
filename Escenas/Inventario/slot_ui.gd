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
	else:
		if icono_node:
			icono_node.texture = null
			icono_node.visible = false
		if lbl_node:
			lbl_node.text = ""
			lbl_node.visible = false
