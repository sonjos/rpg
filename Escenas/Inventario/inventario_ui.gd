extends Control

@onready var grid_mochila: GridContainer = $AreaInventario/ColumnaIzquierda/GridMochila
@onready var grid_equipo: GridContainer = $AreaInventario/ColumnaDerecha/GridEquipo

@onready var lbl_vida: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblVida
@onready var lbl_fuerza: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblFuerza
@onready var lbl_defensa: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblDefensa
@onready var lbl_saqueo: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblSaqueo
@onready var lbl_agilidad: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblAgilidad

const COLUMNAS_MOCHILA: int = 3
const FILAS_MOCHILA: int = 6
const TOTAL_CASILLAS: int = COLUMNAS_MOCHILA * FILAS_MOCHILA

const ESCENA_SLOT = preload("res://Escenas/Inventario/slot_ui.tscn")

func _ready() -> void:
	if grid_mochila and grid_mochila is GridContainer:
		grid_mochila.columns = COLUMNAS_MOCHILA
	
	if not PlayerStats.stats_changed.is_connected(actualizar_interfaz):
		PlayerStats.stats_changed.connect(actualizar_interfaz)
	if not InventarioManager.inventario_actualizado.is_connected(actualizar_interfaz):
		InventarioManager.inventario_actualizado.connect(actualizar_interfaz)
		
	actualizar_interfaz()

func actualizar_interfaz() -> void:
	actualizar_stats_visuales()
	actualizar_mochila()
	actualizar_equipo()

func actualizar_stats_visuales() -> void:
	if lbl_vida: 
		lbl_vida.text = "Vida: " + str(int(PlayerStats.current_health)) + "/" + str(int(PlayerStats.max_health))
	if lbl_fuerza: 
		lbl_fuerza.text = "Fuerza: " + str(PlayerStats.obtener_fuerza_total())
	if lbl_defensa: 
		lbl_defensa.text = "Defensa: " + str(PlayerStats.obtener_defensa_total())
	if lbl_saqueo: 
		lbl_saqueo.text = "Saqueo: " + str(PlayerStats.obtener_saqueo_total())
	if lbl_agilidad:
		lbl_agilidad.text = "Agilidad: " + str(PlayerStats.obtener_agilidad_total())

func actualizar_mochila() -> void:
	if not grid_mochila:
		print("ERROR CRÍTICO: grid_mochila es null en la UI del inventario.")
		return
		
	for hijo in grid_mochila.get_children():
		hijo.queue_free()
		
	print("--- ACTUALIZANDO MOCHILA. Total items en manager: ", InventarioManager.inventario.size())
		
	for i in range(TOTAL_CASILLAS):
		var slot_ui = ESCENA_SLOT.instantiate()
		
		if i < InventarioManager.inventario.size():
			var slot_data = InventarioManager.inventario[i]
			print("Pintando slot ", i, " con item: ", slot_data["item"].nombre, " cantidad: ", slot_data["cantidad"])
			slot_ui.actualizar_slot(slot_data["item"], slot_data["cantidad"])
			slot_ui.pressed.connect(func(): usar_o_equipar_item(i))
		else:
			slot_ui.actualizar_slot(null, 0)
			
		grid_mochila.add_child(slot_ui)

func actualizar_equipo() -> void:
	if not grid_equipo:
		return
		
	for hijo in grid_equipo.get_children():
		hijo.queue_free()
		
	var tipos_slots = ["casco", "pechera", "arma", "anillo"]
	
	for tipo in tipos_slots:
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(50, 50)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
		style.border_color = Color(0.3, 0.4, 0.5, 1)
		slot_btn.add_theme_stylebox_override("normal", style)
		
		if PlayerStats.equipo.has(tipo) and PlayerStats.equipo[tipo] != null:
			var item_equipado = PlayerStats.equipo[tipo]
			var icono_rect = TextureRect.new()
			icono_rect.texture = item_equipado.icono
			icono_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icono_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icono_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			
			var descripcion_tooltip = item_equipado.nombre + " (" + tipo.capitalize() + " Equipado)\n"
			if item_equipado.bonus_fuerza_poder > 0: descripcion_tooltip += "+ Fuerza: " + str(item_equipado.bonus_fuerza_poder) + "\n"
			if item_equipado.bonus_defensa > 0: descripcion_tooltip += "+ Defensa: " + str(item_equipado.bonus_defensa) + "\n"
			if item_equipado.bonus_saqueo > 0: descripcion_tooltip += "+ Saqueo: " + str(item_equipado.bonus_saqueo) + "\n"
			if item_equipado.bonus_agilidad_velocidad != 0: descripcion_tooltip += "+ Agilidad: " + str(item_equipado.bonus_agilidad_velocidad) + "\n"
			
			icono_rect.tooltip_text = descripcion_tooltip
			slot_btn.add_child(icono_rect)
			
			slot_btn.pressed.connect(func(): desequipar_item(tipo))
			
		grid_equipo.add_child(slot_btn)

func usar_o_equipar_item(indice: int) -> void:
	if indice >= InventarioManager.inventario.size():
		return
		
	var slot_data = InventarioManager.inventario[indice]
	var item = slot_data["item"]
	var slot_destino: String = ""
	
	match item.tipo:
		0: slot_destino = "arma"
		1: slot_destino = "pechera"
		4, 5: slot_destino = "anillo"
		2: # Consumible
			if item.cantidad_curacion > 0:
				PlayerStats.current_health = min(PlayerStats.max_health, PlayerStats.current_health + item.cantidad_curacion)
				slot_data["cantidad"] -= 1
				if slot_data["cantidad"] <= 0:
					InventarioManager.inventario.remove_at(indice)
				InventarioManager.inventario_actualizado.emit()
				PlayerStats.stats_changed.emit()
				return
		_:
			# Si es un objeto de misión, material u otro tipo no equipable/consumible, 
			# simplemente evitamos que crashee o ignore el clic.
			return

	if slot_destino != "":
		if PlayerStats.equipo[slot_destino] != null:
			InventarioManager.recoger_item(PlayerStats.equipo[slot_destino])
			
		PlayerStats.equipo[slot_destino] = item
		slot_data["cantidad"] -= 1
		if slot_data["cantidad"] <= 0:
			InventarioManager.inventario.remove_at(indice)
			
		InventarioManager.inventario_actualizado.emit()
		PlayerStats.stats_changed.emit()

func desequipar_item(tipo: String) -> void:
	var item_equipado = PlayerStats.equipo[tipo]
	if item_equipado != null:
		InventarioManager.recoger_item(item_equipado)
		PlayerStats.equipo[tipo] = null
		InventarioManager.inventario_actualizado.emit()
		PlayerStats.stats_changed.emit()
