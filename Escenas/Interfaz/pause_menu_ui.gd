extends Control

signal reanudar_partida
signal abrir_ajustes

@onready var btn_reanudar: Button = find_child("BtnReanudar", true, false)
@onready var btn_ajustes: Button = find_child("BtnAjustes", true, false)
@onready var btn_guardar: Button = find_child("BtnGuardarPartida", true, false)
@onready var btn_menu: Button = find_child("BtnMenuPrincipal", true, false)

# Contenedor dinámico para elegir el slot de guardado desde la pausa
var panel_slots_pausa: PanelContainer
var botones_slots_pausa: Array[Button] = []

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	if btn_reanudar: btn_reanudar.pressed.connect(_on_btn_reanudar_pressed)
	if btn_ajustes: btn_ajustes.pressed.connect(_on_btn_ajustes_pressed)
	if btn_guardar: btn_guardar.pressed.connect(_on_btn_guardar_pressed)
	if btn_menu: btn_menu.pressed.connect(_on_btn_menu_pressed)
	
	_crear_panel_slots_pausa()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if visible:
			cerrar_pausa()
		else:
			abrir_pausa()
		get_viewport().set_input_as_handled()

func abrir_pausa() -> void:
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if panel_slots_pausa:
		panel_slots_pausa.hide() # Aseguramos que el selector de slots empiece oculto al pausar

func cerrar_pausa() -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	reanudar_partida.emit()

func _on_btn_reanudar_pressed() -> void:
	cerrar_pausa()

func _on_btn_ajustes_pressed() -> void:
	abrir_ajustes.emit()

# --- LÓGICA DE SELECCIÓN DE SLOTS PARA GUARDAR ---

func _crear_panel_slots_pausa() -> void:
	# Creamos un panel de manera dinámica para no obligarte a rediseñar la escena de golpe si no quieres
	panel_slots_pausa = PanelContainer.new()
	panel_slots_pausa.name = "PanelSlotsPausa"
	panel_slots_pausa.visible = false
	panel_slots_pausa.custom_minimum_size = Vector2(350, 250)
	
	# Lo centramos o anclamos dentro del control principal de pausa
	panel_slots_pausa.set_anchors_preset(Control.PRESET_CENTER)
	
	var margenes = MarginContainer.new()
	margenes.add_theme_constant_override("margin_top", 15)
	margenes.add_theme_constant_override("margin_bottom", 15)
	margenes.add_theme_constant_override("margin_left", 15)
	margenes.add_theme_constant_override("margin_right", 15)
	panel_slots_pausa.add_child(margenes)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margenes.add_child(vbox)
	
	var titulo = Label.new()
	titulo.text = "Selecciona Slot para Guardar"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)
	
	botones_slots_pausa.clear()
	for i in range(4):
		var slot_num = i + 1
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 35)
		btn.pressed.connect(func(): _on_slot_guardar_seleccionado(slot_num))
		vbox.add_child(btn)
		botones_slots_pausa.append(btn)
		
	var btn_cancelar = Button.new()
	btn_cancelar.text = "Cancelar"
	btn_cancelar.pressed.connect(func(): panel_slots_pausa.hide())
	vbox.add_child(btn_cancelar)
	
	add_child(panel_slots_pausa)

func _on_btn_guardar_pressed() -> void:
	# Actualizamos los textos de los slots antes de mostrarlos para advertir si están ocupados
	for i in range(botones_slots_pausa.size()):
		var slot_num = i + 1
		if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
			var info = SaveManager.obtener_info_slot(slot_num)
			if info.get("vacio", true):
				botones_slots_pausa[i].text = "Slot %d - [ Vacío ]" % slot_num
			else:
				botones_slots_pausa[i].text = "Slot %d - [ Ocupado / Sobrescribir ]" % slot_num
		
	if panel_slots_pausa:
		panel_slots_pausa.show()

func _on_slot_guardar_seleccionado(slot_num: int) -> void:
	if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
		SaveManager.guardar_partida(slot_num)
		print("¡Partida guardada en el slot ", slot_num, "!")
		
		if panel_slots_pausa:
			panel_slots_pausa.hide()
			
		# Feedback visual en el botón de guardar del menú principal de pausa
		if btn_guardar:
			var texto_original = btn_guardar.text
			btn_guardar.text = "¡Slot %d Guardado!" % slot_num
			await get_tree().create_timer(1.5).timeout
			if is_instance_valid(btn_guardar):
				btn_guardar.text = texto_original
	else:
		print("Error: SaveManager no está disponible globalmente.")

func _on_btn_menu_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Ruta vigilada y actualizada al menú principal
	get_tree().change_scene_to_file("res://Escenas/Interfaz/menu_principal.tscn")
