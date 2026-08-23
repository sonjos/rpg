extends CanvasLayer
class_name CajaDialogoUI

@onready var contenedor_dialogo: Control = $ContenedorDialogo
@onready var nombre_label: Label = $ContenedorDialogo/PanelFondo/MarginContainer/VBoxContainer/NombreLabel
@onready var texto_label: RichTextLabel = $ContenedorDialogo/PanelFondo/MarginContainer/VBoxContainer/TextoLabel

var tween_texto: Tween = null
var escribiendo: bool = false
var texto_completo_actual: String = ""

func _ready() -> void:
	add_to_group("HUD")
	
	# Aplicar estilo de marco dorado y fondo oscuro al panel de diálogo de forma automática
	var panel_fondo = get_node_or_null("ContenedorDialogo/PanelFondo")
	if panel_fondo:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color.html("#14141EE0")
		estilo.set_border_width_all(2)
		estilo.border_color = Color.html("#D9A736")
		estilo.set_corner_radius_all(12)
		panel_fondo.add_theme_stylebox_override("panel", estilo)
		
	if contenedor_dialogo:
		contenedor_dialogo.hide()

func mostrar_dialogo(nombre: String, texto: String) -> void:
	if not contenedor_dialogo:
		return
		
	contenedor_dialogo.show()
	
	if nombre_label:
		nombre_label.text = nombre
		nombre_label.add_theme_color_override("font_color", Color.html("#FFD700"))
		
	texto_completo_actual = texto
	if texto_label:
		texto_label.text = texto
		texto_label.visible_characters = 0
		texto_label.add_theme_color_override("default_color", Color.html("#F0F0F0"))
	
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
		
	escribiendo = true
	var tiempo_escritura: float = texto.length() * 0.03
	
	tween_texto = create_tween()
	if texto_label:
		tween_texto.tween_property(texto_label, "visible_characters", texto.length(), tiempo_escritura)
	tween_texto.finished.connect(func(): escribiendo = false)

func ocultar_dialogo() -> void:
	if contenedor_dialogo:
		contenedor_dialogo.hide()

func _unhandled_input(event: InputEvent) -> void:
	if contenedor_dialogo and contenedor_dialogo.visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("Interactuar") or Input.is_key_pressed(KEY_Z)):
		if escribiendo:
			if tween_texto and tween_texto.is_running():
				tween_texto.kill()
			if texto_label:
				texto_label.visible_characters = texto_completo_actual.length()
			escribiendo = false
			get_viewport().set_input_as_handled()
		else:
			ocultar_dialogo()
			get_viewport().set_input_as_handled()
