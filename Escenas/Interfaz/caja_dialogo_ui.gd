# res://Escenas/Interfaz/caja_dialogo_ui.gd
extends CanvasLayer
class_name CajaDialogoUI

@onready var contenedor_dialogo: Control = $ContenedorDialogo
@onready var nombre_label: Label = $ContenedorDialogo/PanelFondo/MarginContainer/VBoxContainer/NombreLabel
@onready var texto_label: RichTextLabel = $ContenedorDialogo/PanelFondo/MarginContainer/VBoxContainer/TextoLabel

# Rutas directas y seguras basadas exactamente en tu archivo .tscn
@onready var contenedor_botones: GridContainer = $ContenedorBotones
@onready var btn_aceptar: Button = $ContenedorBotones/BtnAceptar
@onready var btn_rechazar: Button = $ContenedorBotones/BtnRechazar

var tween_texto: Tween = null
var escribiendo: bool = false
var texto_completo_actual: String = ""

var callback_aceptar: Callable = Callable()
var callback_rechazar: Callable = Callable()

func _ready() -> void:
	add_to_group("HUD")
	add_to_group("CajaDialogo")
	_ocultar_botones()
	if contenedor_dialogo:
		contenedor_dialogo.hide()

func mostrar_dialogo(nombre: String, texto: String) -> void:
	self.show()
	if contenedor_dialogo:
		contenedor_dialogo.show()
		contenedor_dialogo.visible = true
		
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_congelado"):
		player.set_congelado(true)
	if not contenedor_dialogo:
		return
		
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	contenedor_dialogo.show()
	
	# IMPORTANTE: Al abrir cualquier diálogo estándar, limpiamos por completo 
	# cualquier botón dinámico anterior (como los puertos de Jorah) para que no se mezclen con otros NPCs.
	_limpiar_botones_dinamicos()
	_ocultar_botones()
	
	if nombre_label:
		nombre_label.text = nombre
		
	texto_completo_actual = texto
	if texto_label:
		texto_label.text = texto
		texto_label.visible_characters = 0
		
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
		
	escribiendo = true
	var tiempo_escritura: float = texto.length() * 0.03
	
	tween_texto = create_tween()
	if texto_label:
		tween_texto.tween_property(texto_label, "visible_characters", texto.length(), tiempo_escritura)
	tween_texto.finished.connect(_on_texto_terminado)

func _on_texto_terminado() -> void:
	escribiendo = false
	if not (btn_aceptar and btn_aceptar.visible):
		var id_actual = texto_completo_actual
		await get_tree().create_timer(3.0).timeout
		if texto_completo_actual == id_actual and contenedor_dialogo and contenedor_dialogo.visible:
			ocultar_dialogo()

func mostrar_dialogo_con_opciones(nombre: String, texto: String, texto_btn_1: String, callback_1: Callable, texto_btn_2: String = "", callback_2: Callable = Callable()) -> void:
	mostrar_dialogo(nombre, texto)
	
	callback_aceptar = callback_1
	callback_rechazar = callback_2

	if btn_aceptar:
		btn_aceptar.text = texto_btn_1
		btn_aceptar.show()
		if not btn_aceptar.pressed.is_connected(_on_aceptar_pressed):
			btn_aceptar.pressed.connect(_on_aceptar_pressed)

	if btn_rechazar:
		if texto_btn_2 != "":
			btn_rechazar.text = texto_btn_2
			btn_rechazar.show()
			if not btn_rechazar.pressed.is_connected(_on_rechazar_pressed):
				btn_rechazar.pressed.connect(_on_rechazar_pressed)
		else:
			btn_rechazar.hide()
			
	if contenedor_botones:
		contenedor_botones.show()

func _on_aceptar_pressed() -> void:
	ocultar_dialogo()
	if callback_aceptar.is_valid():
		callback_aceptar.call()

func _on_rechazar_pressed() -> void:
	ocultar_dialogo()
	if callback_rechazar.is_valid():
		callback_rechazar.call()

func _ocultar_botones() -> void:
	if btn_aceptar: btn_aceptar.hide()
	if btn_rechazar: btn_rechazar.hide()
	# NOTA: Ya no ocultamos a la fuerza el contenedor entero aquí para permitir 
	# que los botones dinámicos de Jorah se gestionen desde su propia función.

func _limpiar_botones_dinamicos() -> void:
	if not contenedor_botones:
		return
	# Borra cualquier botón que se haya creado proceduralmente (los puertos de Jorah)
	for child in contenedor_botones.get_children():
		if child != btn_aceptar and child != btn_rechazar:
			child.queue_free()

func ocultar_dialogo() -> void:
	if contenedor_dialogo:
		contenedor_dialogo.hide()
		_ocultar_botones()
		_limpiar_botones_dinamicos()
		
	# 1. Aseguramos que el ratón vuelva a capturarse para mover la cámara libremente con el 3D
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 2. Descongelamos al jugador para que recupere el movimiento y la cámara
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_congelado"):
		player.set_congelado(false)
		
	# 3. Por seguridad, si la tienda estuviera abierta en segundo plano, la cerramos también
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_node("TiendaUI"):
		var tienda = hud.get_node("TiendaUI")
		if tienda and tienda.visible:
			tienda.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not contenedor_dialogo or not contenedor_dialogo.visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("Interactuar") or (event is InputEventKey and event.pressed and event.keycode == KEY_Z) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if escribiendo:
			# Si el texto se está escribiendo letra por letra, lo completamos al instante
			if tween_texto and tween_texto.is_running():
				tween_texto.kill()
			if texto_label:
				texto_label.visible_characters = texto_completo_actual.length()
			escribiendo = false
			get_viewport().set_input_as_handled()
		else:
			# Si ya terminó de escribirse, permitimos cerrar el diálogo normalmente al pulsar la tecla o hacer clic fuera de los botones
			# (A menos que el clic haya sido directamente sobre un botón interactivo)
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				# Dejamos que el botón procese su evento de 'pressed' primero
				return
				
			ocultar_dialogo()
			get_viewport().set_input_as_handled()

# --- GESTIÓN DE LISTA DE DESTINOS PARA JORAH ---

func mostrar_dialogo_con_lista_destinos(nombre: String, texto: String, destinos: Array[Dictionary], jugador: Node3D) -> void:
	# Primero abrimos el diálogo normal y limpiamos restos previos
	mostrar_dialogo(nombre, texto)
	
	if not contenedor_botones:
		return
		
	# 1. Limpiamos cualquier botón dinámico anterior que pudiera haber en el GridContainer
	_limpiar_botones_dinamicos()
	
	# 2. Ocultamos los botones por defecto (Aceptar/Rechazar) para que no estorben
	if btn_aceptar: btn_aceptar.hide()
	if btn_rechazar: btn_rechazar.hide()
		
	# 3. Creamos un botón dinámico por cada destino disponible
	for destino in destinos:
		var btn = Button.new()
		btn.text = "%s (%d monedas)" % [destino["nombre"], destino["coste"]]
		
		# Conectamos la acción del botón de forma segura mediante una copia local del diccionario
		var d_copia = destino
		btn.pressed.connect(func():
			_on_destino_seleccionado(d_copia, jugador)
		)
		
		contenedor_botones.add_child(btn)
		
	contenedor_botones.show()

func _on_destino_seleccionado(destino: Dictionary, jugador: Node3D) -> void:
	ocultar_dialogo()
	
	# Validamos de nuevo el oro por seguridad y ejecutamos el viaje
	if PlayerStats.monedas >= destino["coste"]:
		PlayerStats.ganar_monedas(-destino["coste"])
		
		# Mensaje rápido de éxito
		mostrar_dialogo("Capitán Jorah", "¡Izad las velas! Zarpamos hacia %s." % destino["nombre"])
		
		await get_tree().create_timer(1.0).timeout
		MapManager.cambiar_zona(destino["id_zona"], destino["posicion"], jugador)
	else:
		mostrar_dialogo("Capitán Jorah", "No tienes suficiente oro para este viaje. ¡Vuelve cuando reúnas las monedas!")
