# res://Escenas/Interfaz/caja_dialogo_ui.gd (o caja_dialogo_ui_2.gd)
extends CanvasLayer
class_name CajaDialogoUI

@onready var contenedor_dialogo: Control = $ContenedorDialogo
@onready var nombre_label: Label = $ContenedorDialogo/PanelFondo/MarginContainer/VBoxContainer/NombreLabel
@onready var texto_label: RichTextLabel = $ContenedorDialogo/PanelFondo/MarginContainer/VBoxContainer/TextoLabel

var tween_texto: Tween = null
var escribiendo: bool = false
var texto_completo_actual: String = ""

var callback_aceptar: Callable = Callable()
var callback_rechazar: Callable = Callable()

var temporizador_autocierre: SceneTreeTimer = null

func _ready() -> void:
	add_to_group("HUD")
	add_to_group("CajaDialogo")
	if has_node("ContenedorBotones"):
		$ContenedorBotones.hide()
	if contenedor_dialogo:
		contenedor_dialogo.hide()
	_ocultar_botones()

func mostrar_dialogo(nombre: String, texto: String) -> void:
	if not contenedor_dialogo:
		return
		
	# LIBERAR EL RATÓN
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# CONGELAR AL JUGADOR
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_congelado"):
		player.set_congelado(true)
		
	contenedor_dialogo.show()
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
	
	# Si no es un diálogo con opciones, iniciamos auto-cierre tras 3 segundos
	var btn_aceptar = find_child("BtnAceptar", true, false)
	if not (btn_aceptar and btn_aceptar.visible):
		var id_actual = texto_completo_actual
		await get_tree().create_timer(3.0).timeout
		# Solo se cierra si no se ha cambiado de texto mientras tanto
		if texto_completo_actual == id_actual and contenedor_dialogo and contenedor_dialogo.visible:
			ocultar_dialogo()

func mostrar_dialogo_con_opciones(nombre: String, texto: String, texto_btn_1: String, callback_1: Callable, texto_btn_2: String = "", callback_2: Callable = Callable()) -> void:
	mostrar_dialogo(nombre, texto)
	
	callback_aceptar = callback_1
	callback_rechazar = callback_2

	var btn_aceptar = find_child("BtnAceptar", true, false)
	if btn_aceptar:
		btn_aceptar.text = texto_btn_1
		btn_aceptar.show()
		if not btn_aceptar.pressed.is_connected(_on_aceptar_pressed):
			btn_aceptar.pressed.connect(_on_aceptar_pressed)

	var btn_rechazar = find_child("BtnRechazar", true, false)
	if btn_rechazar:
		if texto_btn_2 != "":
			btn_rechazar.text = texto_btn_2
			btn_rechazar.show()
			if not btn_rechazar.pressed.is_connected(_on_rechazar_pressed):
				btn_rechazar.pressed.connect(_on_rechazar_pressed)
		else:
			btn_rechazar.hide()
			
	var contenedor_botones = find_child("ContenedorBotones", true, false)
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
	var btn_aceptar = find_child("BtnAceptar", true, false)
	var btn_rechazar = find_child("BtnRechazar", true, false)
	var contenedor_botones = find_child("ContenedorBotones", true, false)
	
	if btn_aceptar: btn_aceptar.hide()
	if btn_rechazar: btn_rechazar.hide()
	if contenedor_botones: contenedor_botones.hide()

func ocultar_dialogo() -> void:
	if contenedor_dialogo:
		contenedor_dialogo.hide()
		_ocultar_botones()
		
	# DEVOLVER EL RATÓN AL JUEGO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# DESCONGELAR AL JUGADOR
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_congelado"):
		player.set_congelado(false)

func _unhandled_input(event: InputEvent) -> void:
	if not contenedor_dialogo or not contenedor_dialogo.visible:
		return
		
	var btn_aceptar = find_child("BtnAceptar", true, false)
	var tiene_opciones: bool = btn_aceptar and btn_aceptar.visible

	# Si se presiona Z, Aceptar, Interactuar o Clic Izquierdo
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("Interactuar") or (event is InputEventKey and event.pressed and event.keycode == KEY_Z) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		
		# Si hay botones de opciones y ya terminó de escribir, dejamos que el usuario pulse con el ratón
		if tiene_opciones and not escribiendo:
			return
			
		if escribiendo:
			# 1. Si aún está escribiendo, completa el texto de golpe
			if tween_texto and tween_texto.is_running():
				tween_texto.kill()
			if texto_label:
				texto_label.visible_characters = texto_completo_actual.length()
			escribiendo = false
			get_viewport().set_input_as_handled()
		else:
			# 2. Si ya terminó de escribir y es un texto normal, se cierra la caja
			ocultar_dialogo()
			get_viewport().set_input_as_handled()
