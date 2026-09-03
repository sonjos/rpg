# res://Escenas/Inventario/inventario_ui.gd
extends Control

@onready var grid_mochila: GridContainer = $AreaInventario/ColumnaIzquierda/GridMochila
@onready var grid_equipo: HBoxContainer = $AreaInventario/ColumnaDerecha/BoxEquipo
@onready var box_clave: HBoxContainer = $AreaInventario/ColumnaDerecha/HBoxClave
@onready var lbl_vida: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblVida
@onready var lbl_fuerza: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblFuerza
@onready var lbl_defensa: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblDefensa
@onready var lbl_saqueo: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblSaqueo
@onready var lbl_agilidad: Label = $AreaInventario/ColumnaDerecha/PanelStatsUI/LblAgilidad
@onready var inventario_ui: Control = $"."

# Precarga opcional de sonidos de interfaz (asegúrate de ajustar las rutas si usas tus propios archivos .wav o .ogg)
var sonido_menu: AudioStream = preload("res://Assets/rpg-audio/Audio/bookOpen.ogg") 
var sonido_clic: AudioStream = preload("res://Assets/rpg-audio/Audio/cloth3.ogg") 

# Capacidad base del inventario y límite máximo
const CASILLAS_BASE: int = 18
const CASILLAS_MAXIMAS: int = 24

const ESCENA_SLOT = preload("res://Escenas/Inventario/slot_ui.tscn")

func _ready() -> void:
	if not PlayerStats.stats_changed.is_connected(actualizar_interfaz):
		PlayerStats.stats_changed.connect(actualizar_interfaz)
	if not InventarioManager.inventario_actualizado.is_connected(actualizar_interfaz):
		InventarioManager.inventario_actualizado.connect(actualizar_interfaz)
		
	if inventario_ui:
		inventario_ui.visible = false
		
	actualizar_interfaz()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			visible = not visible
			
			# Reproducir sonido global de interfaz al abrir/cerrar menú
			if sonido_menu:
				AudioManager.reproducir_ui(sonido_menu)
			
			if visible:
				get_viewport().gui_release_focus()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				
				var player = get_tree().get_first_node_in_group("Player")
				if player and player.has_method("set_congelado"):
					player.set_congelado(true)
					
				actualizar_interfaz()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				
				var player = get_tree().get_first_node_in_group("Player")
				if player and player.has_method("set_congelado"):
					player.set_congelado(false)
			
			get_viewport().set_input_as_handled()

func actualizar_interfaz() -> void:
	actualizar_stats_visuales()
	actualizar_mochila()
	actualizar_equipo()
	actualizar_objetos_clave()

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
		
	var capacidad_total_actual = min(CASILLAS_BASE + InventarioManager.casillas_extra, CASILLAS_MAXIMAS)

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
		var slot_ui = ESCENA_SLOT.instantiate()
		slot_ui.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var item_equipado = PlayerStats.equipo.get(tipo, null)
		
		slot_ui.actualizar_slot(item_equipado, 1 if item_equipado else 0)
		
		if item_equipado != null:
			var tipo_capturado = tipo
			slot_ui.pressed.connect(func(): desequipar_item(tipo_capturado))
			
		grid_equipo.add_child(slot_ui)

func usar_o_equipar_item(indice: int) -> void:
	if indice >= InventarioManager.inventario.size():
		return
		
	# Reproducir sonido general de clic en objeto
	if sonido_clic:
		AudioManager.reproducir_ui(sonido_clic)
		
	var slot_data = InventarioManager.inventario[indice]
	var item = slot_data["item"]
	var slot_destino: String = ""
	
	var tipo_str = str(item.tipo).to_lower()
	
	# --- 1. USO DIRECTO (MOCHILA / CONSUMIBLES) ---
	if item.tipo == 4 or tipo_str in ["4", "mochila"]:
		var capacidad_actual = CASILLAS_BASE + InventarioManager.casillas_extra
		
		if capacidad_actual >= CASILLAS_MAXIMAS:
			print("El inventario ya alcanzó su límite máximo de 24 casillas.")
			return

		var espacio_a_sumar = item.capacidad_extra if "capacidad_extra" in item else 6
		var nueva_capacidad = min(capacidad_actual + espacio_a_sumar, CASILLAS_MAXIMAS)
		InventarioManager.casillas_extra = nueva_capacidad - CASILLAS_BASE
		
		_consumir_item_del_slot(slot_data, indice)
		return

	elif item.tipo == 2 or tipo_str in ["2", "consumible"]:
		if "cantidad_curacion" in item and item.cantidad_curacion > 0:
			PlayerStats.curar(item.cantidad_curacion)
			_consumir_item_del_slot(slot_data, indice)
		return

	# --- 2. EQUIPAMIENTO ---
	elif item.tipo == 0 or tipo_str in ["0", "arma"]:
		slot_destino = "arma"
	elif item.tipo == 1 or tipo_str in ["1", "armadura", "pechera"]:
		slot_destino = "pechera"
	elif item.tipo == 5 or tipo_str in ["5", "anillo", "abalorio"]:
		slot_destino = "anillo"

	if slot_destino != "":
		if PlayerStats.equipo[slot_destino] != null:
			InventarioManager.recoger_item(PlayerStats.equipo[slot_destino])
			
		PlayerStats.equipo[slot_destino] = item
		_consumir_item_del_slot(slot_data, indice)

func _consumir_item_del_slot(slot_data: Dictionary, indice: int) -> void:
	slot_data["cantidad"] -= 1
	if slot_data["cantidad"] <= 0:
		InventarioManager.inventario.remove_at(indice)
	get_viewport().gui_release_focus()
	InventarioManager.inventario_actualizado.emit()
	PlayerStats.stats_changed.emit()

func desequipar_item(tipo: String) -> void:
	var item_equipado = PlayerStats.equipo[tipo]
	if item_equipado != null:
		if sonido_clic:
			AudioManager.reproducir_ui(sonido_clic)
		get_viewport().gui_release_focus()
		InventarioManager.recoger_item(item_equipado)
		PlayerStats.equipo[tipo] = null
		InventarioManager.inventario_actualizado.emit()
		PlayerStats.stats_changed.emit()

func actualizar_objetos_clave() -> void:
	if not box_clave:
		return
		
	for hijo in box_clave.get_children():
		hijo.queue_free()
		
	var lista_claves = []
	if "objetos_clave" in InventarioManager:
		lista_claves = InventarioManager.objetos_clave

	# Forzamos exactamente 5 slots para rellenar toda la fila visualmente
	const MAX_SLOTS_CLAVE: int = 5

	for i in range(MAX_SLOTS_CLAVE):
		var slot_ui = ESCENA_SLOT.instantiate()
		slot_ui.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if i < lista_claves.size():
			var item_clave = lista_claves[i]
			if typeof(item_clave) == TYPE_DICTIONARY:
				slot_ui.actualizar_slot(item_clave["item"], item_clave.get("cantidad", 1))
			else:
				slot_ui.actualizar_slot(item_clave, 1)
		else:
			# Si aún no se ha obtenido el objeto clave, mostramos la casilla vacía
			slot_ui.actualizar_slot(null, 0)
			
		box_clave.add_child(slot_ui)

func ocultar_hud_por_completo() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
