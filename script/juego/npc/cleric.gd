extends Node3D

var jugador_cerca = false
var velocidad_actual = 2.0 

@onready var anim = $AnimationPlayer
@onready var etiqueta = $CanvasLayer/TextoDialogo
@onready var area = $Area3D # Asegúrate de que tu Area3D se llama así

func _ready() -> void:
	anim.play("Walk")
	etiqueta.visible = false # Ocultamos el texto al empezar
	
	# Conectamos las señales por código para asegurarnos de que funcionen siempre
	if not area.body_entered.is_connected(_on_area_3d_body_entered):
		area.body_entered.connect(_on_area_3d_body_entered)
	if not area.body_exited.is_connected(_on_area_3d_body_exited):
		area.body_exited.connect(_on_area_3d_body_exited)

func _process(delta: float) -> void:
	var padre = get_parent()
	
	if jugador_cerca:
		velocidad_actual = 0.0 # Se para
		anim.stop()
	else:
		velocidad_actual = 2.0 # Sigue caminando
		if not anim.is_playing():
			anim.play("Walk")
			
	if padre is PathFollow3D:
		padre.progress += velocidad_actual * delta

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Jugador":
		jugador_cerca = true
		etiqueta.text = "Pulsa F para hablar"
		etiqueta.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "Jugador":
		jugador_cerca = false
		etiqueta.visible = false # ¡Aquí es donde se oculta el texto al salir!

func _input(event: InputEvent) -> void:
	if jugador_cerca and event.is_action_pressed("interactuar"):
		etiqueta.text = "Clérigo: 'Este santuario guarda grandes secretos...'"
