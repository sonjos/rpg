extends Control

@export_file("*.tscn") var escena_juego: String = "res://Escenas/escenarios/mundo.tscn"

@onready var menu_principal_container: VBoxContainer = $VBoxContainer
@onready var panel_slots: PanelContainer = $PanelSlots 
@onready var vbox_slots: VBoxContainer = $PanelSlots/VBoxContainer
@onready var caja_lore: ScrollContainer = $Lore

# Apuntamos al botón dentro de CajaLore (que está en tu estructura actual)
@onready var btn_skip: Button = $Lore/CajaLore/BtnSkip

@onready var botones_slots: Array[Button] = [
	$PanelSlots/VBoxContainer/Slot1,
	$PanelSlots/VBoxContainer/Slot2,
	$PanelSlots/VBoxContainer/Slot3,
	$PanelSlots/VBoxContainer/Slot4
]

@onready var btn_jugar: Button = $VBoxContainer/Jugar
@onready var btn_salir: Button = $VBoxContainer/Salir
@onready var btn_cargar: Button = $VBoxContainer/CargarPartida

var btn_volver: Button

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if panel_slots:
		panel_slots.hide()
		
	if caja_lore:
		caja_lore.hide() # Se oculta al iniciar el juego
		
	_crear_boton_volver()
		
	if btn_jugar and not btn_jugar.pressed.is_connected(_on_jugar_pressed):
		btn_jugar.pressed.connect(_on_jugar_pressed)
		
	if btn_cargar and not btn_cargar.pressed.is_connected(_on_cargar_pressed):
		btn_cargar.pressed.connect(_on_cargar_pressed)
		
	if btn_salir and not btn_salir.pressed.is_connected(_on_salir_pressed):
		btn_salir.pressed.connect(_on_salir_pressed)
		
	# Conectamos el botón Continuar del lore de forma segura
	if btn_skip and not btn_skip.pressed.is_connected(_on_skip_pressed):
		btn_skip.pressed.connect(_on_skip_pressed)
		
	for i in range(botones_slots.size()):
		var slot_num = i + 1
		var boton = botones_slots[i]
		if boton:
			if not boton.pressed.is_connected(_on_slot_pressed):
				boton.pressed.connect(func(): _on_slot_pressed(slot_num))
			
			if not boton.gui_input.is_connected(_on_slot_gui_input):
				boton.gui_input.connect(func(event: InputEvent): _on_slot_gui_input(event, slot_num))

# Función para permitir que la rueda del ratón mueva el scroll del lore fluidamente
func _input(event: InputEvent) -> void:
	if caja_lore and caja_lore.visible:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				caja_lore.scroll_vertical -= 40
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				caja_lore.scroll_vertical += 40
				get_viewport().set_input_as_handled()

func _crear_boton_volver() -> void:
	if vbox_slots and not has_node("PanelSlots/VBoxContainer/BtnVolver"):
		btn_volver = Button.new()
		btn_volver.name = "BtnVolver"
		btn_volver.text = "Volver al Menú"
		btn_volver.custom_minimum_size = Vector2(0, 40)
		btn_volver.pressed.connect(_on_volver_pressed)
		vbox_slots.add_child(btn_volver)

func _on_jugar_pressed() -> void:
	if ResourceLoader.exists(escena_juego):
		_mostrar_lore_antes_de_jugar()
	else:
		print("Error: La escena de juego no existe en la ruta: ", escena_juego)

func _mostrar_lore_antes_de_jugar() -> void:
	if menu_principal_container:
		menu_principal_container.hide()
	if panel_slots:
		panel_slots.hide()
		
	if caja_lore:
		caja_lore.show() # Muestra el ScrollContainer con todo el texto y el botón
	else:
		get_tree().change_scene_to_file(escena_juego)

# Función que ejecuta el botón Continuar del lore
func _on_skip_pressed() -> void:
	if ResourceLoader.exists(escena_juego):
		get_tree().change_scene_to_file(escena_juego)
	else:
		print("Error al cambiar de escena: La ruta del juego no es válida.")

func _on_cargar_pressed() -> void:
	if menu_principal_container:
		menu_principal_container.hide()
	if caja_lore:
		caja_lore.hide()
	if panel_slots:
		panel_slots.show()
	_actualizar_textos_slots()

func _on_volver_pressed() -> void:
	if panel_slots:
		panel_slots.hide()
	if caja_lore:
		caja_lore.hide()
	if menu_principal_container:
		menu_principal_container.show()

func _actualizar_textos_slots() -> void:
	for i in range(botones_slots.size()):
		var slot_num = i + 1
		if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
			var info = SaveManager.obtener_info_slot(slot_num)
			if botones_slots[i]:
				if info.get("vacio", true):
					botones_slots[i].text = "Slot %d - [ Vacío (Nueva Partida) ]" % slot_num
				else:
					botones_slots[i].text = info.get("texto", "Partida Guardada") + " (Click der: Borrar)"

func _on_slot_pressed(slot_num: int) -> void:
	if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
		if SaveManager.existe_partida(slot_num):
			SaveManager.cargar_partida(slot_num)
		else:
			SaveManager.guardar_partida(slot_num)
			_mostrar_lore_antes_de_jugar()
	else:
		_mostrar_lore_antes_de_jugar()

func _on_slot_gui_input(event: InputEvent, slot_num: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
			SaveManager.borrar_partida(slot_num)
			_actualizar_textos_slots()

func _on_salir_pressed() -> void:
	get_tree().quit()
