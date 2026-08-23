extends Panel

@onready var texture_rect: TextureRect = $TextureRect
@onready var lbl_stats: Label = $LblStats # Asegúrate de que tu Label se llama así (o ajusta la ruta)

func actualizar_slot(item: ItemData) -> void:
	if item:
		if item.icono:
			texture_rect.texture = item.icono
		else:
			texture_rect.texture = null
			
		# Construimos el texto dinámico según los bonus que tenga el objeto
		var texto_bonus = ""
		
		# Verificamos cada bonus posible del ItemData
		# Verificamos cada bonus posible usando exactamente el nombre de tu ItemData
		if "bonus_fuerza_poder" in item and item.bonus_fuerza_poder != 0:
			texto_bonus += "F: +" + str(item.bonus_fuerza_poder) + "\n"
		if "bonus_defensa" in item and item.bonus_defensa != 0:
			texto_bonus += "D: +" + str(item.bonus_defensa) + "\n"
		if "bonus_agilidad_velocidad" in item and item.bonus_agilidad_velocidad != 0:
			texto_bonus += "Velocidad: +" + str(item.bonus_agilidad_velocidad) + "\n"
		if "bonus_saqueo" in item and item.bonus_saqueo != 0:
			texto_bonus += "Saqueo: +" + str(int(item.bonus_saqueo * 100)) + "%\n"
			
		# Asignamos el texto a la etiqueta del slot
		if lbl_stats:
			lbl_stats.text = texto_bonus
			
		visible = true
	else:
		texture_rect.texture = null
		if lbl_stats:
			lbl_stats.text = ""
		visible = false
