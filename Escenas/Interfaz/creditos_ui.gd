extends Control

@onready var boton_menu: Button = $CenterContainer/VBoxContainer/BotonMenuPrincipal

func _ready() -> void:
	if boton_menu:
		boton_menu.pressed.connect(_on_boton_menu_pressed)
		
	# Hacemos visible el ratón para que se pueda hacer clic en el botón
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_boton_menu_pressed() -> void:
	# Nos aseguramos de quitar la pausa por si el juego la tuviera
	get_tree().paused = false
	
	# Cambia a la escena del menú principal (ajusta la ruta si la tienes en otra carpeta)
	get_tree().change_scene_to_file("res://Escenas/Menus/menu_principal.tscn")
