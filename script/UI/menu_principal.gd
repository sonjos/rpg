extends Control

@export_file("*.tscn") var escena_juego: String = "res://Escenas/escenarios/mundo.tscn"

# Como el script está en el nodo MenuPrincipal, buscamos directamente a sus hijos:
@onready var boton_jugar: Button = $VBoxContainer/Jugar
@onready var boton_salir: Button = $VBoxContainer/Salir

func _ready() -> void:
	if boton_jugar:
		boton_jugar.pressed.connect(_on_jugar_pressed)
	if boton_salir:
		boton_salir.pressed.connect(_on_salir_pressed)

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file(escena_juego)

func _on_salir_pressed() -> void:
	get_tree().quit()
