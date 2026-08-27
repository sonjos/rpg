# res://Escenas/Inventario/inventario_ui.gd
extends Control

@onready var grid_mochila: GridContainer = $AreaInventario/ColumnaIzquierda/GridMochila
@onready var grid_equipo: HBoxContainer = $AreaInventario/ColumnaDerecha/BoxEquipo

@onready var lbl_vida: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblVida
@onready var lbl_fuerza: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblFuerza
@onready var lbl_defensa: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblDefensa
@onready var lbl_saqueo: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblSaqueo
@onready var lbl_agilidad: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblAgilidad
@onready var inventario_ui: Control = $"."

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
		
	if inventario_ui:
		inventario_ui.visible = false
		
	actualizar_interfaz()

# USAMOS _input PARA GESTIONAR EL TAB DIRECTAMENTE AQUÍ
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			# Alternamos visibilidad
			visible = not visible
			
			if visible:
				# 1. Liberamos cualquier foco previo para que no navegue por las casillas
				get_viewport().gui_release_focus()
				
				# 2. Liberamos el cursor del ratón (exactamente como lo pediste)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				
				# 3. Congelamos al jugador
				var player = get_tree().get_first_node_in_group("Player")
				if player and player.has_method("set_congelado"):
					player.set_congelado(true)
					
				actualizar_interfaz()
			else:
				# 1. Capturamos de nuevo el ratón para el juego (como lo pediste)
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				
				# 2. Descongelamos al jugador
				var player = get_tree().get_first_node_in_group("Player")
				if player and player.has_method("set_congelado"):
					player.set_congelado(false)
			
			# ¡Importante! Consumimos el evento para que Godot no mueva el foco por las casillas al cerrar
			get_viewport().set_input_as_handled()

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
		return
		
	get_viewport().gui_release_focus()
		
	for hijo in grid_mochila.get_children():
		hijo.queue_free()
		
	var capacidad_total_actual = TOTAL_CASILLAS + InventarioManager.casillas_extra
		
	for i in range(capacidad_total_actual):
		var slot_ui = ESCENA_SLOT.instantiate()
		slot_ui.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if i < InventarioManager.inventario.size():
			var slot_data = InventarioManager.inventario[i]
			slot_ui.actualizar_slot(slot_data["item"], slot_data["cantidad"])
			
			var index_capturado = i
			slot_ui.pressed.connect(func(): usar_o_equipar_item(index_capturado))
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
		slot_btn.custom_minimum_size = Vector2(48, 48)
		slot_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
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
			icono_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var descripcion_tooltip = item_equipado.nombre + " (" + tipo.capitalize() + " Equipado)\n"
			if item_equipado.bonus_fuerza_poder > 0: descripcion_tooltip += "+ Fuerza: " + str(item_equipado.bonus_fuerza_poder) + "\n"
			if item_equipado.bonus_defensa > 0: descripcion_tooltip += "+ Defensa: " + str(item_equipado.bonus_defensa) + "\n"
			if item_equipado.bonus_saqueo > 0: descripcion_tooltip += "+ Saqueo: " + str(item_equipado.bonus_saqueo) + "\n"
			if item_equipado.bonus_agilidad_velocidad != 0: descripcion_tooltip += "+ Agilidad: " + str(item_equipado.bonus_agilidad_velocidad) + "\n"
			
			icono_rect.tooltip_text = descripcion_tooltip
			slot_btn.add_child(icono_rect)
			
			var tipo_capturado = tipo
			slot_btn.pressed.connect(func(): desequipar_item(tipo_capturado))
			
		grid_equipo.add_child(slot_btn)

func usar_o_equipar_item(indice: int) -> void:
	if indice >= InventarioManager.inventario.size():
		return
		
	var slot_data = InventarioManager.inventario[indice]
	var item = slot_data["item"]
	var slot_destino: String = ""
	
	var tipo_val = item.tipo
	
	if tipo_val == 0 or tipo_val == "arma" or tipo_val == "Arma":
		slot_destino = "arma"
	elif tipo_val == 1 or tipo_val == "armadura" or tipo_val == "pechera" or tipo_val == "Armadura":
		slot_destino = "pechera"
	elif tipo_val == 5 or tipo_val == "anillo" or tipo_val == "abalorio" or tipo_val == "Anillo":
		slot_destino = "anillo"
	elif tipo_val == 2 or tipo_val == "consumible":
		if item.cantidad_curacion > 0:
			PlayerStats.current_health = min(PlayerStats.max_health, PlayerStats.current_health + item.cantidad_curacion)
			slot_data["cantidad"] -= 1
			if slot_data["cantidad"] <= 0:
				InventarioManager.inventario.remove_at(indice)
			get_viewport().gui_release_focus()
			InventarioManager.inventario_actualizado.emit()
			PlayerStats.stats_changed.emit()
			return
	elif tipo_val == 4 or tipo_val == "mochila":
		InventarioManager.casillas_extra += 6
		slot_data["cantidad"] -= 1
		if slot_data["cantidad"] <= 0:
			InventarioManager.inventario.remove_at(indice)
		get_viewport().gui_release_focus()
		InventarioManager.inventario_actualizado.emit()
		PlayerStats.stats_changed.emit()
		return

	if slot_destino != "":
		if PlayerStats.equipo[slot_destino] != null:
			InventarioManager.recoger_item(PlayerStats.equipo[slot_destino])
			
		PlayerStats.equipo[slot_destino] = item
		slot_data["cantidad"] -= 1
		if slot_data["cantidad"] <= 0:
			InventarioManager.inventario.remove_at(indice)
			
		get_viewport().gui_release_focus()
			
		InventarioManager.inventario_actualizado.emit()
		PlayerStats.stats_changed.emit()

func desequipar_item(tipo: String) -> void:
	var item_equipado = PlayerStats.equipo[tipo]
	if item_equipado != null:
		get_viewport().gui_release_focus()
		InventarioManager.recoger_item(item_equipado)
		PlayerStats.equipo[tipo] = null
		InventarioManager.inventario_actualizado.emit()
		PlayerStats.stats_changed.emit()
